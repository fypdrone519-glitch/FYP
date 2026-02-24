# User Recommendation System

This document explains how recommendation scores are computed, sorted, cached, and retrieved.

## Source Files

- Recommendation engine: `functions/src/recommendations/computeRecommendedCars.ts`
- Queue enqueue caller: `functions/src/analytics/logVehicleBehavior.ts`
- Function exports: `functions/src/index.ts`

## Inputs

1. User behavior summary:

`users/{userId}/user_behaviour/summary`

2. Candidate vehicles:

`vehicles` collection (limited to 100 docs)

## Triggering Modes

### Async Queue Mode (implemented)

- Behavior events enqueue a job in:
  - `recommendation_jobs/{jobId}`
- Firestore trigger `processRecommendationJob` recomputes recommendations.

### On-demand Callable Mode (implemented)

- Callable: `computeRecommendedCars({ userId })`
- Returns computed list immediately and updates cache.

## Behavior Counters Used

From user behavior summary:
- `category_views`
- `price_range_views`
- `category_bookings`
- `price_range_bookings`

## Candidate Vehicle Features Used

From each vehicle:
- `vehicle_type` -> normalized category key
- `rent_per_day` -> computed price bucket key

Normalization/bucketing matches behavior logic:
- category key sanitization
- price bucket size = `5000`

## Score Formula

Constants:
- `CATEGORY_WEIGHT = 1`
- `PRICE_WEIGHT = 1`
- `BOOKING_SIGNAL_MULTIPLIER = 1`

Per vehicle:

- `category_match = category_views[category] + 1 * category_bookings[category]`
- `price_match = price_range_views[bucket] + 1 * price_range_bookings[bucket]`

Final score:

`score = category_match * 1 + price_match * 1`

Missing keys default to `0`.

## Sorting and Selection

1. Sort by `score` descending.
2. Tie-break by `vehicleId` ascending (lexicographic).
3. Keep top `N = 10`.

## Cache Storage

Recommendations are stored at:

`users/{userId}/user_recommendation/summary`

Stored shape:

```json
{
  "car_ids": ["car1", "car2", "car3"],
  "generated_at": "timestamp",
  "version": 1
}
```

## Callable Response Shape

`computeRecommendedCars` returns:

```json
{
  "recommended_vehicle_ids": ["car1", "car2", "car3"],
  "generated_at": "2026-02-11T13:10:00.000Z"
}
```

## Current Filtering

No candidate filtering is applied right now:
- no owner exclusion
- no availability filtering
- no booking-history filtering

Candidates are simply the first 100 vehicles returned by Firestore query order.
