import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverEmail;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final ScrollController _scrollController = ScrollController();
  String? _chatRoomId;

  @override
  void initState() {
    super.initState();
    
    // Generate chat room ID
    final senderId = _chatService.auth.currentUser!.uid;
    final List<String> ids = [senderId, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');
    
    // Mark messages as read when user opens this chat
    // This updates Firestore and triggers UnreadMessageService to hide the red dot
    _chatService.markMessagesAsRead(widget.receiverId);
    
    // Set presence to indicate user is in this chat
    // This prevents push notifications while user is actively viewing the chat
    _presenceService.setActiveChatRoom(_chatRoomId!);
  }

  @override
  void dispose() {
    // Clear presence when leaving chat
    _presenceService.clearActiveChatRoom();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverId,
        _messageController.text.trim(),
      );
      _messageController.clear();
      
      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

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
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              child: Text(
                widget.receiverName[0].toUpperCase(),
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryText),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong',
              style: AppTextStyles.body(context),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No messages yet',
                  style: AppTextStyles.h2(context).copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Send a message to start the conversation',
                  style: AppTextStyles.meta(context),
                ),
              ],
            ),
          );
        }

        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.sm),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final messageDoc = snapshot.data!.docs[index];
            final messageData = messageDoc.data() as Map<String, dynamic>;
            return _buildMessageBubble(messageData);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData) {
    final isCurrentUser = messageData['senderId'] == _chatService.auth.currentUser!.uid;
    final message = messageData['message'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.accent
                    : AppColors.cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: AppTextStyles.body(context).copyWith(
                  color: isCurrentUser
                      ? AppColors.white
                      : AppColors.primaryText,
                ),
              ),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Text(
                  _formatMessageTime(timestamp),
                  style: AppTextStyles.meta(context).copyWith(
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file, color: AppColors.secondaryText),
                onPressed: () {
                  // TODO: Implement attachment functionality
                },
              ),
              // Camera button
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.secondaryText),
                onPressed: () {
                  // TODO: Implement camera functionality
                },
              ),
              // Text input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.foreground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type here',
                      hintStyle: AppTextStyles.body(context).copyWith(
                        color: AppColors.secondaryText,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTextStyles.body(context),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Send button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: AppColors.white),
                  onPressed: _sendMessage,
                  // Using mic icon as placeholder - will send text if available
                  // TODO: Implement voice recording when text is empty
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy HH:mm').format(dateTime);
    }
  }
}
