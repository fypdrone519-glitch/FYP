/**
 * Cloud Function: getHostRevenue
 * Aggregates revenue data for host dashboard.
 * Revenue is calculated on-demand, not stored in Firestore.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { PLATFORM_COMMISSION_RATE, TransactionType } from '../shared';

// ============================================================================
// Types
// ============================================================================

interface GetHostRevenueRequest {
  hostId: string;
  /** Optional: filter by date range */
  startDate?: string; // ISO date string
  endDate?: string;   // ISO date string
}

interface SettlementTransactionData {
  owner_id?: string;
  type?: string;
  booking_id?: string;
  gross_amount?: number;
  platform_fee?: number;
  host_earning?: number;
  created_at?: FirebaseFirestore.Timestamp;
  vehicle_id?: string;
}

interface RevenueBreakdown {
  gross: number;
  platformCommission: number;
  net: number;
  commissionRate: number;
}

interface BookingSummary {
  bookingId: string;
  grossAmount: number;
  platformFee: number;
  hostEarning: number;
  completedAt: string | null;
  vehicleId: string | null;
}

interface HostRevenueResponse {
  hostId: string;
  revenue: RevenueBreakdown;
  completedBookingsCount: number;
  bookings: BookingSummary[];
  calculatedAt: string;
  dateRange?: {
    startDate: string;
    endDate: string;
  };
}

// ============================================================================
// Cloud Function
// ============================================================================

export const getHostRevenue = functions.https.onCall(
  async (data: GetHostRevenueRequest, context): Promise<HostRevenueResponse> => {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { hostId, startDate, endDate } = data;

    // Validate required parameters
    if (!hostId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'hostId is required'
      );
    }

    // Authorization: user can only view their own revenue (unless admin)
    const isAdmin = context.auth.token?.role === 'admin';
    if (context.auth.uid !== hostId && !isAdmin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only view your own revenue'
      );
    }

    try {
      const db = admin.firestore();

      // Read host transactions and filter to settlement events in memory.
      // This avoids requiring new composite indexes during development.
      const snapshot = await db
        .collection('transactions')
        .where('owner_id', '==', hostId)
        .get();

      let dateRangeApplied: { startDate: string; endDate: string } | undefined;
      const start = startDate ? new Date(startDate) : null;
      const end = endDate ? new Date(endDate) : null;
      if (startDate || endDate) {
        dateRangeApplied = {
          startDate: startDate || 'unbounded',
          endDate: endDate || 'unbounded',
        };
      }

      // Aggregate revenue
      let gross = 0;
      let platformCommission = 0;
      let net = 0;
      const bookings: BookingSummary[] = [];

      snapshot.docs.forEach((doc) => {
        const tx = doc.data() as SettlementTransactionData;
        if (tx.type !== TransactionType.FUNDS_SETTLED) return;

        const settledAt = tx.created_at?.toDate();
        if (start && settledAt && settledAt < start) return;
        if (end && settledAt && settledAt > end) return;

        const txGross = Number(tx.gross_amount ?? 0);
        const txPlatformFee = Number(tx.platform_fee ?? 0);
        const txHostEarning = Number(tx.host_earning ?? 0);

        gross += txGross;
        platformCommission += txPlatformFee;
        net += txHostEarning;

        bookings.push({
          bookingId: tx.booking_id || doc.id,
          grossAmount: roundToTwoDecimals(txGross),
          platformFee: roundToTwoDecimals(txPlatformFee),
          hostEarning: roundToTwoDecimals(txHostEarning),
          completedAt: settledAt?.toISOString() || null,
          vehicleId: tx.vehicle_id || null,
        });
      });

      const response: HostRevenueResponse = {
        hostId,
        revenue: {
          gross: roundToTwoDecimals(gross),
          platformCommission: roundToTwoDecimals(platformCommission),
          net: roundToTwoDecimals(net),
          commissionRate: PLATFORM_COMMISSION_RATE,
        },
        completedBookingsCount: bookings.length,
        bookings,
        calculatedAt: new Date().toISOString(),
      };

      if (dateRangeApplied) {
        response.dateRange = dateRangeApplied;
      }

      return response;
    } catch (error) {
      console.error('❌ Error in getHostRevenue:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'An unexpected error occurred while calculating revenue'
      );
    }
  }
);

// ============================================================================
// Helpers
// ============================================================================

/**
 * Rounds a number to two decimal places for currency calculations.
 */
function roundToTwoDecimals(value: number): number {
  return Math.round(value * 100) / 100;
}

// ============================================================================
// Revenue Calculation Utilities (for reuse)
// ============================================================================

/**
 * Calculates revenue breakdown from a gross amount.
 * Can be used by other functions that need revenue calculations.
 */
export function calculateRevenue(gross: number): RevenueBreakdown {
  const platformCommission = roundToTwoDecimals(gross * PLATFORM_COMMISSION_RATE);
  const net = roundToTwoDecimals(gross - platformCommission);

  return {
    gross: roundToTwoDecimals(gross),
    platformCommission,
    net,
    commissionRate: PLATFORM_COMMISSION_RATE,
  };
}

/**
 * Gets the platform commission rate.
 */
export function getPlatformCommissionRate(): number {
  return PLATFORM_COMMISSION_RATE;
}
