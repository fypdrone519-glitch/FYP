import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { enqueueRecommendationJob } from '../recommendations/computeRecommendedCars';

const VIEW_WEIGHT = 1;
const BOOKING_WEIGHT = 3;
const PRICE_BUCKET_SIZE = 5000;

interface LogVehicleBehaviorRequest {
  vehicleId: string;
}

interface VehicleMetadata {
  categoryKey: string;
  priceBucketKey: string;
  rawCategory: string;
  rawPrice: number;
}

export const logVehicleView = functions.https.onCall(
  async (data: LogVehicleBehaviorRequest, context) => {
    return logBehaviorEvent(data, context, VIEW_WEIGHT, false);
  }
);

export const logVehicleBooking = functions.https.onCall(
  async (data: LogVehicleBehaviorRequest, context) => {
    return logBehaviorEvent(data, context, BOOKING_WEIGHT, true);
  }
);

async function logBehaviorEvent(
  data: LogVehicleBehaviorRequest,
  context: functions.https.CallableContext,
  weight: number,
  isBooking: boolean
) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const vehicleId = data?.vehicleId?.trim();
  if (!vehicleId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'vehicleId is required'
    );
  }

  const metadata = await getVehicleMetadata(vehicleId);
  const db = admin.firestore();
  const uid = context.auth.uid;
  const behaviourDocPath = `users/${uid}/user_behaviour/summary`;

  functions.logger.info('logBehaviorEvent start', {
    uid,
    vehicleId,
    isBooking,
    weight,
    rawCategory: metadata.rawCategory,
    rawPrice: metadata.rawPrice,
    category: metadata.categoryKey,
    priceBucket: metadata.priceBucketKey,
  });

  const updateData: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
    [`category_views.${metadata.categoryKey}`]: admin.firestore.FieldValue.increment(
      weight
    ),
    [`price_range_views.${metadata.priceBucketKey}`]:
      admin.firestore.FieldValue.increment(weight),
    last_updated: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (isBooking) {
    updateData[`category_bookings.${metadata.categoryKey}`] =
      admin.firestore.FieldValue.increment(1);
    updateData[`price_range_bookings.${metadata.priceBucketKey}`] =
      admin.firestore.FieldValue.increment(1);
  }

  const summaryRef = db
    .collection('users')
    .doc(uid)
    .collection('user_behaviour')
    .doc('summary');

  // Ensure doc exists, then use update so dotted keys are interpreted as field paths.
  await summaryRef.set(
    { last_updated: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true }
  );
  await summaryRef.update(updateData);

  const summaryAfterWrite = await summaryRef.get();
  const summaryData = (summaryAfterWrite.data() ??
    {}) as FirebaseFirestore.DocumentData;

  const recommendationJobId = await enqueueRecommendationJob(
    uid,
    isBooking ? 'vehicle_booking' : 'vehicle_view'
  );

  functions.logger.info('logBehaviorEvent write success', {
    uid,
    documentPath: behaviourDocPath,
    recommendationJobId,
    behaviourSnapshot: {
      category_views: topEntries(summaryData.category_views),
      category_bookings: topEntries(summaryData.category_bookings),
      price_range_views: topEntries(summaryData.price_range_views),
      price_range_bookings: topEntries(summaryData.price_range_bookings),
    },
  });

  return {
    success: true,
    uid,
    documentPath: behaviourDocPath,
    vehicleId,
    category: metadata.categoryKey,
    priceBucket: metadata.priceBucketKey,
    weightApplied: weight,
    bookingSignal: isBooking,
    recommendationJobId,
  };
}

async function getVehicleMetadata(vehicleId: string): Promise<VehicleMetadata> {
  const vehicleDoc = await admin.firestore().collection('vehicles').doc(vehicleId).get();
  if (!vehicleDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Vehicle not found');
  }

  const data = vehicleDoc.data() ?? {};
  const rawCategory = typeof data.vehicle_type === 'string' ? data.vehicle_type : 'unknown';
  const rawPrice = typeof data.rent_per_day === 'number' ? data.rent_per_day : 0;

  return {
    categoryKey: sanitizeKey(rawCategory),
    priceBucketKey: getPriceBucketKey(rawPrice),
    rawCategory,
    rawPrice,
  };
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

function topEntries(
  map: FirebaseFirestore.DocumentData | undefined,
  limit: number = 10
): Record<string, number> {
  if (!map || typeof map !== 'object') return {};

  return Object.fromEntries(
    Object.entries(map)
      .filter(([, value]) => typeof value === 'number')
      .sort((a, b) => (b[1] as number) - (a[1] as number))
      .slice(0, limit)
  );
}
