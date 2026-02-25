import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Banner offering to paste clipboard content into the text input.
///
/// Appears when the clipboard contains translatable text on screen focus.
/// Dismissible via the close button or the Dismiss action.
class ClipboardPasteBanner extends StatelessWidget {
  const ClipboardPasteBanner({
    super.key,
    required this.clipboardText,
    required this.onPaste,
    required this.onDismiss,
  });

  /// Preview of the clipboard content.
  final String clipboardText;

  /// Called when the user taps Paste.
  final VoidCallback onPaste;

  /// Called when the user dismisses the banner.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final preview = clipboardText.length > 50
        ? '${clipboardText.substring(0, 50)}...'
        : clipboardText;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.saffronFaint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.saffron.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.content_paste,
            size: 20,
            color: AppColors.saffronDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste from clipboard?',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.saffronDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.stone600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onPaste,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.terracotta,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Paste'),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.stone400,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -1, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}
