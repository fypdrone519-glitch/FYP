# Theme Provider Integration Guide

This guide shows how to integrate the ThemeProvider into your app to enable dark mode support.

## Step 1: Update main.dart

Wrap your `MaterialApp` with `ChangeNotifierProvider`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'theme/theme_provider.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'CarShare - Car Listing App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const MainNavigation(),
    );
  }
  
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        surface: AppColors.cardSurface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardTheme(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
  
  ThemeData _buildDarkTheme() {
    final darkColors = AppThemeColors(true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkColors.accent,
        brightness: Brightness.dark,
        surface: darkColors.cardSurface,
      ),
      scaffoldBackgroundColor: darkColors.background,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      cardTheme: CardTheme(
        color: darkColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
```

## Step 2: Using AppThemeColors in Widgets

Replace static `AppColors` with dynamic `AppThemeColors`:

```dart
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppThemeColors(themeProvider.isDarkMode);
    
    return Container(
      color: colors.cardSurface,
      child: Text(
        'Hello',
        style: TextStyle(color: colors.primaryText),
      ),
    );
  }
}
```

## Step 3: Adding a Theme Toggle Button

Add this to your ProfileScreen or settings:

```dart
IconButton(
  icon: Icon(
    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
  ),
  onPressed: () {
    themeProvider.toggleTheme();
  },
)
```

## Benefits

- **Centralized Colors**: All colors are managed from one place
- **Easy Dark Mode**: Toggle between light and dark with one method
- **Future-Proof**: Easy to add more themes or customize colors
- **Type-Safe**: Colors are accessed through getters, preventing typos
