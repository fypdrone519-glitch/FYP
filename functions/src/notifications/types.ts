export type NotificationType =
  | 'booking_created'
  | 'booking_approved'
  | 'booking_rejected'
  | 'booking_cancelled'
  | 'booking_reminder'
  | 'new_message';

export interface NotificationPayload {
  title: string;
  body: string;
  type: NotificationType;
  relatedId: string;
}

export interface UserData {
  fcmTokens?: string[];
  name?: string;
  email?: string;
}

export interface BookingData {
  renter_id: string;
  owner_id: string;
  vehicle_id: string;
  status: string;
  start_time: FirebaseFirestore.Timestamp;
  end_time: FirebaseFirestore.Timestamp;
  approved_at?: FirebaseFirestore.Timestamp | null;
  cancelled_at?: FirebaseFirestore.Timestamp | null;
}

export interface MessageData {
  senderId: string;
  receiverId: string;
  message: string;
  timestamp: FirebaseFirestore.Timestamp;
}

export interface VehicleData {
  make?: string;
  car_name?: string;
  model?: string;
}

export interface PresenceData {
  activeChatRoomId: string | null;
  lastUpdated: FirebaseFirestore.Timestamp;
}
