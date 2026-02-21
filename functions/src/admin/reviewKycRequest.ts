import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { requireAdmin } from '../shared/auth';

type KycStatus = 'pending' | 'approved' | 'rejected';

interface ReviewKycRequestPayload {
  uid: string;
  status?: KycStatus;
  verification_status?: KycStatus;
}

interface KycRequestData {
  status?: string;
  verification_status?: string;
}

function normalizeStatus(value: string | undefined): KycStatus | null {
  const normalized = (value || '').trim().toLowerCase();
  if (
    normalized === 'pending' ||
    normalized === 'approved' ||
    normalized === 'rejected'
  ) {
    return normalized;
  }
  return null;
}

export const reviewKycRequest = functions.https.onCall(
  async (data: ReviewKycRequestPayload, context) => {
    const auth = requireAdmin(context);
    const uid = data?.uid?.trim();
    const verificationStatus = normalizeStatus(
      data?.verification_status ?? data?.status
    );

    if (!uid) {
      throw new functions.https.HttpsError('invalid-argument', 'uid is required');
    }
    if (!verificationStatus) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'verification_status must be one of: pending, approved, rejected'
      );
    }

    const db = admin.firestore();
    const kycRef = db.collection('kyc_requests').doc(uid);
    const userRef = db.collection('users').doc(uid);

    const kycDoc = await kycRef.get();
    if (!kycDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        `KYC request for user ${uid} not found`
      );
    }

    const kycData = kycDoc.data() as KycRequestData;
    const current = normalizeStatus(
      kycData.verification_status ?? kycData.status
    );
    const alreadyFinal = current === 'approved' || current === 'rejected';
    if (alreadyFinal && current === verificationStatus) {
      return {
        success: true,
        uid,
        verification_status: verificationStatus,
        alreadyApplied: true,
      };
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const kycUpdate: Record<string, unknown> = {
      verification_status: verificationStatus,
      reviewed_by: auth.uid,
      reviewed_at: now,
    };

    if (verificationStatus === 'approved') {
      kycUpdate.approved_by = auth.uid;
      kycUpdate.approved_at = now;
    }

    await kycRef.set(kycUpdate, { merge: true });

    if (verificationStatus === 'approved') {
      await userRef.set(
        {
          is_verified: true,
          verified_at: now,
          verification_status: 'verified',
        },
        { merge: true }
      );
    } else {
      await userRef.set(
        {
          is_verified: false,
          verification_status: 'pending',
        },
        { merge: true }
      );
    }

    return {
      success: true,
      uid,
      verification_status: verificationStatus,
      alreadyApplied: false,
    };
  }
);
