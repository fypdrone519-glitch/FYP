/**
 * Shared constants for booking lifecycle states.
 * All Cloud Functions should import from this module for consistency.
 */

// ============================================================================
// Enums
// ============================================================================

/**
 * Represents all possible states of a booking throughout its lifecycle.
 */
export enum BookingStatus {
  REQUESTED = 'requested',
  APPROVED = 'approved',
  STARTED = 'started',
  ENDED = 'ended',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

/**
 * Types of transactions that occur during booking lifecycle.
 */
export enum TransactionType {
  BOOKING_STARTED = 'booking_started',
  BOOKING_ENDED = 'booking_ended',
  BOOKING_COMPLETED = 'booking_completed',
}

/**
 * Status of a transaction record.
 */
export enum TransactionStatus {
  APPROVED = 'approved',
  PENDING_SYNC = 'pending_sync',
}

// ============================================================================
// Validation Helpers
// ============================================================================

/**
 * Checks if a given string is a valid BookingStatus value.
 * @param status - The string to validate
 * @returns true if the status is a valid BookingStatus
 */
export function isValidBookingStatus(status: string): status is BookingStatus {
  return Object.values(BookingStatus).includes(status as BookingStatus);
}

/**
 * Checks if a booking status represents a terminal (final) state.
 * Terminal states are states from which no further transitions are possible.
 * @param status - The BookingStatus to check
 * @returns true if the status is a terminal state
 */
export function isTerminalState(status: BookingStatus): boolean {
  return status === BookingStatus.COMPLETED || status === BookingStatus.CANCELLED;
}
