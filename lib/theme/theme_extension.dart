import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension on BuildContext to get dynamic colors that respect the current theme
extension ThemeColors on BuildContext {
  /// Get dynamic background color based on brightness
  Color get dynamicBackground {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF121212) : AppColors.background;
  }

  /// Get dynamic surface color based on brightness
  Color get dynamicSurface {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : AppColors.surface;
  }

  /// Get dynamic text color based on brightness
  Color get dynamicText {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFFFFFF) : AppColors.text;
  }

  /// Get dynamic text light color based on brightness
  Color get dynamicTextLight {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFFB0B0B0) : AppColors.textLight;
  }

  /// Get dynamic text secondary color based on brightness
  Color get dynamicTextSecondary {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF8A8A8A) : AppColors.textSecondary;
  }

  /// Get dynamic card color based on brightness
  Color get dynamicCard {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A2A2A) : AppColors.surface;
  }

  /// Get dynamic disabled color based on brightness
  Color get dynamicDisabled {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF404040) : AppColors.disabled;
  }

  /// Get dynamic divider color based on brightness
  Color get dynamicDivider {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF3A3A3A) : AppColors.divider;
  }

  /// Get dynamic border color based on brightness
  Color get dynamicBorder {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF3A3A3A) : AppColors.border;
  }
}
