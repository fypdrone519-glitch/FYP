import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service that monitors unread messages across all chat rooms for the current user.
/// 
/// CRITICAL: This service uses a real-time Firestore listener that:
/// 1. Listens to all chat rooms where the user is a participant
/// 2. For each room, checks if unread messages exist (isRead == false, receiverId == currentUserId)
/// 3. Stops scanning as soon as ONE unread message is found (optimization)
/// 4. Emits updates via ValueNotifier for UI consumption
/// 
/// Performance: Optimized for <200 chats per user by using query limits and early exit.
class UnreadMessageService {
  static final UnreadMessageService _instance = UnreadMessageService._internal();
  factory UnreadMessageService() => _instance;
  UnreadMessageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Global notifier that tracks if any unread messages exist.
  /// UI components should listen to this to display the red dot.
  final ValueNotifier<bool> hasUnreadMessages = ValueNotifier<bool>(false);

  /// Active subscription to chat rooms - must be disposed on logout.
  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;

  /// Map of subscriptions to individual message collections.
  /// Key: chatRoomId, Value: StreamSubscription for that room's messages.
  final Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};

  /// Initializes the unread message listener.
  /// MUST be called when user logs in / app starts with authenticated user.
  /// 
  /// How it works:
  /// 1. Subscribes to all chat_rooms where user is a participant
  /// 2. For each chat room, creates a listener for unread messages
  /// 3. Updates hasUnreadMessages immediately when any unread message is detected
  void startListening() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      debugPrint('[UnreadMessageService] No authenticated user, cannot start listening');
      return;
    }

    debugPrint('[UnreadMessageService] Starting listener for user: $currentUserId');

    // Listen to all chat rooms where current user is a participant
    _chatRoomsSubscription = _firestore
        .collection('Chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('[UnreadMessageService] Chat rooms snapshot received: ${snapshot.docs.length} rooms');

        // Cancel old message subscriptions for rooms that no longer exist
        final currentRoomIds = snapshot.docs.map((doc) => doc.id).toSet();
        _messageSubscriptions.keys.toList().forEach((roomId) {
          if (!currentRoomIds.contains(roomId)) {
            _messageSubscriptions[roomId]?.cancel();
            _messageSubscriptions.remove(roomId);
          }
        });

        // For each chat room, listen to unread messages
        for (var doc in snapshot.docs) {
          final chatRoomId = doc.id;
          _listenToUnreadMessagesInRoom(chatRoomId, currentUserId);
        }

        // If no chat rooms exist, set to false
        if (snapshot.docs.isEmpty) {
          hasUnreadMessages.value = false;
        }
      },
      onError: (error) {
        debugPrint('[UnreadMessageService] Error listening to chat rooms: $error');
      },
    );
  }

  /// Listens to unread messages in a specific chat room.
  /// 
  /// CRITICAL OPTIMIZATION: Uses .limit(1) to stop scanning as soon as one unread message is found.
  /// This prevents fetching entire message history and keeps reads minimal.
  /// 
  /// Query filters:
  /// - receiverId == currentUserId (only messages TO this user)
  /// - isRead == false (only unread messages)
  void _listenToUnreadMessagesInRoom(String chatRoomId, String currentUserId) {
    // Skip if already listening to this room
    if (_messageSubscriptions.containsKey(chatRoomId)) {
      return;
    }

    debugPrint('[UnreadMessageService] Setting up listener for room: $chatRoomId');

    // Listen ONLY to unread messages where current user is the receiver
    _messageSubscriptions[chatRoomId] = _firestore
        .collection('Chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .limit(1) // CRITICAL: Stop at first unread message (optimization)
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('[UnreadMessageService] Room $chatRoomId: ${snapshot.docs.length} unread messages');

        // If ANY unread message exists in ANY room, set to true
        if (snapshot.docs.isNotEmpty) {
          hasUnreadMessages.value = true;
        } else {
          // Need to check if OTHER rooms have unread messages
          // This is called when messages are marked as read in this room
          _recheckAllRooms(currentUserId);
        }
      },
      onError: (error) {
        debugPrint('[UnreadMessageService] Error listening to messages in room $chatRoomId: $error');
      },
    );
  }

  /// Rechecks all rooms to determine if any unread messages still exist.
  /// Called when messages are marked as read to update the global state.
  /// 
  /// CRITICAL: This is needed because when one room's messages become read,
  /// we need to verify if OTHER rooms still have unread messages before
  /// setting hasUnreadMessages to false.
  Future<void> _recheckAllRooms(String currentUserId) async {
    bool foundUnread = false;

    // Check each active room subscription
    for (var chatRoomId in _messageSubscriptions.keys) {
      final snapshot = await _firestore
          .collection('Chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        foundUnread = true;
        break; // Early exit optimization
      }
    }

    hasUnreadMessages.value = foundUnread;
    debugPrint('[UnreadMessageService] Recheck complete: hasUnread = $foundUnread');
  }

  /// Stops all listeners and cleans up resources.
  /// MUST be called when user logs out to prevent memory leaks.
  void stopListening() {
    debugPrint('[UnreadMessageService] Stopping all listeners');
    
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;

    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();

    hasUnreadMessages.value = false;
  }

  /// Disposes the service - call this on app shutdown.
  void dispose() {
    stopListening();
    hasUnreadMessages.dispose();
  }
}
