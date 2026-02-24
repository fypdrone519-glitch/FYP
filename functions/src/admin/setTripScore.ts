import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { BookingStatus } from '../shared';
import { requireAdmin } from '../shared/auth';

type ScoreInputs = {
  kyc: boolean;
  history: boolean;
  reviews: boolean;
};

interface SetTripScoreRequest {
  bookingId: string;
  score: number;
  reason?: string;
  inputs?: Partial<ScoreInputs>;
}

interface BookingData {
  status?: string;
}

function normalizeReason(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeScore(value: unknown): number | null {
  if (typeof value !== 'number' || !Number.isInteger(value)) {
    return null;
  }

  if (value < 1 || value > 10) {
    return null;
  }

  return value;
}

export const setTripScore = functions.https.onCall(
  async (data: SetTripScoreRequest, context) => {
    const auth = requireAdmin(context);
    const bookingId = data?.bookingId?.trim();
    const score = normalizeScore(data?.score);
    const reason = normalizeReason(data?.reason);

    if (!bookingId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId is required'
      );
    }

    if (score === null) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'score must be an integer between 1 and 10'
      );
    }

    if (score < 7 && !reason) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'reason is required when score is less than 7'
      );
    }

    const bookingRef = admin.firestore().collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        `Booking ${bookingId} not found`
      );
    }

    const booking = bookingDoc.data() as BookingData;
    const currentStatus = (booking.status || '').trim().toLowerCase();
    if (currentStatus !== BookingStatus.PENDING_ADMIN_APPROVAL) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Booking must be "${BookingStatus.PENDING_ADMIN_APPROVAL}" to set trip score. Current status: "${currentStatus || 'unknown'}"`
      );
    }

    const inputs: ScoreInputs = {
      kyc: Boolean(data?.inputs?.kyc),
      history: Boolean(data?.inputs?.history),
      // Keep this explicit for now. It can become true once review system is added.
      reviews: false,
    };

    await bookingRef.update({
      admin_trip_score: score,
      admin_trip_score_reason: score < 7 ? reason : null,
      admin_trip_score_by: auth.uid,
      admin_trip_score_at: admin.firestore.FieldValue.serverTimestamp(),
      admin_trip_score_inputs: inputs,
      admin_trip_score_version: 1,
    });

    return {
      success: true,
      bookingId,
      admin_trip_score: score,
      admin_trip_score_reason: score < 7 ? reason : null,
      admin_trip_score_inputs: inputs,
      admin_trip_score_version: 1,
    };
  }
);
