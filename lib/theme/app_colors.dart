import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Modern Indigo
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryContainer = Color(0xFFF0F0FF);

  // Secondary Colors - Emerald Green
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryContainer = Color(0xFFD1FAE5);

  // Accent Color - Orange/Gold
  static const Color accent = Color(0xFFF3951A);

  // Gold Color - For premium/membership tiers
  static const Color gold = Color(0xFFC9A227);

  // Tertiary Colors - Amber
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryLight = Color(0xFFFBBF24);
  static const Color tertiaryDark = Color(0xFFD97706);
  static const Color tertiaryContainer = Color(0xFFFEF3C7);

  // Background & Surface
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFD0D0D0);

  // Text Colors
  static const Color text = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnTertiary = Color(0xFF000000);
  static const Color muted = Color(0xFF8A8A8A);

  // Error, Success, Warning, Info
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFEAB308);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningDark = Color(0xFFC9A227);
  static const Color warningContainer = Color(0xFFFEF08A);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF93C5FD);
  static const Color infoDark = Color(0xFF1D4ED8);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE5E7EB);

  // Disabled
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color disabledBackground = Color(0xFFF5F5F5);

  // Overlay & Shadow
  static const Color overlay = Color(0x4D000000);
  static const Color scrim = Color(0x33000000);
  static const Color shadow = Color(0x1F000000);
  static const Color shadowDark = Color(0x3F000000);

  // Special Colors
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Product & Commerce Related
  static const Color priceColor = primary;
  static const Color originalPrice = textSecondary;
  static const Color discountBadge = error;
  static const Color availableBadge = success;
  static const Color outOfStockBadge = disabled;

  // Payment Related
  static const Color paymentPending = warning;
  static const Color paymentSuccess = success;
  static const Color paymentFailed = error;
  static const Color paymentProcessing = info;

  // Order Status Colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusConfirmed = Color(0xFF3B82F6);
  static const Color statusProcessing = Color(0xFF8B5CF6);
  static const Color statusShipped = Color(0xFF6366F1);
  static const Color statusDelivered = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusReturned = Color(0xFFF59E0B);

  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
