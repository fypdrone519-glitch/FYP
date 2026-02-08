/**
 * Cloud Function: confirmBookingStart
 * Handles start confirmation from the renter.
 * 
 * SECURITY RULES:
 * - Only renter can confirm start
 * - Booking can only be started after start_time has passed
 * - Walkaround video must be uploaded before confirmation
 * - Race-condition safe with deterministic transaction IDs
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  BookingStatus,
  TransactionType,
  validateStartVideoExists,
  StorageValidationError,
  StorageErrorCode,
} from '../shared';
import {
  EvidenceErrorCode,
  StateErrorCode,
  ResourceErrorCode,
} from '../shared/errorCodes';
import { debug } from 'console';

// ============================================================================
// Types
// ============================================================================

interface ConfirmBookingStartRequest {
  bookingId: string;
}

interface BookingData {
  status: string;
  renter_id: string;
  owner_id: string;
  start_time: admin.firestore.Timestamp;
  start_confirmed?: boolean;
  started_at?: admin.firestore.Timestamp;
}

// ============================================================================
// Helper: Generate deterministic transaction ID for idempotency
// ============================================================================

function getStartingTransactionId(bookingId: string): string {
  return `${bookingId}_${TransactionType.BOOKING_STARTED}`;
}

// ============================================================================
// Cloud Function
// ============================================================================

export const confirmBookingStart = functions.https.onCall(
  async (data: ConfirmBookingStartRequest, context) => {
    // Validate authentication
    debug('confirmBookingStart called with data:', data, 'auth:', context.auth);
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { bookingId } = data;

    // Validate required parameters
    if (!bookingId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId is required'
      );
    }

    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);
    const transactionId = getStartingTransactionId(bookingId);
    const transactionRef = db.collection('transactions').doc(transactionId);

    try {
      const result = await db.runTransaction(async (transaction) => {
        // Fetch booking and check for existing transaction in parallel
        const [bookingDoc, existingTransactionDoc] = await Promise.all([
          transaction.get(bookingRef),
          transaction.get(transactionRef),
        ]);

        // RACE CONDITION GUARD: If transaction already exists, booking was already started
        if (existingTransactionDoc.exists) {
          return {
            confirmed: true,
            bookingId,
            newStatus: BookingStatus.STARTED,
            alreadyStarted: true,
            message: 'Booking has already been started',
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
        const userId = context.auth!.uid;

        // Only renter can confirm start
        if (booking.renter_id !== userId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Only the renter can confirm booking start'
          );
        }

        // Validate booking status is "approved"
        if (booking.status !== BookingStatus.APPROVED) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Booking status must be "${BookingStatus.APPROVED}" to confirm start. Current status: "${booking.status}"`,
            { code: StateErrorCode.INVALID_STATE }
          );
        }

        // Check for duplicate confirmation (backup check in case transaction doesn't exist yet)
        if (booking.start_confirmed === true) {
          throw new functions.https.HttpsError(
            'already-exists',
            'Booking start has already been confirmed',
            { code: StateErrorCode.DUPLICATE_ACTION }
          );
        }

        // TIME ENFORCEMENT: Check if booking start_time has passed
        const now = admin.firestore.Timestamp.now();
        if (!booking.start_time) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Booking does not have a valid start_time',
            { code: StateErrorCode.INVALID_STATE }
          );
        }

        if (now.toMillis() < booking.start_time.toMillis()) {
          const startDate = booking.start_time.toDate();
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Booking cannot be started before the scheduled start time (${startDate.toISOString()})`,
            {
              code: StateErrorCode.INVALID_STATE,
              startTime: startDate.toISOString(),
              message: 'Please wait until the booking period begins',
            }
          );
        }

        // Validate walkaround video exists
        try {
          await validateStartVideoExists(bookingId);
        } catch (error) {
          if (
            error instanceof StorageValidationError &&
            error.code === StorageErrorCode.FILE_NOT_FOUND
          ) {
            throw new functions.https.HttpsError(
              'failed-precondition',
              'Renter must upload walkaround video before confirming start',
              {
                code: EvidenceErrorCode.VIDEO_REQUIRED,
                requiredAction: 'Upload walkaround video',
              }
            );
          }
          throw error;
        }

        // Update booking status to started
        transaction.update(bookingRef, {
          status: BookingStatus.STARTED,
          start_confirmed: true,
          started_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Create immutable transaction record with deterministic ID
        // This ensures that even if function is called twice simultaneously,
        // only one transaction document is created
        transaction.set(transactionRef, {
          booking_id: bookingId,
          type: TransactionType.BOOKING_STARTED,
          actor: 'renter',
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          renter_id: booking.renter_id,
          owner_id: booking.owner_id,
          immutable: true,
        });

        return {
          confirmed: true,
          bookingId,
          newStatus: BookingStatus.STARTED,
          alreadyStarted: false,
        };
      });

      return result;
    } catch (error) {
      // Re-throw HttpsErrors as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      console.error('❌ Error in confirmBookingStart:', error);
      throw new functions.https.HttpsError(
        'internal',
        'An unexpected error occurred'
      );
    }
  }
);
