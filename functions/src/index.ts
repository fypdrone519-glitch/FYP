import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all notification functions
export {onBookingCreated} from './notifications/bookingCreated';
export {onBookingUpdated} from './notifications/bookingUpdated';
export {onChatMessageCreated} from './notifications/chatMessageCreated';
export {sendBookingReminders} from './notifications/bookingReminders';
