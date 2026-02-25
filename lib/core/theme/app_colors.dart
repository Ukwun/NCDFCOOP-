import 'package:flutter/material.dart';

/// CoopCommerce App Color Palette
///
/// Defines all colors used throughout the application
/// Organized by purpose: primary, secondary, status, and neutral colors
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ==================== PRIMARY COLORS ====================
  /// Main CoopCommerce brand green color
  /// Used for primary buttons, app bar, navigation
  static const Color primary = Color(0xFF1A472A);

  /// Lighter shade of primary color
  /// Used for hover states, disabled states
  static const Color primaryLight = Color(0xFF2D6B3F);

  /// Darker shade of primary color
  /// Used for pressed states, darker accents
  static const Color primaryDark = Color(0xFF0D2817);

  // ==================== SECONDARY COLORS ====================
  /// Orange accent color for highlights and CTAs
  /// Used to draw attention to important actions
  static const Color secondary = Color(0xFFFFA500);

  /// Lighter orange for hover/disabled states
  static const Color secondaryLight = Color(0xFFFFB84D);

  /// Darker orange for pressed states
  static const Color secondaryDark = Color(0xFFE68A00);

  // ==================== STATUS COLORS ====================
  /// Green color for success states
  /// Used for successful operations, confirmations
  static const Color success = Color(0xFF4CAF50);

  /// Light green for success backgrounds
  static const Color successLight = Color(0xFFE8F5E9);

  /// Yellow/Orange for warning states
  /// Used for cautions, notices
  static const Color warning = Color(0xFFFFC107);

  /// Light yellow for warning backgrounds
  static const Color warningLight = Color(0xFFFFF8E1);

  /// Red color for error states
  /// Used for errors, deletions, critical alerts
  static const Color error = Color(0xFFF44336);

  /// Light red for error backgrounds
  static const Color errorLight = Color(0xFFFFEBEE);

  // ==================== NEUTRAL COLORS ====================
  /// Pure white background
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black text
  static const Color black = Color(0xFF000000);

  /// Light gray surface/background
  static const Color surface = Color(0xFFF5F5F5);

  /// Lighter gray for secondary surfaces
  static const Color surfaceLight = Color(0xFFFAFAFA);

  /// Gray for disabled/inactive elements
  static const Color disabled = Color(0xFFBDBDBD);

  /// Light gray for borders and dividers
  static const Color outline = Color(0xFFE0E0E0);

  /// Darker gray for secondary text
  static const Color textSecondary = Color(0xFF757575);

  /// Hint text color (lighter gray)
  static const Color hint = Color(0xFFAAAAAA);

  // ==================== SEMANTIC COLORS ====================
  /// Price/amount text color (typically green)
  static const Color pricePositive = Color(0xFF2E7D32);

  /// Loss/negative amount color (typically red)
  static const Color priceNegative = Color(0xFFD32F2F);

  /// New badge color
  static const Color badge = Color(0xFFFF6B6B);

  /// Sale/discount color
  static const Color sale = Color(0xFFF50000);

  // ==================== HELPER METHODS ====================
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get primary color with opacity (commonly used)
  static Color primaryWithOpacity(double opacity) {
    return primary.withValues(alpha: opacity);
  }

  /// Get background color based on brightness
  static Color getBackgroundColor(Brightness brightness) {
    return brightness == Brightness.light ? surface : Color(0xFF121212);
  }

  /// Get text color based on brightness
  static Color getTextColor(Brightness brightness) {
    return brightness == Brightness.light ? black : white;
  }
}
