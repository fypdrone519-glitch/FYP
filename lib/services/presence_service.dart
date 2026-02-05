import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user presence to prevent duplicate push notifications
/// when user is actively viewing a chat room
class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sets the active chat room for the current user
  /// This is used by Cloud Functions to determine if a push notification should be sent
  Future<void> setActiveChatRoom(String chatRoomId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('userPresence').doc(userId).set({
        'activeChatRoomId': chatRoomId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      //print('✅ Presence set: User $userId active in chat $chatRoomId');
    } catch (e) {
      print('❌ Error setting presence: $e');
    }
  }

  /// Clears the active chat room for the current user
  /// Call this when user leaves a chat screen
  Future<void> clearActiveChatRoom() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('userPresence').doc(userId).set({
        'activeChatRoomId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      //print('✅ Presence cleared: User $userId no longer in chat');
    } catch (e) {
      print('❌ Error clearing presence: $e');
    }
  }

  /// Gets the active chat room for a specific user
  /// Used for debugging and testing
  Future<String?> getActiveChatRoom(String userId) async {
    try {
      final doc = await _firestore.collection('userPresence').doc(userId).get();
      if (!doc.exists) return null;
      
      return doc.data()?['activeChatRoomId'] as String?;
    } catch (e) {
      print('❌ Error getting presence: $e');
      return null;
    }
  }
}
