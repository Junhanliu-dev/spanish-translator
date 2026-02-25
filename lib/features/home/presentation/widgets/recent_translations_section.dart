import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/translation.dart';

/// Displays the last 3 translations on the home screen.
///
/// Shows a compact preview of recent translations, or an empty state
/// if there is no history.
class RecentTranslationsSection extends StatelessWidget {
  const RecentTranslationsSection({
    super.key,
    required this.translations,
    required this.onViewAll,
    required this.onTap,
  });

  /// The recent translations to display (max 3).
  final List<Translation> translations;

  /// Called when "View all history" is tapped.
  final VoidCallback onViewAll;

  /// Called when a translation item is tapped.
  final ValueChanged<Translation> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Text(
            'Recent',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.stone500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (translations.isEmpty)
          _EmptyState(theme: theme)
        else ...[
          ...translations.map(
            (t) => _RecentItem(
              translation: t,
              onTap: () => onTap(t),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: TextButton(
              onPressed: onViewAll,
              child: Text(
                'View all history \u2192',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.xl3,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.translate,
              size: 48,
              color: AppColors.stone300,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your translations will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.stone500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap any feature above to start',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.stone400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({
    required this.translation,
    required this.onTap,
  });

  final Translation translation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final iconData = switch (translation.type) {
      'speech' => Icons.mic,
      'photo' => Icons.camera_alt,
      _ => Icons.text_fields,
    };

    final iconBg = switch (translation.type) {
      'speech' => AppColors.bilbaoBlueFaint,
      'photo' => AppColors.saffronFaint,
      _ => AppColors.terracottaFaint,
    };

    final iconColor = switch (translation.type) {
      'speech' => AppColors.bilbaoBlue,
      'photo' => AppColors.saffron,
      _ => AppColors.terracotta,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.stone800 : iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translation.sourceText,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    translation.translatedText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.stone500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
