import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'chat_detail_screen.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foreground,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        title: Text('Messages', style: AppTextStyles.h1(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primaryText),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: _buildConversationList(),
    );
  }

  Widget _buildConversationList() {
    return StreamBuilder<List<String>>(
      stream: _getChatRoomsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('====== INBOX ERROR ======');
          print('Error: ${snapshot.error}');
          print('Stack trace: ${snapshot.stackTrace}');
          print('========================');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Something went wrong',
                  style: AppTextStyles.body(context),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: AppTextStyles.meta(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          // print('====== INBOX LOADING ======');
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // print('====== INBOX EMPTY ======');
          // print('Has data: ${snapshot.hasData}');
          // print('Data: ${snapshot.data}');
          // print('========================');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No messages yet',
                  style: AppTextStyles.h2(
                    context,
                  ).copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Start a conversation with a car owner',
                  style: AppTextStyles.meta(context),
                ),
              ],
            ),
          );
        }

        // print('====== INBOX DATA ======');
        // print('Chat rooms count: ${snapshot.data!.length}');
        // print('Chat room IDs: ${snapshot.data}');
        // print('=======================');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final chatRoomId = snapshot.data![index];
            // print('Building conversation item for: $chatRoomId');

            return _buildConversationItem(chatRoomId);
          },
        );
      },
    );
  }

  Stream<int> _getUnreadCountStream(String chatRoomId) {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('Chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Widget _buildConversationItem(String chatRoomId) {
    // print('_buildConversationItem called for: $chatRoomId');
    final currentUserId = _auth.currentUser!.uid;
    // print('Current user ID: $currentUserId');

    final otherUserId = chatRoomId
        .split('_')
        .firstWhere((id) => id != currentUserId);
    //print('Other user ID: $otherUserId');

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('Chat_rooms')
              .doc(chatRoomId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
      builder: (context, messageSnapshot) {
        String lastMessage = '';
        String timestamp = '';
        bool isCurrentUserSender = false;

        if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
          final messageData =
              messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          lastMessage = messageData['message'] ?? '';
          isCurrentUserSender = messageData['senderId'] == currentUserId;

          if (messageData['timestamp'] != null) {
            timestamp = _formatTimestamp(messageData['timestamp'] as Timestamp);
          }
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(otherUserId).get(),
          builder: (context, userSnapshot) {
            String userName = 'User';
            String userEmail = '';

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              userName =
                  userData['name'] ??
                  userData['email']?.split('@')[0] ??
                  'User';
              userEmail = userData['email'] ?? '';
            }

            return StreamBuilder<int>(
              stream: _getUnreadCountStream(chatRoomId),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;

                return Material(
                  color: AppColors.cardSurface,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatDetailScreen(
                                receiverId: otherUserId,
                                receiverName: userName,
                                receiverEmail: userEmail,
                              ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.foreground, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.accent.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  userName[0].toUpperCase(),
                                  style: AppTextStyles.h2(
                                    context,
                                  ).copyWith(color: AppColors.accent),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // Message content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          userName,
                                          style: AppTextStyles.body(
                                            context,
                                          ).copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        if (timestamp.isNotEmpty)
                                          Text(
                                            timestamp,
                                            style: AppTextStyles.meta(context),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMessage.isEmpty
                                          ? 'No messages yet'
                                          : isCurrentUserSender
                                          ? 'You: $lastMessage'
                                          : lastMessage,
                                      style: AppTextStyles.meta(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            bottom: AppSpacing.sm,
                            right: AppSpacing.sm,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Stream<List<String>> _getChatRoomsStream() {
    final currentUserId = _auth.currentUser!.uid;
    // print('====== GET CHAT ROOMS STREAM ======');
    // print('Current user ID: $currentUserId');

    return _firestore
        .collection('Chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true) // Sort by most recent message
        .snapshots()
        .map((snapshot) {
          // print('Chat_rooms snapshot received');
          // print('Total chat rooms for user: ${snapshot.docs.length}');

          // Return the chat room IDs (already sorted by lastMessageTime)
          final chatRoomIds = snapshot.docs.map((doc) => doc.id).toList();

          // print('Chat room IDs (sorted): $chatRoomIds');
          // print('==================================');
          return chatRoomIds;
        });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }
}
