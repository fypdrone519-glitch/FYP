import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

// App theme colors that adapt to light/dark mode
class AppThemeColors {
  final bool isDark;

  AppThemeColors(this.isDark);

  // Background colors
  Color get foreground => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F9FB);
  Color get background => isDark ? const Color(0xFF121212) : const Color.fromARGB(255, 0, 30, 61);
  Color get cardSurface => isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
  
  // Text colors
  Color get primaryText => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  Color get secondaryText => isDark ? const Color(0xFFB0B0B0) : const Color(0xFF64748B);
  Color get lightText => const Color(0xFFFFFFFF);
  
  // Border/Divider colors
  Color get border => isDark ? const Color(0xFF404040) : const Color(0xFFE2E8F0);
  
  // Accent colors (usually stay the same in both modes)
  Color get accent => const Color(0xFF19B394); // Teal/Green
  Color get ratingStar => const Color(0xFFFFA600);
  
  // Additional colors
  Color get white => const Color(0xFFFFFFFF);
  Color get black => const Color(0xFF000000);
  
  // Map pin colors
  Color get mapPinBackground => isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E293B);
  Color get mapPinText => const Color(0xFFFFFFFF);
}
