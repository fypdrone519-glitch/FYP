import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { BookingStatus } from '../shared';
import { requireAdmin } from '../shared/auth';

interface ApproveBookingAsAdminRequest {
  bookingId: string;
}

interface BookingData {
  status?: string;
}

export const approveBookingAsAdmin = functions.https.onCall(
  async (data: ApproveBookingAsAdminRequest, context) => {
    const auth = requireAdmin(context);
    const bookingId = data?.bookingId?.trim();

    if (!bookingId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId is required'
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

    if (currentStatus === BookingStatus.ADMIN_APPROVED) {
      return {
        success: true,
        bookingId,
        status: BookingStatus.ADMIN_APPROVED,
        alreadyApproved: true,
      };
    }

    if (
      currentStatus !== BookingStatus.PENDING_ADMIN_APPROVAL &&
      currentStatus !== 'requested' &&
      currentStatus !== 'pending'
    ) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Booking must be "${BookingStatus.PENDING_ADMIN_APPROVAL}" before admin approval. Current status: "${currentStatus || 'unknown'}"`
      );
    }

    await bookingRef.update({
      status: BookingStatus.ADMIN_APPROVED,
      admin_approved_at: admin.firestore.FieldValue.serverTimestamp(),
      admin_approved_by: auth.uid,
    });

    return {
      success: true,
      bookingId,
      status: BookingStatus.ADMIN_APPROVED,
      alreadyApproved: false,
    };
  }
);
