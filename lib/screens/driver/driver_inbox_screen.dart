import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:car_listing_app/theme/app_spacing.dart';
import 'package:car_listing_app/theme/app_text_styles.dart';
import '../chat_detail_screen.dart';
import 'package:intl/intl.dart';

class DriverInboxScreen extends StatefulWidget {
  const DriverInboxScreen({super.key});

  @override
  State<DriverInboxScreen> createState() => _DriverInboxScreenState();
}

class _DriverInboxScreenState extends State<DriverInboxScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: screenHeight * 0.032,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Search Bar (UI SAME)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iconsBackground,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.secondaryText,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                hintStyle: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.70,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(child: _buildConversationList(scrollController)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(ScrollController scrollController) {
    return StreamBuilder<List<String>>(
      stream: _getChatRoomsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[300],
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

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildConversationItem(snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildConversationItem(String chatRoomId) {
    final currentUserId = _auth.currentUser!.uid;
    final otherUserId = chatRoomId
        .split('_')
        .firstWhere((id) => id != currentUserId);

    return FutureBuilder<DocumentSnapshot>(
      // 🔥 CHANGED HERE (users → drivers)
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        String userName = 'User';
        String userEmail = '';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userName =
              userData['name'] ?? userData['email']?.split('@')[0] ?? 'User';
          userEmail = userData['email'] ?? '';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.8),
                            AppColors.accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<List<String>> _getChatRoomsStream() {
    final currentUserId = _auth.currentUser!.uid;

    // Step 1: get all chat rooms where driver is participant
    return _firestore
        .collection('Chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<String> activeChatRoomIds = [];

          for (var doc in snapshot.docs) {
            final chatRoomId = doc.id;
            final otherUserId = doc.id
                .split('_')
                .firstWhere((id) => id != currentUserId);

            // Step 2: find active bookings with this user
            final bookingQuery =
                await _firestore
                    .collection('bookings')
                    .where('owner_id', isEqualTo: currentUserId)
                    .where('renter_id', isEqualTo: otherUserId)
                    .orderBy('created_at', descending: true)
                    .get();

            if (bookingQuery.docs.isEmpty) continue;

            final latestBooking =
                bookingQuery.docs.first.data() as Map<String, dynamic>;
            final status = latestBooking['status'];
            final startedAt = latestBooking['started_at'] as Timestamp?;
            final endedAt = latestBooking['ended_at'] as Timestamp?;

            final now = DateTime.now();

            bool canChat = false;

            // Trip is ongoing
            if (status == 'approved' || status == 'started') {
              canChat = true;
            }

            // Trip just ended: allow 30 min window
            if (status == 'ended' && endedAt != null) {
              final endTime = endedAt.toDate();
              if (now.isBefore(endTime.add(const Duration(minutes: 30)))) {
                canChat = true;
              }
            }

            if (canChat) activeChatRoomIds.add(chatRoomId);
          }

          return activeChatRoomIds;
        });
  }
}
