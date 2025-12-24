import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // H1 - Page headline: 28-34px Bold
  static TextStyle h1(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryText,
    );
  }
  
  // H2 - Section title: 20-24px Semibold
  static TextStyle h2(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryText,
    );
  }
  
  // Body - Main text: 15-17px Regular
  static TextStyle body(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.primaryText,
    );
  }
  
  // Meta - Labels, helper text: 12-14px Regular/Medium
  static TextStyle meta(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: AppColors.secondaryText,
    );
  }
  
  // Price: 18-22px Bold
  static TextStyle price(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryText,
    );
  }
  
  // Buttons: 15-17px Semibold
  static TextStyle button(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    );
  }
  
  // Car model name
  static TextStyle carModel(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryText,
    );
  }
}

