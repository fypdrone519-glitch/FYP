/**
 * Transaction logging helpers.
 * Transactions are immutable, append-only records.
 */

import * as admin from 'firebase-admin';
import { TransactionType, TransactionStatus } from './bookingConstants';

// ============================================================================
// Types
// ============================================================================

export interface TransactionMetadata {
  renter_id?: string;
  owner_id?: string;
  vehicle_id?: string;
  amount?: number;
  notes?: string;
  [key: string]: unknown;
}

export interface TransactionRecord {
  id: string;
  booking_id: string;
  type: TransactionType;
  actor: string;
  status: TransactionStatus;
  created_at: FirebaseFirestore.Timestamp;
  metadata?: TransactionMetadata;
  immutable: true;
}

export interface CreateTransactionParams {
  bookingId: string;
  type: TransactionType;
  actor: string;
  metadata?: TransactionMetadata;
}

// ============================================================================
// Custom Errors
// ============================================================================

export class TransactionError extends Error {
  constructor(
    message: string,
    public readonly code: TransactionErrorCode
  ) {
    super(message);
    this.name = 'TransactionError';
  }
}

export enum TransactionErrorCode {
  DUPLICATE_TRANSACTION = 'DUPLICATE_TRANSACTION',
  TRANSACTION_EXISTS = 'TRANSACTION_EXISTS',
  MODIFICATION_NOT_ALLOWED = 'MODIFICATION_NOT_ALLOWED',
  INVALID_TRANSACTION_TYPE = 'INVALID_TRANSACTION_TYPE',
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Generates a deterministic transaction ID for idempotency.
 * Format: {bookingId}_{transactionType}
 */
export function generateTransactionId(
  bookingId: string,
  type: TransactionType
): string {
  return `${bookingId}_${type}`;
}

/**
 * Creates an immutable transaction record.
 * Transactions are append-only and cannot be modified or deleted.
 *
 * @param params - Transaction creation parameters
 * @returns The created transaction record
 * @throws TransactionError if transaction already exists
 */
export async function createTransaction(
  params: CreateTransactionParams
): Promise<TransactionRecord> {
  const { bookingId, type, actor, metadata } = params;

  // Validate transaction type
  if (!Object.values(TransactionType).includes(type)) {
    throw new TransactionError(
      `Invalid transaction type: ${type}`,
      TransactionErrorCode.INVALID_TRANSACTION_TYPE
    );
  }

  const db = admin.firestore();
  const transactionId = generateTransactionId(bookingId, type);
  const transactionRef = db.collection('transactions').doc(transactionId);

  // Use Firestore transaction to ensure atomicity
  const result = await db.runTransaction(async (firestoreTransaction) => {
    const existingDoc = await firestoreTransaction.get(transactionRef);

    // Reject if transaction already exists (append-only enforcement)
    if (existingDoc.exists) {
      throw new TransactionError(
        `Transaction ${transactionId} already exists. Transactions are immutable.`,
        TransactionErrorCode.DUPLICATE_TRANSACTION
      );
    }

    const now = admin.firestore.Timestamp.now();

    const transactionData: Omit<TransactionRecord, 'id'> = {
      booking_id: bookingId,
      type,
      actor,
      status: TransactionStatus.APPROVED,
      created_at: now,
      immutable: true,
      ...(metadata && { metadata }),
    };

    firestoreTransaction.set(transactionRef, transactionData);

    return {
      id: transactionId,
      ...transactionData,
    } as TransactionRecord;
  });

  return result;
}

/**
 * Creates a transaction within an existing Firestore transaction.
 * Use this when you need to create a transaction as part of a larger atomic operation.
 *
 * @param firestoreTransaction - The Firestore transaction context
 * @param params - Transaction creation parameters
 * @returns The transaction document reference
 * @throws TransactionError if transaction already exists
 */
export async function createTransactionInTransaction(
  firestoreTransaction: FirebaseFirestore.Transaction,
  params: CreateTransactionParams
): Promise<FirebaseFirestore.DocumentReference> {
  const { bookingId, type, actor, metadata } = params;

  const db = admin.firestore();
  const transactionId = generateTransactionId(bookingId, type);
  const transactionRef = db.collection('transactions').doc(transactionId);

  const existingDoc = await firestoreTransaction.get(transactionRef);

  // Reject if transaction already exists
  if (existingDoc.exists) {
    throw new TransactionError(
      `Transaction ${transactionId} already exists. Transactions are immutable.`,
      TransactionErrorCode.DUPLICATE_TRANSACTION
    );
  }

  const transactionData = {
    booking_id: bookingId,
    type,
    actor,
    status: TransactionStatus.APPROVED,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    immutable: true,
    ...(metadata && { metadata }),
  };

  firestoreTransaction.set(transactionRef, transactionData);

  return transactionRef;
}

/**
 * Checks if a transaction exists for a booking and type.
 * Useful for idempotency checks before attempting operations.
 *
 * @param bookingId - The booking ID
 * @param type - The transaction type
 * @returns true if the transaction exists
 */
export async function transactionExists(
  bookingId: string,
  type: TransactionType
): Promise<boolean> {
  const db = admin.firestore();
  const transactionId = generateTransactionId(bookingId, type);
  const transactionRef = db.collection('transactions').doc(transactionId);

  const doc = await transactionRef.get();
  return doc.exists;
}

/**
 * Retrieves a transaction by booking ID and type.
 *
 * @param bookingId - The booking ID
 * @param type - The transaction type
 * @returns The transaction record or null if not found
 */
export async function getTransaction(
  bookingId: string,
  type: TransactionType
): Promise<TransactionRecord | null> {
  const db = admin.firestore();
  const transactionId = generateTransactionId(bookingId, type);
  const transactionRef = db.collection('transactions').doc(transactionId);

  const doc = await transactionRef.get();

  if (!doc.exists) {
    return null;
  }

  return {
    id: doc.id,
    ...doc.data(),
  } as TransactionRecord;
}

/**
 * Gets all transactions for a booking.
 *
 * @param bookingId - The booking ID
 * @returns Array of transaction records
 */
export async function getTransactionsForBooking(
  bookingId: string
): Promise<TransactionRecord[]> {
  const db = admin.firestore();

  const snapshot = await db
    .collection('transactions')
    .where('booking_id', '==', bookingId)
    .orderBy('created_at', 'asc')
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as TransactionRecord[];
}

// ============================================================================
// Firestore Security Rules Helper (for documentation)
// ============================================================================

/**
 * Recommended Firestore security rules for transactions collection:
 *
 * ```
 * match /transactions/{transactionId} {
 *   // Allow read for authenticated users involved in the booking
 *   allow read: if request.auth != null;
 *
 *   // Allow create only (no update or delete)
 *   allow create: if request.auth != null
 *     && request.resource.data.immutable == true
 *     && request.resource.data.status in ['approved', 'pending_sync'];
 *
 *   // Never allow update or delete
 *   allow update, delete: if false;
 * }
 * ```
 */
