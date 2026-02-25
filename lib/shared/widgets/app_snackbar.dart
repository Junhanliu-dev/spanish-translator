import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Static helper to show styled snackbars.
class AppSnackbar {
  AppSnackbar._();

  /// Show a success snackbar with a green check icon.
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      iconColor: const Color(0xFF81C784),
      backgroundColor: AppColors.stone900,
    );
  }

  /// Show an error snackbar with a red error icon.
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      iconColor: const Color(0xFFEF9A9A),
      backgroundColor: const Color(0xFF7F0000),
      duration: const Duration(seconds: 4),
    );
  }

  /// Show an info snackbar with a blue info icon.
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      iconColor: AppColors.bilbaoBlueLight,
      backgroundColor: AppColors.stone900,
    );
  }

  /// Show a snackbar with an undo action.
  static void withUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppColors.stone100,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.stone900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.terracottaLight,
          onPressed: onUndo,
        ),
      ),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.stone100,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
      ),
    );
  }
}
