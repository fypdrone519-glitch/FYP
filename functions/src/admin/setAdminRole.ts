import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { requireSuperAdmin } from '../shared/auth';

interface SetAdminRoleRequest {
  uid: string;
}

export const setAdminRole = functions.https.onCall(
  async (data: SetAdminRoleRequest, context) => {
    const caller = context.auth?.uid || 'anonymous';
    try {
      requireSuperAdmin(context);
    } catch (error) {
      functions.logger.error('setAdminRole super-admin check failed', {
        callerUid: caller,
      });
      throw error;
    }

    const uid = data?.uid?.trim();
    if (!uid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'uid is required'
      );
    }

    let user: admin.auth.UserRecord;
    try {
      user = await admin.auth().getUser(uid);
    } catch (error) {
      const code =
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        typeof (error as { code?: unknown }).code === 'string'
          ? (error as { code: string }).code
          : '';

      if (code === 'auth/user-not-found') {
        throw new functions.https.HttpsError(
          'not-found',
          `User ${uid} not found`
        );
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to load target user'
      );
    }
    const existingClaims = user.customClaims || {};

    try {
      await admin.auth().setCustomUserClaims(uid, {
        ...existingClaims,
        role: 'admin',
      });
    } catch (error) {
      const code =
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        typeof (error as { code?: unknown }).code === 'string'
          ? (error as { code: string }).code
          : '';

      functions.logger.error('setAdminRole setCustomUserClaims failed', {
        callerUid: caller,
        targetUid: uid,
        errorCode: code || 'unknown',
      });

      throw new functions.https.HttpsError(
        'internal',
        'Failed to assign admin claim'
      );
    }

    // Existing sessions should refresh token to pick up updated claims.
    try {
      await admin.auth().revokeRefreshTokens(uid);
    } catch (error) {
      functions.logger.warn('setAdminRole revokeRefreshTokens failed', {
        callerUid: caller,
        targetUid: uid,
      });
    }

    return {
      success: true,
      uid,
      role: 'admin',
    };
  }
);
