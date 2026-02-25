import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// First-launch greeting banner shown at the top of the home screen.
///
/// Displays a welcome message and auto-dismisses when the user taps close
/// or after the ViewModel calls [dismissGreeting].
class GreetingBanner extends StatelessWidget {
  const GreetingBanner({
    super.key,
    required this.onDismiss,
  });

  /// Called when the banner is dismissed.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.stone100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.celebration_outlined,
              color: AppColors.terracotta,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're all set!",
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap any feature to start translating.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.stone600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.stone400,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
