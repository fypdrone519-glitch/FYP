import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all notification functions
export {onBookingCreated} from './notifications/bookingCreated';
export {onBookingUpdated} from './notifications/bookingUpdated';
export {onChatMessageCreated} from './notifications/chatMessageCreated';
export {sendBookingReminders} from './notifications/bookingReminders';

// Booking lifecycle functions
export { confirmBookingStart } from './bookings/confirmBookingStart';
export { confirmBookingEnd } from './bookings/confirmBookingEnd';
export { confirmBookingCompletion } from './bookings/confirmBookingCompletion'; // NEW
export { completeBooking } from './bookings/completeBooking'; // ADMIN ONLY
export { getEvidenceStatus } from './bookings/getEvidenceStatus';
// ... other exports
// Export revenue functions
export {getHostRevenue} from './revenue/getHostRevenue';
export {logVehicleView, logVehicleBooking} from './analytics/logVehicleBehavior';
export {
  computeRecommendedCars,
  processRecommendationJob,
} from './recommendations/computeRecommendedCars';
export { setAdminRole } from './admin/setAdminRole';
export { approveBookingAsAdmin } from './admin/approveBookingAsAdmin';
export { setTripScore } from './admin/setTripScore';
export { migrateBookingStatuses } from './admin/migrateBookingStatuses';
export { reviewKycRequest } from './admin/reviewKycRequest';
export { submitBookingReview } from './reviews/submitBookingReview';
