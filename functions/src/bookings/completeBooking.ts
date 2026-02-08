/**
 * Cloud Function: completeBooking
 * Marks a booking as completed after the rental period ends.
 * 
 * ADMIN CALLABLE: For manual admin intervention only
 * SCHEDULED: Runs automatically every 15 minutes to complete ended bookings
 */
/**
 * Cloud Function: completeBooking
 * ADMIN ONLY: Manual booking completion override
 * 
 * ⚠️ WARNING: This function is for ADMIN USE ONLY
 * 
 * Normal completion flow should use `confirmBookingCompletion` where both
 * renter and host confirm. This function is only for:
 * - Manual admin intervention
 * - Customer support edge cases
 * - System maintenance
 * 
 * DO NOT expose this to regular users in the UI.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { BookingStatus, TransactionType } from '../shared';

// ============================================================================
// Types
// ============================================================================

interface CompleteBookingRequest {
  bookingId: string;
}

interface BookingData {
  status: string;
  renter_id: string;
  owner_id: string;
  end_time: admin.firestore.Timestamp;
  completed_at?: admin.firestore.Timestamp;
}

// ============================================================================
// Error Codes
// ============================================================================

enum CompleteBookingErrorCode {
  INVALID_STATE = 'INVALID_STATE',
  BOOKING_NOT_FOUND = 'BOOKING_NOT_FOUND',
  ALREADY_COMPLETED = 'ALREADY_COMPLETED',
  UNAUTHORIZED = 'UNAUTHORIZED',
}

// ============================================================================
// Helpers
// ============================================================================

/**
 * Generates a deterministic transaction ID for idempotency.
 * Using the same ID ensures duplicate calls don't create multiple transactions.
 */
function getCompletionTransactionId(bookingId: string): string {
  return `${bookingId}_${TransactionType.BOOKING_COMPLETED}`;
}

/**
 * Validates that the caller has admin privileges.
 * ADMIN ONLY - This is NOT for client use.
 */
function validateAdminAccess(context: functions.https.CallableContext): void {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to call this function',
      { code: CompleteBookingErrorCode.UNAUTHORIZED }
    );
  }

  // Check for admin custom claim
  const isAdmin = context.auth.token?.admin === true;

  if (!isAdmin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'This function can only be called by administrators',
      { code: CompleteBookingErrorCode.UNAUTHORIZED }
    );
  }
}

// ============================================================================
// Cloud Function (Callable - ADMIN ONLY)
// ============================================================================

/**
 * ADMIN ONLY: Manual booking completion
 * Clients should NOT call this - completion is handled automatically by the scheduler
 */
export const completeBooking = functions.https.onCall(
  async (data: CompleteBookingRequest, context) => {
    // ADMIN ACCESS ONLY
    validateAdminAccess(context);

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
    const transactionId = getCompletionTransactionId(bookingId);
    const transactionRef = db.collection('transactions').doc(transactionId);

    try {
      const result = await db.runTransaction(async (transaction) => {
        // Fetch booking and existing transaction in parallel
        const [bookingDoc, existingTransactionDoc] = await Promise.all([
          transaction.get(bookingRef),
          transaction.get(transactionRef),
        ]);

        // Check for idempotency - if transaction already exists, return success
        if (existingTransactionDoc.exists) {
          const bookingData = bookingDoc.data() as BookingData | undefined;
          return {
            completed: true,
            bookingId,
            alreadyCompleted: true,
            status: bookingData?.status || BookingStatus.COMPLETED,
          };
        }

        if (!bookingDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            `Booking ${bookingId} not found`,
            { code: CompleteBookingErrorCode.BOOKING_NOT_FOUND }
          );
        }

        const booking = bookingDoc.data() as BookingData;

        // Idempotency: if already completed, return success without error
        if (booking.status === BookingStatus.COMPLETED) {
          return {
            completed: true,
            bookingId,
            alreadyCompleted: true,
            status: BookingStatus.COMPLETED,
          };
        }

        // Validate booking status is "ended"
        if (booking.status !== BookingStatus.ENDED) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Booking status must be "${BookingStatus.ENDED}" to complete. Current status: "${booking.status}"`,
            { code: CompleteBookingErrorCode.INVALID_STATE }
          );
        }

        // Update booking status to completed
        transaction.update(bookingRef, {
          status: BookingStatus.COMPLETED,
          completed_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Create immutable transaction record with deterministic ID
        transaction.set(transactionRef, {
          booking_id: bookingId,
          type: TransactionType.BOOKING_COMPLETED,
          actor: context.auth?.uid || 'admin',
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          renter_id: booking.renter_id,
          owner_id: booking.owner_id,
          immutable: true,
        });

        return {
          completed: true,
          bookingId,
          alreadyCompleted: false,
          status: BookingStatus.COMPLETED,
        };
      });

      return result;
    } catch (error) {
      // Re-throw HttpsErrors as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      console.error('❌ Error in completeBooking:', error);
      throw new functions.https.HttpsError(
        'internal',
        'An unexpected error occurred'
      );
    }
  }
);

// ============================================================================
// Internal Function (for scheduled jobs)
// ============================================================================

/**
 * Completes a booking programmatically (for use by scheduled functions).
 * This bypasses auth validation since it's called internally.
 */
export async function completeBookingInternal(
  bookingId: string
): Promise<{ completed: boolean; alreadyCompleted: boolean }> {
  const db = admin.firestore();
  const bookingRef = db.collection('bookings').doc(bookingId);
  const transactionId = getCompletionTransactionId(bookingId);
  const transactionRef = db.collection('transactions').doc(transactionId);

  return db.runTransaction(async (transaction) => {
    const [bookingDoc, existingTransactionDoc] = await Promise.all([
      transaction.get(bookingRef),
      transaction.get(transactionRef),
    ]);

    // Idempotency check
    if (existingTransactionDoc.exists) {
      return { completed: true, alreadyCompleted: true };
    }

    if (!bookingDoc.exists) {
      throw new Error(`Booking ${bookingId} not found`);
    }

    const booking = bookingDoc.data() as BookingData;

    // Already completed
    if (booking.status === BookingStatus.COMPLETED) {
      return { completed: true, alreadyCompleted: true };
    }

    // Must be in "ended" state
    if (booking.status !== BookingStatus.ENDED) {
      throw new Error(
        `Booking ${bookingId} status must be "${BookingStatus.ENDED}" to complete. Current: "${booking.status}"`
      );
    }

    // Update booking
    transaction.update(bookingRef, {
      status: BookingStatus.COMPLETED,
      completed_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create transaction record
    transaction.set(transactionRef, {
      booking_id: bookingId,
      type: TransactionType.BOOKING_COMPLETED,
      actor: 'system',
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      renter_id: booking.renter_id,
      owner_id: booking.owner_id,
      immutable: true,
    });

    return { completed: true, alreadyCompleted: false };
  });
}

// ============================================================================
// Scheduled Function (Runs automatically every 15 minutes)
// ============================================================================

/**
 * SCHEDULED: Automatically completes bookings that have ended
 * 
 * Runs every 15 minutes and:
 * 1. Queries all bookings with status "ended" and no completed_at timestamp
 * 2. Checks if end_time has passed
 * 3. Completes each eligible booking using completeBookingInternal()
 * 
 * This is the primary mechanism for booking completion.
 * Clients should NOT trigger completion manually.
 */
export const autoCompleteEndedBookings = functions.pubsub
  .schedule('every 15 minutes')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    console.log('🔄 Starting auto-completion job at', new Date().toISOString());

    try {
      // Query bookings that:
      // 1. Have status "ended"
      // 2. Have no completed_at timestamp (not yet completed)
      // 3. Have end_time in the past
      const endedBookingsSnapshot = await db
        .collection('bookings')
        .where('status', '==', BookingStatus.ENDED)
        .where('completed_at', '==', null)
        .where('end_time', '<', now)
        .limit(100) // Process in batches to avoid timeouts
        .get();

      if (endedBookingsSnapshot.empty) {
        console.log('✅ No ended bookings to complete');
        return null;
      }

      console.log(`📋 Found ${endedBookingsSnapshot.size} bookings to complete`);

      // Complete each booking
      const completionPromises = endedBookingsSnapshot.docs.map(async (doc) => {
        const bookingId = doc.id;
        const bookingData = doc.data() as BookingData;

        try {
          const result = await completeBookingInternal(bookingId);
          
          if (result.alreadyCompleted) {
            console.log(`⏭️  Booking ${bookingId} already completed (skipped)`);
          } else {
            console.log(`✅ Completed booking ${bookingId} (renter: ${bookingData.renter_id})`);
          }

          return { bookingId, success: true, alreadyCompleted: result.alreadyCompleted };
        } catch (error) {
          console.error(`❌ Failed to complete booking ${bookingId}:`, error);
          return { bookingId, success: false, error: String(error) };
        }
      });

      const results = await Promise.allSettled(completionPromises);

      // Summarize results
      const successful = results.filter(
        (r) => r.status === 'fulfilled' && r.value.success
      ).length;
      const alreadyCompleted = results.filter(
        (r) => r.status === 'fulfilled' && r.value.success && r.value.alreadyCompleted
      ).length;
      const failed = results.filter(
        (r) => r.status === 'rejected' || (r.status === 'fulfilled' && !r.value.success)
      ).length;

      console.log(`
🎯 Auto-completion summary:
   - Total processed: ${endedBookingsSnapshot.size}
   - Successfully completed: ${successful - alreadyCompleted}
   - Already completed (idempotent): ${alreadyCompleted}
   - Failed: ${failed}
      `);

      return {
        processed: endedBookingsSnapshot.size,
        successful,
        alreadyCompleted,
        failed,
      };
    } catch (error) {
      console.error('❌ Error in auto-completion job:', error);
      throw error;
    }
  });