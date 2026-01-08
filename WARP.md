# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

CarShare is a Flutter mobile application for car sharing/rental in Pakistan, designed with a Turo-like interface. The app targets Pakistani users with support for local currency (PKR) and major cities (Karachi, Lahore, Islamabad).

**Key Technologies:**
- Flutter SDK 3.7.0+ / Dart SDK 3.7.0+
- Google Maps integration for car location
- Material Design 3 with custom design system
- Geolocator for user location services

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload is automatic - press 'r' in terminal
# Hot restart - press 'R' in terminal
```

### Code Quality
```bash
# Run static analysis
flutter analyze

# Check for linting issues (uses flutter_lints package)
dart analyze

# Format code
dart format lib/ test/

# Format a specific file
dart format <file_path>
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build release APK
flutter build apk --release

# Build iOS (requires macOS)
flutter build ios

# Build for specific platform
flutter build <platform> --release
```

### Maintenance
```bash
# Clean build artifacts
flutter clean

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Get doctor report
flutter doctor
```

## Architecture

### Design System
The app uses a centralized design system in `lib/theme/`:
- **AppColors** (`app_colors.dart`): Color palette including `accent` (#19B394 teal), `background` (dark blue), `cardSurface` (white), and text colors
- **AppSpacing** (`app_spacing.dart`): 8-pt grid system (xs=8, sm=16, md=24, lg=32, xl=40, xxl=48), card radius (20px), minimum touch targets (44px)
- **AppTextStyles** (`app_text_styles.dart`): Typography using Inter font via Google Fonts - h1 (30px bold), h2 (22px semibold), body (16px), meta (13px), price (20px bold), button (16px semibold)

Always use these constants instead of hardcoded values to maintain design consistency.

### Code Organization
```
lib/
├── main.dart                    # Entry point, MaterialApp setup with theme
├── models/                      # Data models
│   └── car.dart                 # Car model with location data
├── screens/                     # Full-page screens
│   ├── main_navigation.dart     # Bottom nav container (Home, Map, Trips, Inbox, Profile)
│   ├── home_screen.dart         # Main listing screen with search/filters
│   └── map_screen.dart          # Google Maps view with carousel
├── theme/                       # Design system
└── widgets/                     # Reusable components
    ├── car_card.dart            # Car listing card with badges
    ├── cars_map.dart            # Google Maps widget with markers
    ├── category_chip.dart       # Filter chips
    └── quick_chip.dart          # Quick action chips
```

### Navigation Pattern
- App uses `MainNavigation` widget with `IndexedStack` for bottom navigation persistence
- Map screen is pushed as a separate route (not in bottom nav stack)
- Placeholder screens exist for Trips, Inbox, and Profile (not yet implemented)

### State Management
- Currently uses StatefulWidget with setState (no formal state management library)
- Sample car data is hardcoded in screens - future: connect to backend API

### Google Maps Integration
- **Android**: API key configured in `android/app/src/main/AndroidManifest.xml`
- **iOS**: API key NOT yet configured in `ios/Runner/AppDelegate.swift` - needs to be added for iOS builds
- Location permissions are requested at runtime via `geolocator` package
- Maps show car markers with info windows; tapping opens bottom sheet or navigates

### UI Patterns
- **CarCard**: Standard car listing with image, badges (Instant/Verified/Delivery), features, rating, trips count, price
- **Bottom Sheets**: Used for detailed car views from map screen
- **Carousel**: Map screen uses `carousel_slider` for horizontal card scrolling
- All cards use 20px border radius
- Images: Currently placeholders, will load from URLs when backend connected

## Development Guidelines

### When Adding New Screens
1. Create screen file in `lib/screens/`
2. Use AppColors, AppSpacing, AppTextStyles from theme
3. Add to navigation in `main_navigation.dart` if it's a main tab
4. Ensure SafeArea wrapping for notch/status bar compatibility

### When Creating New Widgets
1. Place in `lib/widgets/`
2. Make widgets reusable with required parameters
3. Use const constructors where possible
4. Follow existing naming pattern (PascalCase for classes, camelCase for files)

### When Working with Maps
- Test location permissions on physical devices (simulator may not work well)
- Car model requires `latitude` and `longitude` (nullable) for map markers
- Update both Android and iOS configurations when changing Google Maps API key

### Styling Rules
- Always use theme constants (AppColors.accent, AppSpacing.sm, etc.)
- Use GoogleFonts.inter for typography
- Card elevation is 0 with subtle shadows (black @ 0.05 alpha)
- Minimum touch targets: 44x44px

### Future Backend Integration
When connecting to a real backend:
1. Replace hardcoded `_cars` lists in screens with API calls
2. Car model is ready for JSON serialization (add `fromJson`/`toJson` methods)
3. Update image loading - currently handles empty `imageUrl` with placeholder icons
4. Implement proper error handling and loading states

## Pakistan-Specific Context
- Currency: Pakistani Rupees (PKR) - use "Rs" prefix
- Major cities: Karachi, Lahore, Islamabad
- Default map location: Karachi (24.8607, 67.0011)
- Future: Add Urdu language support with Noto Sans Arabic font
