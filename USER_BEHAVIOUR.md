# User Behaviour Tracking

This document explains how user intent signals are stored, updated, and weighted.

## Purpose

Track only high-intent events:
- Vehicle detail view
- Vehicle booking action

Ignore low-intent events (for example scrolls, image clicks).

## Source Files

- Cloud Functions entry: `functions/src/analytics/logVehicleBehavior.ts`
- Function exports: `functions/src/index.ts`
- Flutter caller: `lib/services/user_behavior_service.dart`
- View trigger: `lib/screens/car_details.dart`
- Booking trigger: `lib/screens/car_booking_screen.dart`

## Callable Functions

- `logVehicleView({ vehicleId })`
- `logVehicleBooking({ vehicleId })`

Both are authenticated callable functions.

## Storage Path

Data is stored in:

`users/{userId}/user_behaviour/summary`

## Stored Structure

```json
{
  "category_views": {
    "suv": 7,
    "sedan": 3
  },
  "price_range_views": {
    "0_5000": 4,
    "5000_10000": 6
  },
  "category_bookings": {
    "suv": 2
  },
  "price_range_bookings": {
    "5000_10000": 1
  },
  "last_updated": "timestamp"
}
```

## Atomic Update Rules

Updates use:
- `FieldValue.increment(...)` for counters
- `FieldValue.serverTimestamp()` for `last_updated`
- `set(..., { merge: true })`

This ensures counters are atomic and avoids overwriting the full object.

## Backend Normalization

Vehicle metadata is fetched server-side from:

`vehicles/{vehicleId}`

Fields used:
- `vehicle_type` -> category key
- `rent_per_day` -> price bucket key

### Category Key Formula

`sanitizeKey(vehicle_type)`:
- lowercases
- replaces non-alphanumeric chars with `_`
- trims leading/trailing `_`
- fallback: `unknown`

Example:
- `"SUV"` -> `suv`
- `"Mini Van"` -> `mini_van`

### Price Bucket Formula

Bucket size constant:

`PRICE_BUCKET_SIZE = 5000`

Formula:
- `lower = floor(price / 5000) * 5000`
- `upper = lower + 5000`
- `bucket = "${lower}_${upper}"`

Example:
- `rent_per_day = 7200` -> `5000_10000`

## Signal Weights

Constants:
- `VIEW_WEIGHT = 1`
- `BOOKING_WEIGHT = 3`

### On Vehicle View

Increments:
- `category_views[category] += 1`
- `price_range_views[bucket] += 1`

### On Vehicle Booking

Increments:
- weighted view-like counters:
  - `category_views[category] += 3`
  - `price_range_views[bucket] += 3`
- booking counters:
  - `category_bookings[category] += 1`
  - `price_range_bookings[bucket] += 1`

## Recommendation Queue Trigger

After each successful behavior write, a job is enqueued:

`recommendation_jobs/{jobId}`

with:
- `userId`
- `reason` (`vehicle_view` or `vehicle_booking`)
- `created_at`

This is done in `functions/src/analytics/logVehicleBehavior.ts`.
