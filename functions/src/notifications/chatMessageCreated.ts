import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {sendPushNotification, storeNotificationInFirestore, getUserName} from './helpers';
import {MessageData, PresenceData} from './types';

/**
 * Trigger when a new chat message is created
 * Sends push notification only if receiver is not actively viewing the chat
 * Always stores notification in Firestore
 */
export const onChatMessageCreated = functions.firestore
  .document('Chat_rooms/{chatRoomId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const chatRoomId = context.params.chatRoomId;
    //const messageId = context.params.messageId;
    const messageData = snapshot.data() as MessageData;

    //console.log(`💬 New message in chat room: ${chatRoomId}`);

    try {
      const {senderId, receiverId, message} = messageData;

      // Don't send notification if sender and receiver are the same (shouldn't happen)
      if (senderId === receiverId) {
        console.log('⚠️ Sender and receiver are the same, skipping notification');
        return;
      }

      // Get sender's name
      const senderName = await getUserName(senderId);

      // Prepare notification payload
      const notificationPayload = {
        title: `New Message from ${senderName}`,
        body: message.length > 50 ? `${message.substring(0, 50)}...` : message,
        type: 'new_message' as const,
        relatedId: chatRoomId,
      };

      // Check if receiver is actively viewing this chat
      const presenceDoc = await admin.firestore()
        .collection('userPresence')
        .doc(receiverId)
        .get();

      let shouldSendPush = true;

      if (presenceDoc.exists) {
        const presenceData = presenceDoc.data() as PresenceData;
        const activeChatRoomId = presenceData.activeChatRoomId;

        if (activeChatRoomId === chatRoomId) {
          console.log(`🔕 Receiver is active in chat ${chatRoomId}, skipping push notification`);
          shouldSendPush = false;
        }
      }

      if (shouldSendPush) {
        // Send push notification
        await sendPushNotification(receiverId, notificationPayload);
        //console.log(`✅ Push notification sent to receiver ${receiverId}`);
      } else {
        // Still store in Firestore for notification center
        await storeNotificationInFirestore(receiverId, notificationPayload);
        //console.log(`✅ Notification stored in Firestore (no push sent)`);
      }
    } catch (error) {
      console.error('❌ Error in onChatMessageCreated:', error);
    }
  });
