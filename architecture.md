# Architecture Documentation

## Overview
Peer-to-peer car rental platform connecting Renters and Hosts.

**Core Principles:**
- Server-authoritative state
- Immutable financial records
- Media-enforced trust
- Lean MVP (no payouts yet)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter |
| Backend | Firebase (Firestore, Cloud Functions, Storage, Auth, FCM) |
| Cloud Functions Runtime | Node.js 20 |
| Payments | JazzCash (planned, not integrated) |

**Key Configuration Files:**
- `firebase.json` - Firebase project configuration
- `lib/firebase_options.dart` - Firebase initialization options
- `lib/main.dart` - Flutter app entry point
- `functions/src/index.ts` - Cloud Functions entry point
- `functions/package.json` - Node.js dependencies

## Firestore Data Model

**Related Files:**
- **Flutter Services:** `lib/services/booking_service.dart`
- **Cloud Functions:** `functions/src/bookings/`
- **Models:** Data models are defined inline in Firestore documents

### `bookings/{bookingId}`

**Required Fields:**
- `renter_id` - User ID of renter
- `owner_id` - User ID of host
- `vehicle_id` - Reference to vehicle
- `status` - Current booking state (server-controlled)
- `created_at` - Timestamp
- `approved_at` - Timestamp
- `started_at` - Timestamp
- `ended_at` - Timestamp
- `completed_at` - Timestamp
- `start_confirmed_by_renter` - Boolean
- `start_confirmed_by_host` - Boolean
- `end_confirmed_by_renter` - Boolean
- `end_confirmed_by_host` - Boolean

**Status Values:**
- `requested` - Initial state
- `approved` - Host accepted
- `cancelled` - Booking cancelled
- `started` - Rental in progress
- `ended` - Rental concluded
- `completed` - Finalized

**⚠️ Clients cannot update `status` directly. Only Cloud Functions can modify it.**

### `bookings/{bookingId}/transactions/{transactionId}`

Immutable transaction log. Append-only.

**Fields:**
- `type` - Transaction type (`booking_charge`, `refund_pending`)
- `gross_amount` - Total amount
- `platform_fee` - 10% commission
- `host_earning` - Amount host receives
- `status` - `approved` or `pending_refund`
- `created_at` - Timestamp
- `related_booking_id` - Reference to booking

**⚠️ Clients cannot write transactions. Server-only.**

### `Chat_rooms/{chatRoomId}`

**Fields:**
- `participants` - Array of user IDs
- `lastMessage` - Most recent message text
- `lastMessageTime` - Timestamp

### `Chat_rooms/{chatRoomId}/messages/{messageId}`

**Fields:**
- `senderId` - User who sent message
- `receiverId` - User who receives message
- `text` - Message content
- `isRead` - Boolean
- `createdAt` - Timestamp

**Related Files:**
- **Flutter Services:** `lib/services/chat_service.dart`, `lib/services/unread_message_service.dart`
- **Flutter Screens:** `lib/screens/chat_detail_screen.dart`, `lib/screens/inbox_screen.dart`
- **Models:** `lib/models/message.dart`

## Security Model

**⚠️ Note:** Security rules files not found in repository. Rules should be defined in Firebase Console.

### Firestore Rules

**Read Access:**
- Users can only read bookings where they are `renter_id` or `owner_id`

**Write Restrictions:**
- Clients **cannot** change booking `status`
- Clients **cannot** write transactions
- Clients **cannot** delete bookings

**Authority:**
- Cloud Functions are the **only** authority for:
  - Status transitions
  - Transaction creation

### Storage Rules

**Media Enforcement:**

| Phase | Path | Uploader | Rules |
|-------|------|----------|-------|
| Start | `bookings/{bookingId}/start/renter_walkaround.mp4` | Renter | Upload once, no overwrite/delete |
| End | `bookings/{bookingId}/end/{fileName}` | Host | Multiple files allowed, no overwrite/delete |

## Booking Lifecycle

### State Machine

| From | To | Trigger | Enforced By |
|------|-----|---------|-------------|
| `requested` | `approved` | Host approval | Cloud Function |
| `requested` | `cancelled` | Renter cancels | Cloud Function |
| `approved` | `cancelled` | Renter cancels (pre-start) | Cloud Function |
| `approved` | `started` | Renter + start video uploaded | Cloud Function |
| `started` | `ended` | Renter OR Host ends | Cloud Function |
| `ended` | `completed` | Server / confirmation | Cloud Function |

**⚠️ All illegal transitions are rejected by Cloud Functions.**

**Related Files:**
- **Cloud Functions:**
  - `functions/src/bookings/confirmBookingStart.ts` - Handles `approved` → `started` transition
  - `functions/src/bookings/confirmBookingEnd.ts` - Handles `started` → `ended` transition
  - `functions/src/bookings/completeBooking.ts` - Handles `ended` → `completed` transition
  - `functions/src/bookings/getEvidenceStatus.ts` - Validates media requirements
- **Flutter Services:** `lib/services/booking_service.dart`
- **Flutter Screens:** 
  - `lib/screens/car_booking_screen.dart` - Booking creation
  - `lib/screens/booking_details_screen.dart` - Booking status display
  - `lib/screens/trips_screen.dart` - User's trip history

## Media Enforcement Rules

1. **Start Transition:**
   - Booking **cannot** enter `started` unless start video exists at `bookings/{bookingId}/start/renter_walkaround.mp4`

2. **End Transition:**
   - Booking **cannot** enter `ended` unless host uploaded ≥1 photo to `bookings/{bookingId}/end/`

3. **Validation:**
   - Media existence is validated **server-side** before status transition

**Related Files:**
- **Cloud Functions:**
  - `functions/src/shared/storageHelpers.ts` - Media validation utilities
  - `functions/src/bookings/confirmBookingStart.ts` - Validates start video
  - `functions/src/bookings/confirmBookingEnd.ts` - Validates end photos
  - `functions/src/bookings/getEvidenceStatus.ts` - Checks media existence
- **Constants:** `functions/src/shared/bookingConstants.ts` - Media path definitions

## Revenue & Accounting

**Principles:**
- Revenue is derived from `transactions` subcollection, not booking fields
- Platform commission: **10%**
- Calculation: `host_earning = gross_amount - platform_fee`
- Revenue shown only after booking reaches `completed` status
- **No payouts implemented yet** (future feature)

**Example Transaction:**
```
gross_amount: 1000
platform_fee: 100 (10%)
host_earning: 900
```

**Related Files:**
- **Cloud Functions:**
  - `functions/src/shared/transactionHelpers.ts` - Transaction creation utilities
  - `functions/src/revenue/getHostRevenue.ts` - Revenue aggregation
  - `functions/src/bookings/completeBooking.ts` - Creates booking_charge transaction

## Host Dashboard Logic

- Revenue is **aggregated server-side** from transactions
- Client only **reads** computed values
- **No client-side calculations** for financial data
- Dashboard displays:
  - Total earnings
  - Platform fees
  - Booking history

**Related Files:**
- **Flutter Screens:**
  - `lib/screens/host/host_home_screen.dart` - Host dashboard
  - `lib/screens/host/host_profile_screen.dart` - Host profile with revenue
  - `lib/screens/host/add_car.dart` - Add vehicle listing
  - `lib/screens/host/edit_car_screen.dart` - Edit vehicle listing
- **Cloud Functions:** `functions/src/revenue/getHostRevenue.ts`

## Notifications System

### Types
- Push notifications (Firebase Cloud Messaging)
- In-app notification center
- Stored for history

### Events

| Event | Renter Notified | Host Notified |
|-------|----------------|---------------|
| Booking request sent | ❌ | ✅ |
| Booking approved | ✅ | ❌ |
| Booking rejected | ✅ | ❌ |
| Booking day reminder (midnight) | ✅ | ✅ |
| New chat message | ✅ | ✅ |

### Triggers
- **Booking state changes:** Cloud Functions
- **Booking-day reminder:** Scheduled Cloud Function (runs at midnight)

**Related Files:**
- **Cloud Functions:**
  - `functions/src/notifications/bookingCreated.ts` - New booking notifications
  - `functions/src/notifications/bookingUpdated.ts` - Status change notifications
  - `functions/src/notifications/chatMessageCreated.ts` - Chat notifications
  - `functions/src/notifications/bookingReminders.ts` - Scheduled reminders
  - `functions/src/notifications/helpers.ts` - Notification utilities
  - `functions/src/notifications/types.ts` - Type definitions
- **Flutter Services:**
  - `lib/services/notification_service.dart` - FCM integration
- **Flutter Screens:**
  - `lib/screens/notifications_screen.dart` - Notification center
- **Models:** `lib/models/notification_model.dart`

## Personalization & Recommendations

### User Behaviour Tracking

Intent-level behavior is tracked through callable Cloud Functions:
- `logVehicleView({ vehicleId })`
- `logVehicleBooking({ vehicleId })`

**Storage path:**
- `users/{userId}/user_behaviour/summary`

**Stored counters:**
- `category_views.{categoryKey}`
- `price_range_views.{bucketKey}`
- `category_bookings.{categoryKey}`
- `price_range_bookings.{bucketKey}`
- `last_updated`

**Atomicity guarantees:**
- Uses `FieldValue.increment(...)` for counters
- Uses `set(..., { merge: true })` to avoid full-object overwrite

**Signal weights currently implemented:**
- View: `+1` to category and price-range view counters
- Booking: `+3` to category and price-range view counters
- Booking: `+1` to category and price-range booking counters

**Bucket logic:**
- Price bucket size: `5000`
- Formula: `lower = floor(price / 5000) * 5000`, `upper = lower + 5000`, key = `${lower}_${upper}`

### Recommendation Computation

Recommendations are computed from:
1. `users/{userId}/user_behaviour/summary`
2. Candidate vehicles from `vehicles` collection (limit 100)

**Score formula per vehicle:**
- `category_match = category_views[vehicleCategory] + 1 * category_bookings[vehicleCategory]`
- `price_match = price_range_views[vehicleBucket] + 1 * price_range_bookings[vehicleBucket]`
- `score = category_match * 1 + price_match * 1`

**Ranking:**
- Sort by score descending
- Tie-break by vehicle ID ascending
- Top 10 are selected

### Recommendation Cache

**Cache path:**
- `users/{userId}/user_recommendation/summary`

**Cache shape:**
```json
{
  "car_ids": ["car1", "car2", "car3"],
  "generated_at": "timestamp",
  "version": 1
}
```

### Recompute Triggering Model

Uses separate async queue pattern:
- Behavior functions enqueue jobs into `recommendation_jobs/{jobId}`
- Firestore trigger `processRecommendationJob` recomputes and updates cache

Also available on-demand:
- Callable `computeRecommendedCars({ userId })`
- Response:
```json
{
  "recommended_vehicle_ids": ["car1", "car2", "car3"],
  "generated_at": "ISO timestamp"
}
```

### Related Files

- `functions/src/analytics/logVehicleBehavior.ts`
- `functions/src/recommendations/computeRecommendedCars.ts`
- `lib/services/user_behavior_service.dart`
- `USER_BEHAVIOUR.md`
- `USER_RECOMMENDATION.md`

## Out of Scope (MVP)

The following features are **explicitly not implemented** in this version:

- Driver module
- Suspicious case handling
- Automated payouts
- Dispute resolution
- Refund execution (only marked as `pending_refund`)

## Architectural Principles

1. **Server is Source of Truth**
   - Clients request, server validates
   - All business logic runs server-side

2. **Atomic State Transitions**
   - Status changes are validated and atomic
   - No partial state updates

3. **Append-Only Financial Records**
   - Transactions are immutable
   - No updates or deletes allowed

4. **Media as Non-Repudiable Evidence**
   - Videos and photos enforce trust
   - Required for critical state transitions
   - Cannot be overwritten or deleted

5. **Lean MVP**
   - Focus on core rental flow
   - Defer complex features (payouts, disputes)

## Additional Key Files

### Flutter App Structure
- **Authentication:** `lib/services/auth_service.dart`, `lib/screens/auth/`
- **Navigation:** `lib/screens/main_navigation.dart`, `lib/screens/host_navigation.dart`
- **Core Screens:**
  - `lib/screens/home_screen.dart` - Main search/browse
  - `lib/screens/car_details.dart` - Vehicle details
  - `lib/screens/map_screen.dart` - Map view
  - `lib/screens/profile_screen.dart` - User profile
- **Models:** `lib/models/car.dart`, `lib/models/car_filter_model.dart`
- **Theme:** `lib/theme/`

### Cloud Functions Shared Utilities
- `functions/src/shared/bookingConstants.ts` - Booking status and constants
- `functions/src/shared/errorCodes.ts` - Error handling
- `functions/src/shared/storageHelpers.ts` - Firebase Storage utilities
- `functions/src/shared/transactionHelpers.ts` - Transaction management
- `functions/src/shared/index.ts` - Shared exports

### Deployment
- `deploy_notifications.sh` - Deployment script for notification functions
