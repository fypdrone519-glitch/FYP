/**
 * Structured error codes for UI consumption.
 * These codes are returned in the `details.code` field of HttpsError responses.
 */

/**
 * Evidence-related error codes (photos and videos)
 */
export enum EvidenceErrorCode {
  VIDEO_REQUIRED = 'VIDEO_REQUIRED',
  DAMAGE_PHOTOS_REQUIRED = 'DAMAGE_PHOTOS_REQUIRED',
  RETURN_VIDEO_REQUIRED = 'RETURN_VIDEO_REQUIRED', // NEW: For host return video at completion
}


// ============================================================================
// State Errors
// ============================================================================

export enum StateErrorCode {
  /** Booking is not in the required state for this operation */
  INVALID_STATE = 'INVALID_STATE',
  /** Action has already been performed */
  DUPLICATE_ACTION = 'DUPLICATE_ACTION',
}

// ============================================================================
// Authorization Errors
// ============================================================================

export enum AuthErrorCode {
  /** User is not authorized to perform this action */
  UNAUTHORIZED = 'UNAUTHORIZED',
  /** Invalid actor specified */
  INVALID_ACTOR = 'INVALID_ACTOR',
}

// ============================================================================
// Resource Errors
// ============================================================================

export enum ResourceErrorCode {
  /** Booking not found */
  BOOKING_NOT_FOUND = 'BOOKING_NOT_FOUND',
  /** File not found */
  FILE_NOT_FOUND = 'FILE_NOT_FOUND',
}

// ============================================================================
// Combined Error Code Type
// ============================================================================

export type BookingErrorCode =
  | EvidenceErrorCode
  | StateErrorCode
  | AuthErrorCode
  | ResourceErrorCode;

// ============================================================================
// Error Response Interface
// ============================================================================

export interface StructuredErrorDetails {
  code: BookingErrorCode;
  field?: string;
  requiredAction?: string;
}
