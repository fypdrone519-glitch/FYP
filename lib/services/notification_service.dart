import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../screens/booking_details_screen.dart';
import '../screens/chat_detail_screen.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // print('🔔 Background message: ${message.messageId}');
  // print('📩 Title: ${message.notification?.title}');
  // print('📩 Body: ${message.notification?.body}');
  // print('📩 Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Navigation key for routing from notifications
  static GlobalKey<NavigatorState>? navigatorKey;

  bool _initialized = false;

  /// Initialize the notification service
  /// Call this in main() before runApp()
  Future<void> initialize() async {
    if (_initialized) return;

    //print('🔔 Initializing NotificationService...');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permissions
    await _requestPermissions();

    // Get and save FCM token
    await _getFcmToken();

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((token) {
      //print('🔄 FCM token refreshed: $token');
      _saveFcmToken(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
     //print('🚀 App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }

    _initialized = true;
    //print('✅ NotificationService initialized');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    //print('📱 Notification permission status: ${settings.authorizationStatus}');
  }

  /// Get FCM token and save to Firestore via Cloud Function
  Future<void> _getFcmToken() async {
    try {
      // On iOS, we need to wait for APNs token first
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        
        // If APNs token is not available, wait and retry
        if (apnsToken == null) {
          //print('⏳ Waiting for APNs token...');
          // Wait a bit for APNs token to be available
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _fcm.getAPNSToken();
          
          if (apnsToken == null) {
            //print('⚠️ APNs token still not available, will retry on token refresh');
            // Set up a delayed retry
            Future.delayed(const Duration(seconds: 10), () async {
              final retryApns = await _fcm.getAPNSToken();
              if (retryApns != null) {
               // print('✅ APNs token now available, getting FCM token');
                final token = await _fcm.getToken();
                if (token != null) {
                  //print('📱 FCM Token (retry): $token');
                  await _saveFcmToken(token);
                }
              }
            });
            return;
          }
        }
        //print('✅ APNs token available: ${apnsToken.substring(0, 20)}...');
      }
      
      final token = await _fcm.getToken();
      if (token != null) {
        //print('📱 FCM Token: $token');
        await _saveFcmToken(token);
      }
    } catch (e) {
      //print('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFcmToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      //print('⚠️ No user logged in, cannot save FCM token');
      return;
    }

    try {
      // Save token directly to Firestore
      // In production, you might want to use a callable function for security
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      //print('✅ FCM token saved for user: $userId');
    } catch (e) {
      //print('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages - show local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // print('🔔 Foreground message received');
    // print('📩 Title: ${message.notification?.title}');
    // print('📩 Body: ${message.notification?.body}');
    // print('📩 Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap from background/terminated state
  void _handleNotificationTap(RemoteMessage message) {
    //print('👆 Notification tapped: ${message.data}');
    _navigateFromNotification(message.data);
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    //print('👆 Local notification tapped: ${response.payload}');
    // Parse payload and navigate
    // For now, we'll rely on FCM data payload
  }

  /// Navigate to appropriate screen based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final relatedId = data['relatedId'] as String?;

    if (navigatorKey == null || relatedId == null) {
      //print('⚠️ Cannot navigate: navigatorKey or relatedId is null');
      return;
    }

    final context = navigatorKey!.currentContext;
    if (context == null) {
      print('⚠️ Cannot navigate: no context available');
      return;
    }

    print('🧭 Navigating to: $type with ID: $relatedId');

    switch (type) {
      case 'booking_created':
      case 'booking_approved':
      case 'booking_rejected':
      case 'booking_cancelled':
      case 'booking_reminder':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(
              bookingId: relatedId,
              isHostView: type == 'booking_created',
            ),
          ),
        );
        break;

      case 'new_message':
        // For messages, relatedId contains chatRoomId
        // We need to parse it to get the other user's info
        // Format: userId1_userId2
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          final parts = relatedId.split('_');
          final otherUserId = parts.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );

          if (otherUserId.isNotEmpty) {
            // Fetch user details and navigate
            _navigateToChatWithUserId(context, otherUserId);
          }
        }
        break;

      default:
       // print('⚠️ Unknown notification type: $type');
    }
  }

  /// Navigate to chat screen with user ID
  Future<void> _navigateToChatWithUserId(
      BuildContext context, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final name = userData['name'] as String? ?? 'User';
      final email = userData['email'] as String? ?? '';

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            receiverId: userId,
            receiverName: name,
            receiverEmail: email,
          ),
        ),
      );
    } catch (e) {
      //print('❌ Error navigating to chat: $e');
    }
  }

  /// Stream of notifications for current user
  Stream<List<NotificationModel>> getNotificationsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get unread notification count
  Stream<int> getUnreadCountStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      //print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final unreadDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      //print('✅ All notifications marked as read');
    } catch (e) {
      //print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      //print('✅ Notification deleted: $notificationId');
    } catch (e) {
      //print('❌ Error deleting notification: $e');
    }
  }
}
