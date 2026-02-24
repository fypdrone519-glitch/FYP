import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {sendPushNotification} from './helpers';
import {BookingData} from './types';
import { BookingStatus } from '../shared';

/**
 * Scheduled function that runs every hour to check for bookings starting today
 * Sends reminders to both renter and owner at midnight (00:00 UTC)
 */
export const sendBookingReminders = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async (context) => {
    //console.log('⏰ Running booking reminders scheduler...');

    try {
      // Get current date at midnight
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
      const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

      //console.log(`📅 Checking bookings for ${todayStart.toISOString().split('T')[0]}`);

      // Query bookings that start today and are host approved and not cancelled
      const bookingsSnapshot = await admin.firestore()
        .collection('bookings')
        .where('start_time', '>=', admin.firestore.Timestamp.fromDate(todayStart))
        .where('start_time', '<=', admin.firestore.Timestamp.fromDate(todayEnd))
        .where('status', '==', BookingStatus.HOST_APPROVED)
        .get();

      if (bookingsSnapshot.empty) {
        console.log('✅ No bookings starting today');
        return;
      }

      //console.log(`📬 Found ${bookingsSnapshot.docs.length} bookings starting today`);

      const promises: Promise<void>[] = [];

      for (const bookingDoc of bookingsSnapshot.docs) {
        const bookingId = bookingDoc.id;
        const bookingData = bookingDoc.data() as BookingData;

        // Skip cancelled bookings
        if (bookingData.cancelled_at) {
          //console.log(`⏭️ Skipping cancelled booking ${bookingId}`);
          continue;
        }

        const {renter_id: renterId, owner_id: ownerId} = bookingData;

        if (!renterId || !ownerId) {
          //console.error(`❌ Missing renter_id or owner_id for booking ${bookingId}`);
          continue;
        }

        // Send notification to renter
        promises.push(
          sendPushNotification(renterId, {
            title: 'Your Rental Starts Today!',
            body: 'Don\'t forget, your rental begins today. Have a great trip!',
            type: 'booking_reminder',
            relatedId: bookingId,
          }).then(() => {
            //console.log(`✅ Reminder sent to renter ${renterId} for booking ${bookingId}`);
          }).catch((error) => {
            console.error(`❌ Failed to send reminder to renter ${renterId}:`, error);
          })
        );

        // Send notification to owner
        promises.push(
          sendPushNotification(ownerId, {
            title: 'Vehicle Rental Today',
            body: 'Your vehicle is booked for rental today. Stay connected with your renter.',
            type: 'booking_reminder',
            relatedId: bookingId,
          }).then(() => {
            //console.log(`✅ Reminder sent to owner ${ownerId} for booking ${bookingId}`);
          }).catch((error) => {
            console.error(`❌ Failed to send reminder to owner ${ownerId}:`, error);
          })
        );
      }

      // Wait for all notifications to be sent
      await Promise.all(promises);

      //console.log(`✅ Booking reminders completed. Sent ${promises.length} notifications.`);
    } catch (error) {
      console.error('❌ Error in sendBookingReminders:', error);
    }
  });
