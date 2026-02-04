import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  bookingCreated,
  bookingApproved,
  bookingRejected,
  bookingCancelled,
  bookingReminder,
  newMessage,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return NotificationModel(
      id: snapshot.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: _parseNotificationType(data['type'] as String?),
      relatedId: data['relatedId'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': _notificationTypeToString(type),
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'booking_created':
        return NotificationType.bookingCreated;
      case 'booking_approved':
        return NotificationType.bookingApproved;
      case 'booking_rejected':
        return NotificationType.bookingRejected;
      case 'booking_cancelled':
        return NotificationType.bookingCancelled;
      case 'booking_reminder':
        return NotificationType.bookingReminder;
      case 'new_message':
        return NotificationType.newMessage;
      default:
        return NotificationType.newMessage;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.bookingCreated:
        return 'booking_created';
      case NotificationType.bookingApproved:
        return 'booking_approved';
      case NotificationType.bookingRejected:
        return 'booking_rejected';
      case NotificationType.bookingCancelled:
        return 'booking_cancelled';
      case NotificationType.bookingReminder:
        return 'booking_reminder';
      case NotificationType.newMessage:
        return 'new_message';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
