import 'package:car_listing_app/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  //instance of the firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  //get user stream to diplay all the avaliable users
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore
        .collection('Users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  //send message to the user
  Future<void> sendMessage(String revicerid, message) async {
    //get the current/sender user id
    String senderId = auth.currentUser!.uid;
    String senderEmail = auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message _message = Message(
      senderId: senderId,
      senderEmail: senderEmail,
      receiverId: revicerid,
      message: message,
      timestamp: timestamp,
    );

    //create messages

    List<String> ids = [senderId, revicerid];
    ids.sort();
    String chatRoomId = ids.join('_');

    // Create or update the chat room document with metadata
    await _firestore.collection("Chat_rooms").doc(chatRoomId).set({
      'participants': ids,
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastMessageSenderId': senderId,
    }, SetOptions(merge: true));

    // Add the message to the messages subcollection
    await _firestore
        .collection("Chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(_message.toMap());
  }
  //get messages from the user

  Stream<QuerySnapshot> getMessages(String receiverId) {
    String senderId = auth.currentUser!.uid;
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');
    return _firestore
        .collection("Chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Marks all messages as read for the current user in a specific chat room.
  /// 
  /// CRITICAL: This is called when user opens a chat - it marks ALL messages
  /// where receiverId == currentUserId and isRead == false to isRead = true.
  /// 
  /// This triggers the UnreadMessageService listeners to update the red dot instantly.
  Future<void> markMessagesAsRead(String receiverId) async {
    String senderId = auth.currentUser!.uid;
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // Query all unread messages where current user is the receiver
    final unreadMessages = await _firestore
        .collection("Chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .where('receiverId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();

    // Batch update all unread messages to read
    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
