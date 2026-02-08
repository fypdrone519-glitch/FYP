/**
 * Cloud Function: getHostRevenue
 * Aggregates revenue data for host dashboard.
 * Revenue is calculated on-demand, not stored in Firestore.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { BookingStatus } from '../shared';

// ============================================================================
// Constants
// ============================================================================

const PLATFORM_COMMISSION_RATE = 0.10; // 10%

// ============================================================================
// Types
// ============================================================================

interface GetHostRevenueRequest {
  hostId: string;
  /** Optional: filter by date range */
  startDate?: string; // ISO date string
  endDate?: string;   // ISO date string
}

interface BookingData {
  owner_id: string;
  status: string;
  amount_paid?: number;
  completed_at?: FirebaseFirestore.Timestamp;
  start_time?: FirebaseFirestore.Timestamp;
  end_time?: FirebaseFirestore.Timestamp;
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
  amountPaid: number;
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
    const isAdmin = context.auth.token?.admin === true;
    if (context.auth.uid !== hostId && !isAdmin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only view your own revenue'
      );
    }

    try {
      const db = admin.firestore();

      // Build query for completed bookings owned by host
      let query: FirebaseFirestore.Query = db
        .collection('bookings')
        .where('owner_id', '==', hostId)
        .where('status', '==', BookingStatus.COMPLETED);

      // Apply date filters if provided
      let dateRangeApplied: { startDate: string; endDate: string } | undefined;

      if (startDate || endDate) {
        const start = startDate
          ? admin.firestore.Timestamp.fromDate(new Date(startDate))
          : null;
        const end = endDate
          ? admin.firestore.Timestamp.fromDate(new Date(endDate))
          : null;

        if (start) {
          query = query.where('completed_at', '>=', start);
        }
        if (end) {
          query = query.where('completed_at', '<=', end);
        }

        dateRangeApplied = {
          startDate: startDate || 'unbounded',
          endDate: endDate || 'unbounded',
        };
      }

      // Execute query
      const snapshot = await query.get();

      // Aggregate revenue
      let gross = 0;
      const bookings: BookingSummary[] = [];

      snapshot.docs.forEach((doc) => {
        const booking = doc.data() as BookingData;
        const amountPaid = booking.amount_paid || 0;

        gross += amountPaid;

        bookings.push({
          bookingId: doc.id,
          amountPaid,
          completedAt: booking.completed_at?.toDate().toISOString() || null,
          vehicleId: booking.vehicle_id || null,
        });
      });

      // Calculate commission and net
      const platformCommission = roundToTwoDecimals(gross * PLATFORM_COMMISSION_RATE);
      const net = roundToTwoDecimals(gross - platformCommission);

      const response: HostRevenueResponse = {
        hostId,
        revenue: {
          gross: roundToTwoDecimals(gross),
          platformCommission,
          net,
          commissionRate: PLATFORM_COMMISSION_RATE,
        },
        completedBookingsCount: snapshot.size,
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
