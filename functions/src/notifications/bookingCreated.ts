import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {sendPushNotification} from './helpers';
import {BookingData, VehicleData} from './types';

/**
 * Trigger when a new booking is created
 * Notifies the vehicle owner about the new booking request
 */
export const onBookingCreated = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snapshot, context) => {
    const bookingId = context.params.bookingId;
    const bookingData = snapshot.data() as BookingData;

    //console.log(`📅 New booking created: ${bookingId}`);

    try {
      const ownerId = bookingData.owner_id;
      if (!ownerId) {
       ///console.error('❌ No owner_id found in booking');
        return;
      }

      // Get vehicle details for better notification message
      let vehicleName = 'your vehicle';
      if (bookingData.vehicle_id) {
        try {
          const vehicleDoc = await admin.firestore()
            .collection('vehicles')
            .doc(bookingData.vehicle_id)
            .get();

          if (vehicleDoc.exists) {
            const vehicleData = vehicleDoc.data() as VehicleData;
            const make = vehicleData.make || '';
            const carName = vehicleData.car_name || '';
            const model = vehicleData.model || '';
            vehicleName = `${make} ${carName} ${model}`.trim() || 'your vehicle';
          }
        } catch (error) {
          //console.error('❌ Error fetching vehicle details:', error);
        }
      }

      // Send notification to owner
      await sendPushNotification(ownerId, {
        title: 'New Booking Request',
        body: `You received a new booking request for ${vehicleName}`,
        type: 'booking_created',
        relatedId: bookingId,
      });

      //console.log(`✅ Notification sent to owner ${ownerId}`);
    } catch (error) {
      console.error('❌ Error in onBookingCreated:', error);
    }
  });
