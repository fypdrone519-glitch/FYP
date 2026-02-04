import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'booking_details_screen.dart';
import 'chat_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foreground,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.h1(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.accent),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await NotificationService().markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService().getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Error loading notifications',
                    style: AppTextStyles.h2(context).copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No notifications yet',
                    style: AppTextStyles.h2(context).copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'You\'ll be notified about bookings\nand messages here',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.meta(context),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a rebuild by doing nothing
              // The stream will automatically update
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationItem(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    // Mark as read
    NotificationService().markAsRead(notification.id);

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.bookingCreated:
      case NotificationType.bookingApproved:
      case NotificationType.bookingRejected:
      case NotificationType.bookingCancelled:
      case NotificationType.bookingReminder:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(
              bookingId: notification.relatedId,
              isHostView: notification.type == NotificationType.bookingCreated,
            ),
          ),
        );
        break;

      case NotificationType.newMessage:
        _navigateToChat(context, notification.relatedId);
        break;
    }
  }

  Future<void> _navigateToChat(BuildContext context, String chatRoomId) async {
    // Parse chat room ID to get other user's ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final parts = chatRoomId.split('_');
    final otherUserId = parts.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return;

    try {
      // Fetch user details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final name = userData['name'] as String? ?? 'User';
      final email = userData['email'] as String? ?? '';

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              receiverId: otherUserId,
              receiverName: name,
              receiverEmail: email,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navigating to chat: $e');
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.cardSurface
            : AppColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withOpacity(0.2)
              : AppColors.accent.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.body(context).copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTextStyles.meta(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.createdAt),
                      style: AppTextStyles.meta(context).copyWith(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.bookingCreated:
        return Icons.calendar_today;
      case NotificationType.bookingApproved:
        return Icons.check_circle;
      case NotificationType.bookingRejected:
        return Icons.cancel;
      case NotificationType.bookingCancelled:
        return Icons.event_busy;
      case NotificationType.bookingReminder:
        return Icons.alarm;
      case NotificationType.newMessage:
        return Icons.message;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.bookingCreated:
        return Colors.blue;
      case NotificationType.bookingApproved:
        return Colors.green;
      case NotificationType.bookingRejected:
      case NotificationType.bookingCancelled:
        return Colors.red;
      case NotificationType.bookingReminder:
        return Colors.orange;
      case NotificationType.newMessage:
        return AppColors.accent;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}
