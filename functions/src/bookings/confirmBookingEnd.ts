/**
 * Cloud Function: confirmBookingEnd
 * Handles end confirmation from both renter and host.
 * 
 * SECURITY RULES:
 * - Booking can only be ended after end_time has passed
 * - Both renter and host must confirm
 * - Host must upload damage photos if claiming damage
 * - Race-condition safe with transaction guards
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  BookingStatus,
  TransactionType,
  validateEndPhotosExist,
  StorageValidationError,
  StorageErrorCode,
} from '../shared';
import {
  EvidenceErrorCode,
  StateErrorCode,
  AuthErrorCode,
  ResourceErrorCode,
} from '../shared/errorCodes';

// ============================================================================
// Types
// ============================================================================

type Actor = 'renter' | 'host';

interface ConfirmBookingEndRequest {
  bookingId: string;
  actor: Actor;
  hasDamage: boolean;
}

interface EndConfirmations {
  renter?: boolean;
  host?: boolean;
}

interface BookingData {
  status: string;
  renter_id: string;
  owner_id: string;
  end_time: admin.firestore.Timestamp;
  end_confirmations?: EndConfirmations;
  ended_at?: admin.firestore.Timestamp;
}

// ============================================================================
// Helper: Generate deterministic transaction ID for idempotency
// ============================================================================

function getEndingTransactionId(bookingId: string): string {
  return `${bookingId}_${TransactionType.BOOKING_ENDED}`;
}

// ============================================================================
// Cloud Function
// ============================================================================

export const confirmBookingEnd = functions.https.onCall(
  async (data: ConfirmBookingEndRequest, context) => {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { bookingId, actor, hasDamage } = data;

    // Validate required parameters
    if (!bookingId || !actor) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId and actor are required'
      );
    }

    // Validate actor value
    if (actor !== 'renter' && actor !== 'host') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid actor: ${actor}. Must be "renter" or "host"`,
        { code: AuthErrorCode.INVALID_ACTOR }
      );
    }

    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);
    const transactionId = getEndingTransactionId(bookingId);
    const transactionRef = db.collection('transactions').doc(transactionId);

    try {
      const result = await db.runTransaction(async (transaction) => {
        // Fetch booking and check for existing transaction in parallel
        const [bookingDoc, existingTransactionDoc] = await Promise.all([
          transaction.get(bookingRef),
          transaction.get(transactionRef),
        ]);

        // RACE CONDITION GUARD: If transaction already exists, booking was already ended
        if (existingTransactionDoc.exists) {
          return {
            confirmed: true,
            actor,
            bothConfirmed: true,
            newStatus: BookingStatus.ENDED,
            alreadyEnded: true,
            message: 'Booking already ended by both parties',
          };
        }

        if (!bookingDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            `Booking ${bookingId} not found`,
            { code: ResourceErrorCode.BOOKING_NOT_FOUND }
          );
        }

        const booking = bookingDoc.data() as BookingData;

        // Validate actor is authorized (must be the actual renter or host)
        const userId = context.auth!.uid;
        if (actor === 'renter' && booking.renter_id !== userId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Only the renter can confirm as renter'
          );
        }
        if (actor === 'host' && booking.owner_id !== userId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Only the host can confirm as host'
          );
        }

        // Validate booking status is "started"
        if (booking.status !== BookingStatus.STARTED) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Booking status must be "${BookingStatus.STARTED}" to confirm end. Current status: "${booking.status}"`,
            { code: StateErrorCode.INVALID_STATE }
          );
        }

        // TIME ENFORCEMENT: Check if booking end_time has passed
        const now = admin.firestore.Timestamp.now();
        if (!booking.end_time) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Booking does not have a valid end_time',
            { code: StateErrorCode.INVALID_STATE }
          );
        }

        if (now.toMillis() < booking.end_time.toMillis()) {
          const endDate = booking.end_time.toDate();
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Booking cannot be ended before the scheduled end time (${endDate.toISOString()})`,
            {
              code: StateErrorCode.INVALID_STATE,
              endTime: endDate.toISOString(),
              message: 'Please wait until the booking period has ended',
            }
          );
        }

        // Check for duplicate confirmation
        const confirmations = booking.end_confirmations || {};
        if (confirmations[actor] === true) {
          throw new functions.https.HttpsError(
            'already-exists',
            `${actor} has already confirmed booking end`,
            { code: StateErrorCode.DUPLICATE_ACTION }
          );
        }

        // If host confirms with damage, validate photos exist
        if (actor === 'host' && hasDamage === true) {
          try {
            await validateEndPhotosExist(bookingId);
          } catch (error) {
            if (
              error instanceof StorageValidationError &&
              error.code === StorageErrorCode.FILE_NOT_FOUND
            ) {
              throw new functions.https.HttpsError(
                'failed-precondition',
                'Host must upload at least one photo when reporting damage',
                {
                  code: EvidenceErrorCode.DAMAGE_PHOTOS_REQUIRED,
                  requiredAction: 'Upload damage photos',
                }
              );
            }
            throw error;
          }
        }

        // Update confirmations
        const updatedConfirmations: EndConfirmations = {
          ...confirmations,
          [actor]: true,
        };

        // Check if both parties have confirmed
        const bothConfirmed =
          updatedConfirmations.renter === true &&
          updatedConfirmations.host === true;

        // Prepare booking update
        const bookingUpdate: Record<string, unknown> = {
          end_confirmations: updatedConfirmations,
          [`end_confirmed_at_${actor}`]: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (bothConfirmed) {
          // EXACTLY ONCE: Only set status to ENDED when both have confirmed
          bookingUpdate.status = BookingStatus.ENDED;
          bookingUpdate.ended_at = admin.firestore.FieldValue.serverTimestamp();
        }

        // Apply booking update
        transaction.update(bookingRef, bookingUpdate);

        // EXACTLY ONCE: Create immutable transaction record with deterministic ID
        // This ensures that even if function is called twice simultaneously,
        // only one transaction document is created
        if (bothConfirmed) {
          transaction.set(transactionRef, {
            booking_id: bookingId,
            type: TransactionType.BOOKING_ENDED,
            actor: 'system',
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            renter_id: booking.renter_id,
            owner_id: booking.owner_id,
            immutable: true,
          });
        }

        return {
          confirmed: true,
          actor,
          bothConfirmed,
          newStatus: bothConfirmed ? BookingStatus.ENDED : BookingStatus.STARTED,
          alreadyEnded: false,
        };
      });

      return result;
    } catch (error) {
      // Re-throw HttpsErrors as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      console.error('❌ Error in confirmBookingEnd:', error);
      throw new functions.https.HttpsError(
        'internal',
        'An unexpected error occurred'
      );
    }
  }
);
