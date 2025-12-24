# CarShare - Car Listing App

A Flutter mobile application for car sharing/rental in Pakistan, styled similar to Turo.

## Features

- **Home Screen** with:
  - Top bar with app name and profile icon
  - Big headline: "Find your next ride"
  - Search bar with filter option
  - Quick chips for dates, time, and cities (Karachi, Lahore, Islamabad)
  - Category pills (Economy, SUV, Luxury, Hybrid, 7-seater)
  - Maps section placeholder for nearby cars
  - Car cards with images, ratings, prices, and badges
  - Bottom navigation bar (Home, Favourites, Trips, Inbox, Profile)

## Design System

### Colors
- Background: `#F7F9FB`
- Card Surface: `#FFFFFF`
- Primary Text: `#0F172A`
- Secondary Text: `#64748B`
- Border/Divider: `#E2E8F0`
- Accent (CTA): `#19B394` (Teal/Green)
- Rating Star: `#FFA600`

### Typography
- **Font**: Inter (via Google Fonts)
- **H1**: 30px Bold (Page headlines)
- **H2**: 22px Semibold (Section titles)
- **Body**: 16px Regular (Main text)
- **Meta**: 13px Regular (Labels, helper text)
- **Price**: 20px Bold
- **Button**: 16px Semibold

### Spacing
- Uses 8-pt grid system (8, 16, 24, 32px)
- Card radius: 20px
- Minimum touch targets: 44x44px

## Getting Started

### Prerequisites
- Flutter SDK (3.7.0 or higher)
- Dart SDK (3.7.0 or higher)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── car.dart             # Car data model
├── screens/
│   └── home_screen.dart     # Main home screen
├── theme/
│   ├── app_colors.dart      # Color definitions
│   ├── app_spacing.dart     # Spacing constants
│   └── app_text_styles.dart # Text style definitions
└── widgets/
    ├── car_card.dart        # Car listing card component
    ├── category_chip.dart   # Category filter chip
    └── quick_chip.dart      # Quick action chip
```

## Dependencies

- `google_fonts`: For Inter font family
- `google_maps_flutter`: For maps integration (ready for future implementation)

## Next Steps

- [ ] Integrate Google Maps API to show nearby cars
- [ ] Add car detail screen
- [ ] Implement search and filter functionality
- [ ] Add date/time pickers
- [ ] Connect to backend API
- [ ] Add image loading from URLs
- [ ] Implement navigation between screens
- [ ] Add Urdu language support with Noto Sans Arabic

## Notes

- The maps section is currently a placeholder. To integrate Google Maps:
  1. Get a Google Maps API key
  2. Add it to `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`
  3. Replace the placeholder in `home_screen.dart` with actual Google Maps widget

- Sample car data is hardcoded. Replace with API calls when backend is ready.
