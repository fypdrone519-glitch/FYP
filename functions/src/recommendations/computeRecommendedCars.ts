import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const CATEGORY_WEIGHT = 1;
const PRICE_WEIGHT = 1;
const BOOKING_SIGNAL_MULTIPLIER = 1;
const CANDIDATE_LIMIT = 100;
const MAX_RECOMMENDATIONS = 10;
const PRICE_BUCKET_SIZE = 5000;
const RECOMMENDATION_VERSION = 1;

type CounterMap = Record<string, number>;

interface UserBehaviorSummary {
  category_views?: CounterMap;
  price_range_views?: CounterMap;
  category_bookings?: CounterMap;
  price_range_bookings?: CounterMap;
}

interface VehicleCandidate {
  id: string;
  category: string;
  priceBucket: string;
}

interface RecommendationResult {
  recommended_vehicle_ids: string[];
  generated_at: string;
}

interface RecommendationJob {
  userId?: string;
  reason?: string;
  created_at?: FirebaseFirestore.Timestamp;
}

export const computeRecommendedCars = functions.https.onCall(
  async (data: { userId: string }, context): Promise<RecommendationResult> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = data?.userId?.trim();
    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'userId is required');
    }

    const isAdmin = context.auth.token?.role === 'admin';
    if (context.auth.uid !== userId && !isAdmin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only compute recommendations for your own account'
      );
    }

    return computeAndStoreRecommendations(userId);
  }
);

export const processRecommendationJob = functions.firestore
  .document('recommendation_jobs/{jobId}')
  .onCreate(async (snapshot) => {
    const job = snapshot.data() as RecommendationJob;
    const userId = (job.userId || '').trim();
    const jobId = snapshot.id;

    functions.logger.info('processRecommendationJob start', {
      jobId,
      userId,
      reason: job.reason || null,
    });

    if (!userId) {
      functions.logger.warn('Recommendation job missing userId', {
        jobId,
        payload: job,
      });
      return;
    }

    const result = await computeAndStoreRecommendations(userId);
    functions.logger.info('processRecommendationJob success', {
      jobId,
      userId,
      recommendedCount: result.recommended_vehicle_ids.length,
      documentPath: `users/${userId}/user_recommendation/summary`,
    });
  });

export async function enqueueRecommendationJob(
  userId: string,
  reason: 'vehicle_view' | 'vehicle_booking'
): Promise<string> {
  const ref = await admin.firestore().collection('recommendation_jobs').add({
    userId,
    reason,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return ref.id;
}

async function computeAndStoreRecommendations(
  userId: string
): Promise<RecommendationResult> {
  const db = admin.firestore();
  const behaviorSummary = await getUserBehaviorSummary(userId);
  const vehicles = await getVehicleCandidates();
  functions.logger.info('computeAndStoreRecommendations inputs', {
    userId,
    candidates: vehicles.length,
    behaviorSnapshot: {
      category_views: getTopEntries(behaviorSummary.category_views),
      category_bookings: getTopEntries(behaviorSummary.category_bookings),
      price_range_views: getTopEntries(behaviorSummary.price_range_views),
      price_range_bookings: getTopEntries(behaviorSummary.price_range_bookings),
    },
  });

  const scoredVehicles = vehicles.map((vehicle) => {
    const categoryViews = getCount(behaviorSummary.category_views, vehicle.category);
    const categoryBookings = getCount(
      behaviorSummary.category_bookings,
      vehicle.category
    );
    const priceViews = getCount(behaviorSummary.price_range_views, vehicle.priceBucket);
    const priceBookings = getCount(
      behaviorSummary.price_range_bookings,
      vehicle.priceBucket
    );

    const categoryMatch = categoryViews + BOOKING_SIGNAL_MULTIPLIER * categoryBookings;
    const priceMatch = priceViews + BOOKING_SIGNAL_MULTIPLIER * priceBookings;
    const score = categoryMatch * CATEGORY_WEIGHT + priceMatch * PRICE_WEIGHT;

    return {
      vehicleId: vehicle.id,
      category: vehicle.category,
      priceBucket: vehicle.priceBucket,
      categoryViews,
      categoryBookings,
      priceViews,
      priceBookings,
      categoryMatch,
      priceMatch,
      score,
    };
  });

  const categoryCounts = new Map<string, number>();
  for (const vehicle of vehicles) {
    categoryCounts.set(
      vehicle.category,
      (categoryCounts.get(vehicle.category) || 0) + 1
    );
  }

  const nonZeroVehicles = scoredVehicles.filter((item) => item.score > 0);
  const uniqueScores = new Set(scoredVehicles.map((item) => item.score));
  functions.logger.info('computeAndStoreRecommendations scoring summary', {
    userId,
    candidates: scoredVehicles.length,
    categoryDistribution: Object.fromEntries(categoryCounts),
    nonZeroCandidates: nonZeroVehicles.length,
    uniqueScoreCount: uniqueScores.size,
    sampleTopScores: scoredVehicles
      .slice()
      .sort((a, b) => b.score - a.score)
      .slice(0, 10)
      .map((item) => ({
        vehicleId: item.vehicleId,
        category: item.category,
        priceBucket: item.priceBucket,
        score: item.score,
        categoryViews: item.categoryViews,
        categoryBookings: item.categoryBookings,
        priceViews: item.priceViews,
        priceBookings: item.priceBookings,
      })),
  });

  if (nonZeroVehicles.length === 0) {
    functions.logger.warn('All recommendation scores are zero', {
      userId,
      hint: 'Behavior keys may not match candidate vehicle category/price keys.',
      behaviorKeys: {
        category_views: Object.keys(behaviorSummary.category_views ?? {}),
        category_bookings: Object.keys(behaviorSummary.category_bookings ?? {}),
        price_range_views: Object.keys(behaviorSummary.price_range_views ?? {}),
        price_range_bookings: Object.keys(
          behaviorSummary.price_range_bookings ?? {}
        ),
      },
      candidateSample: vehicles.slice(0, 10),
    });
  }

  scoredVehicles.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return a.vehicleId.localeCompare(b.vehicleId);
  });

  const recommendedIds = scoredVehicles
    .slice(0, MAX_RECOMMENDATIONS)
    .map((item) => item.vehicleId);

  const generatedAtIso = new Date().toISOString();

  await db
    .collection('users')
    .doc(userId)
    .collection('user_recommendation')
    .doc('summary')
    .set(
      {
        car_ids: recommendedIds,
        generated_at: admin.firestore.FieldValue.serverTimestamp(),
        version: RECOMMENDATION_VERSION,
      },
      { merge: true }
    );

  functions.logger.info('computeAndStoreRecommendations write success', {
    userId,
    recommendedCount: recommendedIds.length,
    recommendedIds,
    documentPath: `users/${userId}/user_recommendation/summary`,
  });

  return {
    recommended_vehicle_ids: recommendedIds,
    generated_at: generatedAtIso,
  };
}

async function getUserBehaviorSummary(userId: string): Promise<UserBehaviorSummary> {
  const summaryDoc = await admin
    .firestore()
    .collection('users')
    .doc(userId)
    .collection('user_behaviour')
    .doc('summary')
    .get();

  if (!summaryDoc.exists) {
    return {};
  }

  const raw = (summaryDoc.data() ?? {}) as FirebaseFirestore.DocumentData;
  const normalized: UserBehaviorSummary = {
    category_views: readCounterMap(raw, 'category_views'),
    price_range_views: readCounterMap(raw, 'price_range_views'),
    category_bookings: readCounterMap(raw, 'category_bookings'),
    price_range_bookings: readCounterMap(raw, 'price_range_bookings'),
  };

  functions.logger.info('getUserBehaviorSummary normalized', {
    userId,
    rawKeys: Object.keys(raw),
    category_views_keys: Object.keys(normalized.category_views ?? {}),
    price_range_views_keys: Object.keys(normalized.price_range_views ?? {}),
    category_bookings_keys: Object.keys(normalized.category_bookings ?? {}),
    price_range_bookings_keys: Object.keys(
      normalized.price_range_bookings ?? {}
    ),
  });

  return normalized;
}

async function getVehicleCandidates(): Promise<VehicleCandidate[]> {
  const snapshot = await admin.firestore().collection('vehicles').limit(CANDIDATE_LIMIT).get();

  return snapshot.docs.map((doc) => {
    const data = doc.data() ?? {};
    const categoryRaw = typeof data.vehicle_type === 'string' ? data.vehicle_type : 'unknown';
    const priceRaw = typeof data.rent_per_day === 'number' ? data.rent_per_day : 0;

    return {
      id: doc.id,
      category: sanitizeKey(categoryRaw),
      priceBucket: getPriceBucketKey(priceRaw),
    };
  });
}

function getCount(map: CounterMap | undefined, key: string): number {
  if (!map) return 0;
  const value = map[key];
  return typeof value === 'number' ? value : 0;
}

function sanitizeKey(value: string): string {
  const trimmed = value.trim().toLowerCase();
  const normalized = trimmed.replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
  return normalized || 'unknown';
}

function getPriceBucketKey(price: number): string {
  const nonNegativePrice = Math.max(0, Math.floor(price));
  const lower = Math.floor(nonNegativePrice / PRICE_BUCKET_SIZE) * PRICE_BUCKET_SIZE;
  const upper = lower + PRICE_BUCKET_SIZE;
  return `${lower}_${upper}`;
}

function getTopEntries(
  map: CounterMap | undefined,
  limit: number = 10
): Record<string, number> {
  if (!map) return {};

  return Object.fromEntries(
    Object.entries(map)
      .filter(([, value]) => typeof value === 'number')
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
  );
}

function readCounterMap(
  raw: FirebaseFirestore.DocumentData,
  mapField: string
): CounterMap {
  const result: CounterMap = {};

  const nested = raw[mapField];
  if (nested && typeof nested === 'object') {
    for (const [key, value] of Object.entries(
      nested as FirebaseFirestore.DocumentData
    )) {
      if (typeof value === 'number') {
        result[key] = value;
      }
    }
  }

  // Backward compatibility: supports legacy flat keys like "category_views.suv".
  const dottedPrefix = `${mapField}.`;
  for (const [key, value] of Object.entries(raw)) {
    if (typeof value !== 'number') continue;
    if (!key.startsWith(dottedPrefix)) continue;

    const subKey = key.slice(dottedPrefix.length).trim();
    if (!subKey) continue;
    result[subKey] = value;
  }

  return result;
}
