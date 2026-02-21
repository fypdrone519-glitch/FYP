/**
 * Shared module exports.
 * Import from './shared' for all shared constants and utilities.
 */

export {
  BookingStatus,
  PLATFORM_COMMISSION_RATE,
  TransactionType,
  TransactionStatus,
  isValidBookingStatus,
  isTerminalState,
} from './bookingConstants';

export {
  StoragePaths,
  StorageValidationError,
  StorageErrorCode,
  validateStartVideoExists,
  validateHostStartVideoExists,
  validateEndPhotosExist,
  validateReturnVideoExists, // NEW: Export the return video validation
  validateStartVideoUploadPermission,
  validateEndPhotoUploadPermission,
  validateReturnVideoUploadPermission, // NEW: Export the return video upload permission
  preventStartVideoOverwrite,
  preventEndPhotoOverwrite,
  preventReturnVideoOverwrite, // NEW: Export the return video overwrite prevention
  getNextEndPhotoNumber,
} from './storageHelpers';

export {
  TransactionError,
  TransactionErrorCode,
  createTransaction,
  createTransactionInTransaction,
  transactionExists,
  getTransaction,
  getTransactionsForBooking,
  generateTransactionId,
} from './transactionHelpers';

export type {
  TransactionRecord,
  TransactionMetadata,
  CreateTransactionParams,
} from './transactionHelpers';

export {
  EvidenceErrorCode,
  StateErrorCode,
  AuthErrorCode,
  ResourceErrorCode,
} from './errorCodes';

export type {
  BookingErrorCode,
  StructuredErrorDetails,
} from './errorCodes';
