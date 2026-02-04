import * as functions from 'firebase-functions';
import {sendPushNotification} from './helpers';
import {BookingData} from './types';

/**
 * Trigger when a booking is updated
 * Notifies the renter when booking is approved or rejected/cancelled
 */
export const onBookingUpdated = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const bookingId = context.params.bookingId;
    const beforeData = change.before.data() as BookingData;
    const afterData = change.after.data() as BookingData;

    console.log(`📝 Booking updated: ${bookingId}`);

    try {
      const renterId = afterData.renter_id;
      if (!renterId) {
        console.error('❌ No renter_id found in booking');
        return;
      }

      // Check if booking was approved
      if (!beforeData.approved_at && afterData.approved_at) {
        console.log('✅ Booking approved, notifying renter');
        
        await sendPushNotification(renterId, {
          title: 'Booking Approved!',
          body: 'Your booking request has been approved by the host.',
          type: 'booking_approved',
          relatedId: bookingId,
        });
        
        return;
      }

      // Check if booking was cancelled
      if (!beforeData.cancelled_at && afterData.cancelled_at) {
        // Check status to determine if it was rejected or cancelled
        const status = afterData.status?.toUpperCase();
        
        if (status === 'REJECTED') {
          console.log('❌ Booking rejected, notifying renter');
          
          await sendPushNotification(renterId, {
            title: 'Booking Rejected',
            body: 'Your booking request was not approved by the host.',
            type: 'booking_rejected',
            relatedId: bookingId,
          });
        } else if (status === 'CANCELLED') {
          console.log('🚫 Booking cancelled, notifying renter');
          
          await sendPushNotification(renterId, {
            title: 'Booking Cancelled',
            body: 'Your booking has been cancelled.',
            type: 'booking_cancelled',
            relatedId: bookingId,
          });
        }
      }
    } catch (error) {
      console.error('❌ Error in onBookingUpdated:', error);
    }
  });
