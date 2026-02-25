import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/translation.dart';

/// A single item in the history list.
///
/// Shows type icon, source/translation snippets, timestamp, and bookmark
/// status. Supports swipe-to-delete via Dismissible.
class HistoryListItem extends StatelessWidget {
  const HistoryListItem({
    super.key,
    required this.translation,
    required this.onTap,
    required this.onDismissed,
    required this.onToggleFavorite,
  });

  final Translation translation;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final VoidCallback onToggleFavorite;

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

    final timeString = _formatTime(translation.createdAt);

    return Dismissible(
      key: ValueKey(translation.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: Semantics(
        label: '${translation.type} translation: '
            '${translation.sourceText} to ${translation.translatedText}, '
            '$timeString',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.listItemPadding),
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.stone900 : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.stone700 : AppColors.stone200,
              ),
            ),
            child: Row(
              children: [
                // Type icon.
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.stone800 : iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData, size: 20, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translation.sourceText,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        translation.translatedText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.stone500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeString,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.stone400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bookmark.
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    translation.isFavorite
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: translation.isFavorite
                        ? AppColors.terracotta
                        : AppColors.stone400,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
