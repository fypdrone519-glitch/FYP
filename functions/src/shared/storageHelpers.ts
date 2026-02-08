/**
 * Firebase Storage path conventions and helpers for booking evidence.
 */

import * as admin from 'firebase-admin';

// ============================================================================
// Custom Errors
// ============================================================================

export class StorageValidationError extends Error {
  constructor(
    message: string,
    public readonly code: StorageErrorCode
  ) {
    super(message);
    this.name = 'StorageValidationError';
  }
}

export enum StorageErrorCode {
  FILE_NOT_FOUND = 'FILE_NOT_FOUND',
  FILE_ALREADY_EXISTS = 'FILE_ALREADY_EXISTS',
  UNAUTHORIZED_UPLOAD = 'UNAUTHORIZED_UPLOAD',
  INVALID_PATH = 'INVALID_PATH',
}

// ============================================================================
// Path Conventions
// ============================================================================

/**
 * Storage path patterns for booking evidence.
 */
export const StoragePaths = {
  /**
   * Path for renter's walkaround video at booking start.
   * Only the renter may upload this file.
   */
  startVideo: (bookingId: string) =>
    `bookings/${bookingId}/start/renter_walkaround.mp4`,

  /**
   * Path for host's photo at booking end.
   * Only the host may upload these files.
   * @param n - Photo number (1-indexed)
   */
  endPhoto: (bookingId: string, n: number) =>
    `bookings/${bookingId}/end/host/photo_${n}.jpg`,

  /**
   * Directory path for all host end photos.
   */
  endPhotosDir: (bookingId: string) =>
    `bookings/${bookingId}/end/host/`,

  /**
   * Path for host's return condition video at booking completion.
   * Only the host may upload this file.
   * NEW: Added for manual completion feature
   */
  returnVideo: (bookingId: string) =>
    `bookings/${bookingId}/host_return_video.mp4`,
} as const;

// ============================================================================
// Validation Helpers
// ============================================================================

/**
 * Validates that the renter's start walkaround video exists for a booking.
 * @param bookingId - The booking ID
 * @returns true if the video exists
 * @throws StorageValidationError if the video does not exist
 */
export async function validateStartVideoExists(bookingId: string): Promise<boolean> {
  const bucket = admin.storage().bucket();
  const filePath = StoragePaths.startVideo(bookingId);
  const file = bucket.file(filePath);

  const [exists] = await file.exists();

  if (!exists) {
    throw new StorageValidationError(
      `Start video not found for booking ${bookingId}. Expected at: ${filePath}`,
      StorageErrorCode.FILE_NOT_FOUND
    );
  }

  return true;
}

/**
 * Validates that at least one host end photo exists for a booking.
 * @param bookingId - The booking ID
 * @returns The number of photos found
 * @throws StorageValidationError if no photos exist
 */
export async function validateEndPhotosExist(bookingId: string): Promise<number> {
  const bucket = admin.storage().bucket();
  const prefix = StoragePaths.endPhotosDir(bookingId);

  const [files] = await bucket.getFiles({ prefix });

  // Filter to only include photo_*.jpg files
  const photos = files.filter((file) =>
    /photo_\d+\.jpg$/.test(file.name)
  );

  if (photos.length === 0) {
    throw new StorageValidationError(
      `No end photos found for booking ${bookingId}. Expected at: ${prefix}photo_{n}.jpg`,
      StorageErrorCode.FILE_NOT_FOUND
    );
  }

  return photos.length;
}

/**
 * NEW: Validates that the host's return video exists for booking completion.
 * Required when host confirms booking completion.
 * @param bookingId - The booking ID
 * @returns true if the video exists
 * @throws StorageValidationError if the video does not exist
 */
export async function validateReturnVideoExists(bookingId: string): Promise<boolean> {
  const bucket = admin.storage().bucket();
  const filePath = StoragePaths.returnVideo(bookingId);
  const file = bucket.file(filePath);

  const [exists] = await file.exists();

  if (!exists) {
    throw new StorageValidationError(
      `Return video not found for booking ${bookingId}. Expected at: ${filePath}`,
      StorageErrorCode.FILE_NOT_FOUND
    );
  }

  return true;
}

// ============================================================================
// Upload Permission Helpers
// ============================================================================

/**
 * Validates that a user is authorized to upload the start video.
 * Only the renter may upload the start video.
 * @param bookingId - The booking ID
 * @param userId - The user attempting to upload
 * @throws StorageValidationError if the user is not the renter
 */
export async function validateStartVideoUploadPermission(
  bookingId: string,
  userId: string
): Promise<void> {
  const booking = await getBookingData(bookingId);

  if (booking.renter_id !== userId) {
    throw new StorageValidationError(
      `User ${userId} is not authorized to upload start video. Only the renter may upload.`,
      StorageErrorCode.UNAUTHORIZED_UPLOAD
    );
  }
}

/**
 * Validates that a user is authorized to upload end photos.
 * Only the host (owner) may upload end photos.
 * @param bookingId - The booking ID
 * @param userId - The user attempting to upload
 * @throws StorageValidationError if the user is not the host
 */
export async function validateEndPhotoUploadPermission(
  bookingId: string,
  userId: string
): Promise<void> {
  const booking = await getBookingData(bookingId);

  if (booking.owner_id !== userId) {
    throw new StorageValidationError(
      `User ${userId} is not authorized to upload end photos. Only the host may upload.`,
      StorageErrorCode.UNAUTHORIZED_UPLOAD
    );
  }
}

/**
 * NEW: Validates that a user is authorized to upload the return video.
 * Only the host (owner) may upload the return video.
 * @param bookingId - The booking ID
 * @param userId - The user attempting to upload
 * @throws StorageValidationError if the user is not the host
 */
export async function validateReturnVideoUploadPermission(
  bookingId: string,
  userId: string
): Promise<void> {
  const booking = await getBookingData(bookingId);

  if (booking.owner_id !== userId) {
    throw new StorageValidationError(
      `User ${userId} is not authorized to upload return video. Only the host may upload.`,
      StorageErrorCode.UNAUTHORIZED_UPLOAD
    );
  }
}

// ============================================================================
// Overwrite Prevention
// ============================================================================

/**
 * Checks if the start video already exists and prevents overwrite.
 * @param bookingId - The booking ID
 * @throws StorageValidationError if the file already exists
 */
export async function preventStartVideoOverwrite(bookingId: string): Promise<void> {
  const bucket = admin.storage().bucket();
  const filePath = StoragePaths.startVideo(bookingId);
  const file = bucket.file(filePath);

  const [exists] = await file.exists();

  if (exists) {
    throw new StorageValidationError(
      `Start video already exists for booking ${bookingId}. Overwrite is not allowed.`,
      StorageErrorCode.FILE_ALREADY_EXISTS
    );
  }
}

/**
 * Checks if an end photo already exists and prevents overwrite.
 * @param bookingId - The booking ID
 * @param photoNumber - The photo number
 * @throws StorageValidationError if the file already exists
 */
export async function preventEndPhotoOverwrite(
  bookingId: string,
  photoNumber: number
): Promise<void> {
  const bucket = admin.storage().bucket();
  const filePath = StoragePaths.endPhoto(bookingId, photoNumber);
  const file = bucket.file(filePath);

  const [exists] = await file.exists();

  if (exists) {
    throw new StorageValidationError(
      `End photo ${photoNumber} already exists for booking ${bookingId}. Overwrite is not allowed.`,
      StorageErrorCode.FILE_ALREADY_EXISTS
    );
  }
}

/**
 * NEW: Checks if the return video already exists and prevents overwrite.
 * Ensures host cannot replace return video after initial upload.
 * @param bookingId - The booking ID
 * @throws StorageValidationError if the file already exists
 */
export async function preventReturnVideoOverwrite(bookingId: string): Promise<void> {
  const bucket = admin.storage().bucket();
  const filePath = StoragePaths.returnVideo(bookingId);
  const file = bucket.file(filePath);

  const [exists] = await file.exists();

  if (exists) {
    throw new StorageValidationError(
      `Return video already exists for booking ${bookingId}. Overwrite is not allowed.`,
      StorageErrorCode.FILE_ALREADY_EXISTS
    );
  }
}

/**
 * Gets the next available photo number for end photos.
 * @param bookingId - The booking ID
 * @returns The next available photo number (1-indexed)
 */
export async function getNextEndPhotoNumber(bookingId: string): Promise<number> {
  const bucket = admin.storage().bucket();
  const prefix = StoragePaths.endPhotosDir(bookingId);

  const [files] = await bucket.getFiles({ prefix });

  // Extract existing photo numbers
  const existingNumbers = files
    .map((file) => {
      const match = file.name.match(/photo_(\d+)\.jpg$/);
      return match ? parseInt(match[1], 10) : 0;
    })
    .filter((n) => n > 0);

  if (existingNumbers.length === 0) {
    return 1;
  }

  return Math.max(...existingNumbers) + 1;
}

// ============================================================================
// Internal Helpers
// ============================================================================

interface BookingRoles {
  renter_id: string;
  owner_id: string;
}

/**
 * Retrieves booking data from Firestore.
 * @param bookingId - The booking ID
 * @returns The booking document data
 */
async function getBookingData(bookingId: string): Promise<BookingRoles> {
  const bookingDoc = await admin.firestore()
    .collection('bookings')
    .doc(bookingId)
    .get();

  if (!bookingDoc.exists) {
    throw new StorageValidationError(
      `Booking ${bookingId} not found`,
      StorageErrorCode.INVALID_PATH
    );
  }

  const data = bookingDoc.data() as BookingRoles;
  return data;
}