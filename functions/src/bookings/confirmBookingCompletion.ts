/**
 * Cloud Function: confirmBookingCompletion
 * Handles completion confirmation from both renter and host.
 * 
 * COMPLETION FLOW:
 * 1. Booking must be in "ended" status
 * 2. Host must upload return condition video before confirming
 * 3. Renter can confirm without uploading anything
 * 4. When BOTH parties confirm → status changes to "completed"
 * 
 * SECURITY:
 * - Only renter and host can confirm
 * - Host must upload return video (validates before confirmation)
 * - Race-condition safe with deterministic transaction IDs
 * - Exactly-once status change guarantee
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  BookingStatus,
  TransactionType,
  validateReturnVideoExists,
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

interface ConfirmBookingCompletionRequest {
  bookingId: string;
  actor: Actor;
}

interface CompletionConfirmations {
  renter?: boolean;
  host?: boolean;
}

interface BookingData {
  status: string;
  renter_id: string;
  owner_id: string;
  ended_at?: admin.firestore.Timestamp;
  completion_confirmations?: CompletionConfirmations;
}

// ============================================================================
// Helper: Generate deterministic transaction ID for idempotency
// ============================================================================

/**
 * Generates a unique, deterministic ID for the completion transaction.
 * Using the same booking ID always produces the same transaction ID.
 * This ensures that even if the function is called multiple times,
 * only one completion transaction is created.
 */
function getCompletionTransactionId(bookingId: string): string {
  return `${bookingId}_${TransactionType.BOOKING_COMPLETED}`;
}

// ============================================================================
// Cloud Function
// ============================================================================

export const confirmBookingCompletion = functions.https.onCall(
  async (data: ConfirmBookingCompletionRequest, context) => {
    // ========================================================================
    // STEP 1: AUTHENTICATION CHECK
    // ========================================================================

    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { bookingId, actor } = data;

    // ========================================================================
    // STEP 2: PARAMETER VALIDATION
    // ========================================================================

    // Validate required parameters
    if (!bookingId || !actor) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId and actor are required'
      );
    }

    // Validate actor value (must be 'renter' or 'host')
    if (actor !== 'renter' && actor !== 'host') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid actor: ${actor}. Must be "renter" or "host"`,
        { code: AuthErrorCode.INVALID_ACTOR }
      );
    }

    // ========================================================================
    // STEP 3: FIRESTORE REFERENCES
    // ========================================================================

    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);
    const transactionId = getCompletionTransactionId(bookingId);
    const transactionRef = bookingRef
      .collection('transactions')
      .doc(transactionId);


    try {
      // ======================================================================
      // STEP 4: ATOMIC TRANSACTION
      // ======================================================================

      const result = await db.runTransaction(async (transaction) => {
        // ==================================================================
        // STEP 4.1: FETCH BOOKING AND CHECK FOR EXISTING TRANSACTION
        // ==================================================================

        // Fetch booking and check for existing completion transaction in parallel
        // This is an optimization to reduce latency
        const [bookingDoc, existingTransactionDoc] = await Promise.all([
          transaction.get(bookingRef),
          transaction.get(transactionRef),
        ]);

        // ==================================================================
        // STEP 4.2: RACE CONDITION GUARD (IDEMPOTENCY CHECK)
        // ==================================================================

        // If the completion transaction already exists, the booking was already completed
        // Return success without making any changes (idempotent behavior)
        if (existingTransactionDoc.exists) {
          return {
            confirmed: true,
            actor,
            bothConfirmed: true,
            newStatus: BookingStatus.COMPLETED,
            alreadyCompleted: true,
            message: 'Booking has already been completed by both parties',
          };
        }

        // ==================================================================
        // STEP 4.3: BOOKING EXISTENCE CHECK
        // ==================================================================

        if (!bookingDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            `Booking ${bookingId} not found`,
            { code: ResourceErrorCode.BOOKING_NOT_FOUND }
          );
        }

        const booking = bookingDoc.data() as BookingData;
        const userId = context.auth!.uid;

        // ==================================================================
        // STEP 4.4: AUTHORIZATION CHECK
        // ==================================================================

        // Validate that the user is actually the renter or host they claim to be
        // Prevents users from confirming on behalf of others
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

        // ==================================================================
        // STEP 4.5: STATUS VALIDATION
        // ==================================================================

        // Booking must be in "ended" status to be completed
        // Ensures proper state machine flow: ended → completed
        if (booking.status !== BookingStatus.ENDED) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Booking status must be "${BookingStatus.ENDED}" to confirm completion. Current status: "${booking.status}"`,
            { code: StateErrorCode.INVALID_STATE }
          );
        }

        // ==================================================================
        // STEP 4.6: DUPLICATE CONFIRMATION CHECK
        // ==================================================================

        // Check if this actor has already confirmed
        // Prevents double-confirmation from the same party
        const confirmations = booking.completion_confirmations || {};
        if (confirmations[actor] === true) {
          throw new functions.https.HttpsError(
            'already-exists',
            `${actor} has already confirmed booking completion`,
            { code: StateErrorCode.DUPLICATE_ACTION }
          );
        }

        // ==================================================================
        // STEP 4.7: MEDIA VALIDATION (HOST ONLY)
        // ==================================================================

        // If host is confirming, validate that return video has been uploaded
        // This ensures the host has documented the vehicle's condition at return
        if (actor === 'host') {
          try {
            await validateReturnVideoExists(bookingId);
          } catch (error) {
            if (
              error instanceof StorageValidationError &&
              error.code === StorageErrorCode.FILE_NOT_FOUND
            ) {
              throw new functions.https.HttpsError(
                'failed-precondition',
                'Host must upload return condition video before confirming completion',
                {
                  code: EvidenceErrorCode.RETURN_VIDEO_REQUIRED,
                  requiredAction: 'Upload return video',
                  videoPath: `bookings/${bookingId}/host_return_video.mp4`,
                }
              );
            }
            // Re-throw other storage errors
            throw error;
          }
        }

        // ==================================================================
        // STEP 4.8: UPDATE CONFIRMATIONS
        // ==================================================================

        // Update the confirmations object with the current actor's confirmation
        const updatedConfirmations: CompletionConfirmations = {
          ...confirmations,
          [actor]: true,
        };

        // Check if both parties have now confirmed
        const bothConfirmed =
          updatedConfirmations.renter === true &&
          updatedConfirmations.host === true;

        // ==================================================================
        // STEP 4.9: PREPARE BOOKING UPDATE
        // ==================================================================

        // Build the update object for the booking document
        const bookingUpdate: Record<string, unknown> = {
          completion_confirmations: updatedConfirmations,
          [`completion_confirmed_at_${actor}`]: admin.firestore.FieldValue.serverTimestamp(),
        };

        // If both parties have confirmed, finalize the booking
        if (bothConfirmed) {
          bookingUpdate.status = BookingStatus.COMPLETED;
          bookingUpdate.completed_at = admin.firestore.FieldValue.serverTimestamp();
        }

        // ==================================================================
        // STEP 4.10: APPLY BOOKING UPDATE
        // ==================================================================

        transaction.update(bookingRef, bookingUpdate);

        // ==================================================================
        // STEP 4.11: CREATE IMMUTABLE TRANSACTION RECORD (IF BOTH CONFIRMED)
        // ==================================================================

        // When both parties confirm, create an immutable audit trail
        // The deterministic transaction ID ensures this is only created once
        if (bothConfirmed) {
          transaction.set(transactionRef, {
            booking_id: bookingId,
            type: TransactionType.BOOKING_COMPLETED,
            actor: 'system', // System finalizes when both confirm
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            renter_id: booking.renter_id,
            owner_id: booking.owner_id,
            immutable: true,
            // Additional metadata for audit trail
            completion_triggered_by: {
              renter_confirmed: true,
              host_confirmed: true,
            },
          });
        }

        // ==================================================================
        // STEP 4.12: RETURN RESULT
        // ==================================================================

        return {
          confirmed: true,
          actor,
          bothConfirmed,
          newStatus: bothConfirmed ? BookingStatus.COMPLETED : BookingStatus.ENDED,
          alreadyCompleted: false,
          message: bothConfirmed
            ? 'Booking completed successfully'
            : `Waiting for ${actor === 'host' ? 'renter' : 'host'} confirmation`,
        };
      });

      return result;
    } catch (error) {
      // ======================================================================
      // ERROR HANDLING
      // ======================================================================

      // Re-throw HttpsErrors as-is (they're already formatted correctly)
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Log unexpected errors for debugging
      console.error('❌ Error in confirmBookingCompletion:', error);

      // Return generic error to client (don't expose internal details)
      throw new functions.https.HttpsError(
        'internal',
        'An unexpected error occurred while confirming completion'
      );
    }
  }
);