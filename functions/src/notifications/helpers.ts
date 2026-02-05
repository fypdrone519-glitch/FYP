import * as admin from 'firebase-admin';
import {NotificationPayload, UserData} from './types';

/**
 * Send push notification to a user and store in Firestore
 * @param userId Target user ID
 * @param payload Notification data
 */
export async function sendPushNotification(
  userId: string,
  payload: NotificationPayload
): Promise<void> {
  try {
    //console.log(`📤 Sending notification to user ${userId}:`, payload);

    // Get user's FCM tokens
    const tokens = await getUserFcmTokens(userId);

    if (tokens.length === 0) {
      //console.log(`⚠️ No FCM tokens found for user ${userId}`);
      // Still store the notification in Firestore
      await storeNotificationInFirestore(userId, payload);
      return;
    }

    // Prepare FCM message
    const message: admin.messaging.MulticastMessage = {
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        relatedId: payload.relatedId,
      },
      tokens: tokens,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send notification
    const response = await admin.messaging().sendEachForMulticast(message);

    //  console.log(`✅ Successfully sent ${response.successCount} messages`);

    // Handle failed tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`❌ Failed to send to token ${tokens[idx]}:`, resp.error);
          failedTokens.push(tokens[idx]);
        }
      });

      // Clean up invalid tokens
      if (failedTokens.length > 0) {
        await cleanInvalidTokens(userId, failedTokens);
      }
    }

    // Store notification in Firestore
    await storeNotificationInFirestore(userId, payload);
  } catch (error) {
    console.error(`❌ Error sending notification to ${userId}:`, error);
    // Still try to store in Firestore
    try {
      await storeNotificationInFirestore(userId, payload);
    } catch (storeError) {
      console.error('❌ Failed to store notification in Firestore:', storeError);
    }
  }
}

/**
 * Get user's FCM tokens from Firestore
 * @param userId User ID
 * @returns Array of FCM tokens
 */
export async function getUserFcmTokens(userId: string): Promise<string[]> {
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      //console.log(`⚠️ User document not found: ${userId}`);
      return [];
    }

    const userData = userDoc.data() as UserData;
    return userData.fcmTokens || [];
  } catch (error) {
    console.error(`❌ Error getting FCM tokens for ${userId}:`, error);
    return [];
  }
}

/**
 * Store notification in Firestore for notification center
 * @param userId User ID
 * @param payload Notification data
 */
export async function storeNotificationInFirestore(
  userId: string,
  payload: NotificationPayload
): Promise<void> {
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        title: payload.title,
        body: payload.body,
        type: payload.type,
        relatedId: payload.relatedId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    //  console.log(`✅ Notification stored in Firestore for user ${userId}`);
  } catch (error) {
    console.error(`❌ Error storing notification for ${userId}:`, error);
    throw error;
  }
}

/**
 * Remove invalid FCM tokens from user document
 * @param userId User ID
 * @param invalidTokens Array of invalid tokens to remove
 */
export async function cleanInvalidTokens(
  userId: string,
  invalidTokens: string[]
): Promise<void> {
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });

    //console.log(`🧹 Removed ${invalidTokens.length} invalid tokens for user ${userId}`);
  } catch (error) {
    console.error(`❌ Error cleaning invalid tokens for ${userId}:`, error);
  }
}

/**
 * Get user's name for notifications
 * @param userId User ID
 * @returns User's name or 'User'
 */
export async function getUserName(userId: string): Promise<string> {
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      return 'User';
    }

    const userData = userDoc.data() as UserData;
    return userData.name || 'User';
  } catch (error) {
    console.error(`❌ Error getting user name for ${userId}:`, error);
    return 'User';
  }
}
