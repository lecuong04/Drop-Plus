import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

extension SnackBarExt on BuildContext {
  void _showCustomSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(this);
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 22, color: foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    final colorScheme = Theme.of(this).colorScheme;
    _showCustomSnackBar(
      message: message,
      icon: Symbols.check_circle,
      backgroundColor: colorScheme.tertiaryContainer,
      foregroundColor: colorScheme.onTertiaryContainer,
      borderColor: colorScheme.tertiary.withValues(alpha: 0.5),
    );
  }

  void showErrorSnackBar(String message) {
    final colorScheme = Theme.of(this).colorScheme;
    _showCustomSnackBar(
      message: message,
      icon: Symbols.error,
      backgroundColor: colorScheme.errorContainer,
      foregroundColor: colorScheme.onErrorContainer,
      borderColor: colorScheme.error.withValues(alpha: 0.5),
      duration: const Duration(seconds: 4),
    );
  }

  void showInfoSnackBar(String message) {
    final colorScheme = Theme.of(this).colorScheme;
    _showCustomSnackBar(
      message: message,
      icon: Symbols.info,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      borderColor: colorScheme.primary.withValues(alpha: 0.5),
    );
  }

  void showWarningSnackBar(String message) {
    final colorScheme = Theme.of(this).colorScheme;
    _showCustomSnackBar(
      message: message,
      icon: Symbols.warning,
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      borderColor: colorScheme.secondary.withValues(alpha: 0.5),
    );
  }
}
