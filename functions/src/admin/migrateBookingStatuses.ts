import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { BookingStatus } from '../shared';
import { requireAdmin } from '../shared/auth';

interface MigrationResult {
  scanned: number;
  updated: number;
  unchanged: number;
}

function toNewStatus(rawStatus: string): string | null {
  const status = rawStatus.trim().toLowerCase();

  if (
    status === 'pending_admin_approval' ||
    status === 'admin_approved' ||
    status === 'host_approved' ||
    status === BookingStatus.STARTED ||
    status === BookingStatus.ENDED ||
    status === BookingStatus.COMPLETED ||
    status === BookingStatus.CANCELLED ||
    status === 'rejected'
  ) {
    return null;
  }

  if (status === 'requested' || status === 'pending') {
    return BookingStatus.PENDING_ADMIN_APPROVAL;
  }

  if (status === 'approved') {
    return BookingStatus.HOST_APPROVED;
  }

  return null;
}

export const migrateBookingStatuses = functions.https.onCall(
  async (_, context): Promise<MigrationResult> => {
    requireAdmin(context);

    const db = admin.firestore();
    const snapshot = await db.collection('bookings').get();
    const docs = snapshot.docs;

    let scanned = 0;
    let updated = 0;
    let unchanged = 0;

    let batch = db.batch();
    let pendingWrites = 0;

    for (const doc of docs) {
      scanned += 1;

      const data = doc.data();
      const rawStatus = typeof data.status === 'string' ? data.status : '';
      const mappedStatus = toNewStatus(rawStatus);

      if (!mappedStatus) {
        unchanged += 1;
        continue;
      }

      batch.update(doc.ref, { status: mappedStatus });
      pendingWrites += 1;
      updated += 1;

      if (pendingWrites >= 400) {
        await batch.commit();
        batch = db.batch();
        pendingWrites = 0;
      }
    }

    if (pendingWrites > 0) {
      await batch.commit();
    }

    return { scanned, updated, unchanged };
  }
);
