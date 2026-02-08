/**
 * Cloud Function: getEvidenceStatus
 * Checks the upload status of booking evidence (videos and photos).
 * 
 * SECURITY:
 * - Role-based access control (renter, host, or admin only)
 * - Short-lived signed URLs (5 minutes)
 * - Read-only operation
 * - No storage path exposure to unauthorized users
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { StoragePaths } from '../shared';
import { ResourceErrorCode } from '../shared/errorCodes';

// ============================================================================
// Types
// ============================================================================

interface GetEvidenceStatusRequest {
  bookingId: string;
  includeUrls?: boolean; // Optional: if false, skip signed URL generation
}

interface EvidenceStatus {
  bookingId: string;
  start: {
    videoUploaded: boolean;
    videoPath: string | null;
    videoUrl: string | null;
  };
  end: {
    photosUploaded: boolean;
    photoCount: number;
    photoPaths: string[];
    photoUrls: string[];
  };
  checkedAt: string;
  urlExpiresIn?: string; // Human-readable expiry time
}

interface BookingData {
  renter_id: string;
  owner_id: string;
}

// ============================================================================
// Constants
// ============================================================================

// Signed URL expiry: 5 minutes for enhanced security
const SIGNED_URL_EXPIRY_MS = 5 * 60 * 1000; // 5 minutes

// ============================================================================
// Cloud Function
// ============================================================================

export const getEvidenceStatus = functions.https.onCall(
  async (data: GetEvidenceStatusRequest, context): Promise<EvidenceStatus> => {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { bookingId, includeUrls = true } = data;

    // Validate required parameters
    if (!bookingId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'bookingId is required'
      );
    }

    try {
      const db = admin.firestore();
      const bucket = admin.storage().bucket();

      // Fetch booking to validate access
      const bookingDoc = await db.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          `Booking ${bookingId} not found`,
          { code: ResourceErrorCode.BOOKING_NOT_FOUND }
        );
      }

      const booking = bookingDoc.data() as BookingData;
      const userId = context.auth.uid;

      // ROLE-BASED ACCESS CONTROL: Only renter, host, or admin can check evidence status
      const isAdmin = context.auth.token?.admin === true;
      const isRenter = booking.renter_id === userId;
      const isHost = booking.owner_id === userId;

      if (!isRenter && !isHost && !isAdmin) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'You do not have permission to view this booking\'s evidence'
        );
      }

      // Calculate expiry timestamp for signed URLs
      const expiryTimestamp = Date.now() + SIGNED_URL_EXPIRY_MS;

      // Check start video
      const startVideoPath = StoragePaths.startVideo(bookingId);
      const startVideoFile = bucket.file(startVideoPath);
      const [startVideoExists] = await startVideoFile.exists();

      let startVideoUrl: string | null = null;
      if (startVideoExists && includeUrls) {
        const [url] = await startVideoFile.getSignedUrl({
          action: 'read',
          expires: expiryTimestamp,
        });
        startVideoUrl = url;
      }

      // Check end photos
      const endPhotosPrefix = StoragePaths.endPhotosDir(bookingId);
      const [endPhotoFiles] = await bucket.getFiles({ prefix: endPhotosPrefix });

      // Filter to only include photo_*.jpg files
      const validPhotos = endPhotoFiles.filter((file) =>
        /photo_\d+\.jpg$/.test(file.name)
      );

      const photoPaths = validPhotos.map((file) => file.name);
      const photoUrls: string[] = [];

      // Generate signed URLs for photos (only if requested)
      if (includeUrls) {
        for (const file of validPhotos) {
          const [url] = await file.getSignedUrl({
            action: 'read',
            expires: expiryTimestamp,
          });
          photoUrls.push(url);
        }
      }

      const response: EvidenceStatus = {
        bookingId,
        start: {
          videoUploaded: startVideoExists,
          videoPath: startVideoExists ? startVideoPath : null,
          videoUrl: startVideoUrl,
        },
        end: {
          photosUploaded: validPhotos.length > 0,
          photoCount: validPhotos.length,
          photoPaths,
          photoUrls,
        },
        checkedAt: new Date().toISOString(),
        urlExpiresIn: includeUrls ? '5 minutes' : undefined,
      };

      return response;
    } catch (error) {
      // Re-throw HttpsErrors as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      console.error('❌ Error in getEvidenceStatus:', error);
      throw new functions.https.HttpsError(
        'internal',
        'An unexpected error occurred while checking evidence status'
      );
    }
  }
);