/**
 * Cloud Function: confirmBookingStart
 * Handles start confirmation from BOTH host and renter (two-actor model).
 *
 * FLOW:
 * 1. Host calls first  → sets start_confirmations.host = true
 * 2. Renter calls next → sets start_confirmations.renter = true
 *                      → sets status = STARTED (only when BOTH confirmed)
 *
 * SECURITY RULES:
 * - Only the host OR renter of the booking can confirm
 * - Renter cannot confirm before host has confirmed
 * - Each actor can only confirm once
 * - Both walkaround videos must exist before the trip is fully started
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  BookingStatus,
  PLATFORM_COMMISSION_RATE,
  TransactionType,
  validateHostStartVideoExists,
  validateStartVideoExists,
  StorageValidationError,
  StorageErrorCode,
} from '../shared';
import {
  EvidenceErrorCode,
  StateErrorCode,
  ResourceErrorCode,
} from '../shared/errorCodes';

// ============================================================================
// Types
// ============================================================================

interface ConfirmBookingStartRequest {
  bookingId: string;
  actor: 'host' | 'renter'; // Which party is confirming
}

interface BookingData {
  status: string;
  renter_id: string;
  owner_id: string;
  vehicle_id?: string;
  start_time: admin.firestore.Timestamp;
  amount_paid?: number;
  start_confirmations?: {
    host?: boolean;
    renter?: boolean;
  };
}

function getFundsReceivedTransactionId(bookingId: string): string {
  return `${bookingId}_${TransactionType.FUNDS_RECEIVED}`;
}

// ============================================================================
// Cloud Function
// ============================================================================

export const confirmBookingStart = functions.https.onCall(
  async (data: ConfirmBookingStartRequest, context) => {
    // ── Auth guard ──────────────────────────────────────────────────────────
    const { bookingId, actor } = data;
    console.log(`confirmBookingStart called with bookingId=${bookingId} as actor=${actor}`);
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }


    // ── Input validation ────────────────────────────────────────────────────
    if (!bookingId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId is required'
      );
    }
    if (actor !== 'host' && actor !== 'renter') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'actor must be either "host" or "renter"'
      );
    }

    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);
    const fundsReceivedRef = db
      .collection('transactions')
      .doc(getFundsReceivedTransactionId(bookingId));

    try {
      const result = await db.runTransaction(async (transaction) => {
        const bookingDoc = await transaction.get(bookingRef);

        // ── Booking existence check ───────────────────────────────────────
        if (!bookingDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            `Booking ${bookingId} not found`,
            { code: ResourceErrorCode.BOOKING_NOT_FOUND }
          );
        }

        const booking = bookingDoc.data() as BookingData;
        const userId = context.auth!.uid;
        const startConfirmations = booking.start_confirmations ?? {};

        // ── Actor ownership check ─────────────────────────────────────────
        const isHost = booking.owner_id === userId;
        const isRenter = booking.renter_id === userId;

        if (actor === 'host' && !isHost) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Only the vehicle owner can confirm as host'
          );
        }

        if (actor === 'renter' && !isRenter) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Only the renter can confirm as renter'
          );
        }

        // ── Status check ──────────────────────────────────────────────────
        // Booking must be in an approved state for the host's first confirmation,
        // or already have the host confirmed for the renter's confirmation.
        const normalizedStatus = (booking.status ?? '').trim().toLowerCase();
        const allowedStatuses = [
          BookingStatus.HOST_APPROVED,
          'approved',
          'host_approved',
          'admin_approved',
          // Allow STARTED in case host already confirmed and status was updated early
          BookingStatus.STARTED,
          'started',
        ];

        if (!allowedStatuses.includes(normalizedStatus)) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Booking status "${booking.status}" does not allow trip start confirmation`,
            { code: StateErrorCode.INVALID_STATE }
          );
        }

        // ── Duplicate confirmation guard ──────────────────────────────────
        if (actor === 'host' && startConfirmations.host === true) {
          const bothConfirmed =
            startConfirmations.host === true &&
            startConfirmations.renter === true;
          return {
            confirmed: true,
            bookingId,
            actor,
            bothConfirmed,
            alreadyConfirmed: true,
            newStatus: bothConfirmed ? BookingStatus.STARTED : booking.status,
            message: 'Host has already confirmed trip start',
          };
        }

        if (actor === 'renter' && startConfirmations.renter === true) {
          const bothConfirmed =
            startConfirmations.host === true &&
            startConfirmations.renter === true;
          return {
            confirmed: true,
            bookingId,
            actor,
            bothConfirmed,
            alreadyConfirmed: true,
            newStatus: bothConfirmed ? BookingStatus.STARTED : booking.status,
            message: 'Renter has already confirmed trip start',
          };
        }

        // ── Ordering guard: renter cannot go before host ──────────────────
        if (actor === 'renter' && startConfirmations.host !== true) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Host must confirm trip start before the renter can confirm',
            { code: StateErrorCode.INVALID_STATE }
          );
        }
        // TIME ENFORCEMENT: only allow on or after start date
        const now = admin.firestore.Timestamp.now();
        if (now.toMillis() < booking.start_time.toMillis()) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Trip cannot be started before the scheduled start time',
            { code: StateErrorCode.INVALID_STATE }
          );
        }

        // ── Evidence guard: actor must upload their start walkaround first ──
        try {
          if (actor === 'host') {
            await validateHostStartVideoExists(bookingId);
          } else {
            await validateStartVideoExists(bookingId);
          }
        } catch (error) {
          if (
            error instanceof StorageValidationError &&
            error.code === StorageErrorCode.FILE_NOT_FOUND
          ) {
            throw new functions.https.HttpsError(
              'failed-precondition',
              actor === 'host'
                ? 'Host must upload walkaround video before confirming trip start'
                : 'Renter must upload walkaround video before confirming trip start',
              {
                code: EvidenceErrorCode.VIDEO_REQUIRED,
                requiredAction: actor === 'host'
                  ? 'Upload host walkaround video'
                  : 'Upload renter walkaround video',
              }
            );
          }
          throw error;
        }

        // ── Determine new confirmation state ──────────────────────────────
        const updatedConfirmations = Object.assign(Object.assign({}, startConfirmations), { [actor]: true });

        const bothConfirmed =
          updatedConfirmations.host === true &&
          updatedConfirmations.renter === true;

        // ── Build Firestore update ────────────────────────────────────────
        const bookingUpdate: Record<string, unknown> = {
          start_confirmations: updatedConfirmations,
          [`${actor}_start_confirmed_at`]: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Only flip status to STARTED once BOTH parties have confirmed
        if (bothConfirmed) {
          bookingUpdate['status'] = BookingStatus.STARTED;
          bookingUpdate['started_at'] = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.update(bookingRef, bookingUpdate);

        // Financial ledger entry: renter funds are considered received by platform
        // once the trip has officially started (both confirmations complete).
        if (bothConfirmed) {
          const grossAmount = Number(booking.amount_paid ?? 0);
          const platformFee = Math.round(grossAmount * PLATFORM_COMMISSION_RATE * 100) / 100;
          const hostEarning = Math.round((grossAmount - platformFee) * 100) / 100;

          transaction.set(fundsReceivedRef, {
            booking_id: bookingId,
            type: TransactionType.FUNDS_RECEIVED,
            actor: 'system',
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            renter_id: booking.renter_id,
            owner_id: booking.owner_id,
            vehicle_id: booking.vehicle_id ?? null,
            gross_amount: Math.round(grossAmount * 100) / 100,
            commission_rate: PLATFORM_COMMISSION_RATE,
            platform_fee: platformFee,
            host_earning: hostEarning,
            status: 'approved',
            immutable: true,
          });
        }

        return {
          confirmed: true,
          bookingId,
          actor,
          bothConfirmed,
          alreadyConfirmed: false,
          newStatus: bothConfirmed ? BookingStatus.STARTED : booking.status,
          message: bothConfirmed
            ? 'Both parties confirmed. Trip has started.'
            : actor === 'host'
            ? 'Host confirmed. Waiting for renter to confirm.'
            : 'Renter confirmed.',
        };
      });

      return result;
    } catch (error) {
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
