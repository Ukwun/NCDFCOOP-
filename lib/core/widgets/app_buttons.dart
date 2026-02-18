import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Standard button sizes for consistency
enum ButtonSize {
  small,
  medium,
  large,
}

/// Button styles for different actions
enum ButtonStyle {
  primary, // Main action (filled)
  secondary, // Alternative action (outlined)
  destructive, // Danger action (delete, cancel with consequences)
  ghost, // Tertiary action (text only)
  success, // Success action (green)
}

/// Consistent button component
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle style;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final String? tooltip;
  final double? width;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.style = ButtonStyle.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.tooltip,
    this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonWidget = _buildButton();

    if (tooltip != null) {
      buttonWidget = Tooltip(
        message: tooltip,
        child: buttonWidget,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: buttonWidget);
    }

    return buttonWidget;
  }

  Widget _buildButton() {
    if (isLoading) {
      return _buildLoadingButton();
    }

    final effectiveOnPressed = isEnabled ? onPressed : null;

    return switch (style) {
      ButtonStyle.primary => _buildPrimaryButton(effectiveOnPressed),
      ButtonStyle.secondary => _buildSecondaryButton(effectiveOnPressed),
      ButtonStyle.destructive => _buildDestructiveButton(effectiveOnPressed),
      ButtonStyle.ghost => _buildGhostButton(effectiveOnPressed),
      ButtonStyle.success => _buildSuccessButton(effectiveOnPressed),
    };
  }

  Widget _buildPrimaryButton(VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: _getPadding(),
        backgroundColor:
            onPressed != null ? AppColors.primary : AppColors.surface,
        foregroundColor:
            onPressed != null ? AppColors.surface : AppColors.muted,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildSecondaryButton(VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: _getPadding(),
        side: BorderSide(
          color: onPressed != null ? AppColors.primary : AppColors.surface,
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildDestructiveButton(VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: _getPadding(),
        backgroundColor:
            onPressed != null ? AppColors.error : AppColors.surface,
        foregroundColor:
            onPressed != null ? AppColors.surface : AppColors.muted,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildGhostButton(VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: _getPadding(),
        foregroundColor:
            onPressed != null ? AppColors.primary : AppColors.muted,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildSuccessButton(VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: _getPadding(),
        backgroundColor:
            onPressed != null ? AppColors.success : AppColors.surface,
        foregroundColor:
            onPressed != null ? AppColors.surface : AppColors.muted,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildLoadingButton() {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        padding: _getPadding(),
        backgroundColor: AppColors.primary.withValues(alpha: 0.5),
        foregroundColor: AppColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.surface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      ButtonSize.small =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ButtonSize.medium =>
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ButtonSize.large =>
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    };
  }
}

/// Button group for multiple actions
class AppButtonGroup extends StatelessWidget {
  final List<(String label, VoidCallback onPressed, ButtonStyle style)> buttons;
  final Axis direction;
  final MainAxisAlignment alignment;
  final double spacing;

  const AppButtonGroup({
    required this.buttons,
    this.direction = Axis.horizontal,
    this.alignment = MainAxisAlignment.spaceEvenly,
    this.spacing = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidgets = buttons
        .map(
          (b) => Expanded(
            child: AppButton(
              label: b.$1,
              onPressed: b.$2,
              style: b.$3,
            ),
          ),
        )
        .toList();

    return Flex(
      direction: direction,
      mainAxisAlignment: alignment,
      children: [
        for (int i = 0; i < buttonWidgets.length; i++) ...[
          buttonWidgets[i],
          if (i < buttonWidgets.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// Standard button placements for different screen types
class ButtonPlacementStrategy {
  /// Placement for form screens (login, registration, checkout)
  static Widget formButtonLayout({
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          AppButton(
            label: primaryLabel,
            onPressed: onPrimary,
            style: ButtonStyle.primary,
            size: ButtonSize.large,
            isLoading: isLoading,
            width: double.infinity,
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: secondaryLabel,
              onPressed: onSecondary,
              style: ButtonStyle.secondary,
              size: ButtonSize.large,
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }

  /// Placement for list items (swipe actions, inline actions)
  static Widget listItemButtonLayout({
    String? primaryLabel,
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    String? destructiveLabel,
    VoidCallback? onDestructive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (primaryLabel != null && onPrimary != null)
            AppButton(
              label: primaryLabel,
              onPressed: onPrimary,
              style: ButtonStyle.primary,
              size: ButtonSize.small,
            ),
          if (secondaryLabel != null && onSecondary != null)
            AppButton(
              label: secondaryLabel,
              onPressed: onSecondary,
              style: ButtonStyle.secondary,
              size: ButtonSize.small,
            ),
          if (destructiveLabel != null && onDestructive != null)
            AppButton(
              label: destructiveLabel,
              onPressed: onDestructive,
              style: ButtonStyle.destructive,
              size: ButtonSize.small,
            ),
        ],
      ),
    );
  }

  /// Placement for detail screens (view item, edit, delete)
  static Widget detailScreenButtonLayout({
    String? editLabel,
    VoidCallback? onEdit,
    String? shareLabel,
    VoidCallback? onShare,
    String? deleteLabel,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppButtonGroup(
        buttons: [
          if (editLabel != null && onEdit != null)
            (editLabel, onEdit, ButtonStyle.primary),
          if (shareLabel != null && onShare != null)
            (shareLabel, onShare, ButtonStyle.secondary),
          if (deleteLabel != null && onDelete != null)
            (deleteLabel, onDelete, ButtonStyle.destructive),
        ],
        direction: Axis.vertical,
        spacing: 12,
      ),
    );
  }

  /// Placement for bottom sheet actions
  static Widget bottomSheetButtonLayout({
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? cancelLabel,
    VoidCallback? onCancel,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppButtonGroup(
          buttons: [
            (
              primaryLabel,
              onPrimary,
              ButtonStyle.primary,
            ),
            if (cancelLabel != null && onCancel != null)
              (
                cancelLabel,
                onCancel,
                ButtonStyle.secondary,
              ),
          ],
          direction: Axis.vertical,
          spacing: 12,
        ),
      ),
    );
  }

  /// Floating action button for primary action
  static Widget floatingActionButtonLayout({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool mini = false,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      mini: mini,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      tooltip: label,
      child: Icon(icon),
    );
  }

  /// Placement for confirmation dialogs
  static Widget dialogButtonLayout({
    required String confirmLabel,
    required VoidCallback onConfirm,
    required String cancelLabel,
    required VoidCallback onCancel,
    bool isDangerous = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AppButtonGroup(
        buttons: [
          (
            cancelLabel,
            onCancel,
            ButtonStyle.secondary,
          ),
          (
            confirmLabel,
            onConfirm,
            isDangerous ? ButtonStyle.destructive : ButtonStyle.primary,
          ),
        ],
        spacing: 12,
      ),
    );
  }
}
