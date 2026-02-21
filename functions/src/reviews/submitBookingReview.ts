import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { BookingStatus } from '../shared';

type Actor = 'renter' | 'host';

interface ReviewInput {
  rating: number;
  comment?: string;
}

interface SubmitBookingReviewRequest {
  bookingId: string;
  actor: Actor;
  renter_to_car?: ReviewInput;
  renter_to_host?: ReviewInput;
  host_to_renter?: ReviewInput;
}

interface BookingData {
  status?: string;
  renter_id?: string;
  owner_id?: string;
  vehicle_id?: string;
}

function normalizeComment(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeRating(value: unknown): number | null {
  if (typeof value !== 'number' || !Number.isInteger(value)) {
    return null;
  }

  if (value < 1 || value > 5) {
    return null;
  }

  return value;
}

function normalizeReviewInput(input: ReviewInput | undefined): ReviewInput | null {
  if (!input) {
    return null;
  }

  const rating = normalizeRating(input.rating);
  if (rating === null) {
    return null;
  }

  return {
    rating,
    comment: normalizeComment(input.comment) ?? undefined,
  };
}

export const submitBookingReview = functions.https.onCall(
  async (data: SubmitBookingReviewRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const bookingId = data?.bookingId?.trim();
    const actor = data?.actor;
    if (!bookingId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId is required'
      );
    }
    if (actor !== 'renter' && actor !== 'host') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'actor must be either "renter" or "host"'
      );
    }

    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);
    const reviewRef = db.collection('reviews').doc(`${bookingId}_${actor}`);

    return await db.runTransaction(async (transaction) => {
      const [bookingDoc, reviewDoc] = await Promise.all([
        transaction.get(bookingRef),
        transaction.get(reviewRef),
      ]);

      if (!bookingDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          `Booking ${bookingId} not found`
        );
      }

      if (reviewDoc.exists) {
        throw new functions.https.HttpsError(
          'already-exists',
          `Review already submitted for booking ${bookingId} by ${actor}`
        );
      }

      const booking = bookingDoc.data() as BookingData;
      const status = (booking.status || '').trim().toLowerCase();
      const isEndedState =
        status === BookingStatus.ENDED || status === BookingStatus.COMPLETED;
      if (!isEndedState) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Reviews can only be submitted when booking status is "${BookingStatus.ENDED}" or "${BookingStatus.COMPLETED}". Current status: "${status || 'unknown'}"`
        );
      }

      const userId = context.auth!.uid;
      if (actor === 'renter' && booking.renter_id !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only the renter can submit renter review'
        );
      }
      if (actor === 'host' && booking.owner_id !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only the host can submit host review'
        );
      }

      const renterToCar = normalizeReviewInput(data?.renter_to_car);
      const renterToHost = normalizeReviewInput(data?.renter_to_host);
      const hostToRenter = normalizeReviewInput(data?.host_to_renter);

      if (actor === 'renter') {
        if (!renterToCar || !renterToHost) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'renter_to_car and renter_to_host ratings are required for renter'
          );
        }
      } else if (!hostToRenter) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'host_to_renter rating is required for host'
        );
      }

      const now = admin.firestore.FieldValue.serverTimestamp();
      const reviewData: Record<string, unknown> = {
        booking_id: bookingId,
        actor,
        renter_id: booking.renter_id ?? null,
        owner_id: booking.owner_id ?? null,
        vehicle_id: booking.vehicle_id ?? null,
        created_at: now,
      };

      if (actor === 'renter') {
        reviewData.renter_to_car = {
          rating: renterToCar!.rating,
          comment: renterToCar!.comment ?? null,
        };
        reviewData.renter_to_host = {
          rating: renterToHost!.rating,
          comment: renterToHost!.comment ?? null,
        };
      } else {
        reviewData.host_to_renter = {
          rating: hostToRenter!.rating,
          comment: hostToRenter!.comment ?? null,
        };
      }

      transaction.set(reviewRef, reviewData);

      return {
        success: true,
        bookingId,
        actor,
        reviewId: reviewRef.id,
      };
    });
  }
);
