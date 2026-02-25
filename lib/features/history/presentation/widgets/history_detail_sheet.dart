import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/translation.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/language_badge.dart';

/// Bottom sheet showing the full translation detail for a history item.
class HistoryDetailSheet extends StatelessWidget {
  const HistoryDetailSheet({
    super.key,
    required this.translation,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final Translation translation;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  /// Show this sheet.
  static void show(
    BuildContext context, {
    required Translation translation,
    required VoidCallback onDelete,
    required VoidCallback onToggleFavorite,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => HistoryDetailSheet(
        translation: translation,
        onDelete: onDelete,
        onToggleFavorite: onToggleFavorite,
      ),
    );
  }

  String get _typeLabel => switch (translation.type) {
        'speech' => 'Speech Translation',
        'photo' => 'Photo Translation',
        _ => 'Text Translation',
      };

  IconData get _typeIcon => switch (translation.type) {
        'speech' => Icons.mic,
        'photo' => Icons.camera_alt,
        _ => Icons.text_fields,
      };

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag handle.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.stone300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header.
              Row(
                children: [
                  Icon(_typeIcon, color: AppColors.terracotta, size: 24),
                  const SizedBox(width: 8),
                  Text(_typeLabel, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(translation.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.stone500,
                ),
              ),

              const SizedBox(height: AppSpacing.xl2),

              // Source section.
              Text(
                'SOURCE',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.stone500,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (translation.sourceLanguage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LanguageBadge(
                    languageCode: translation.sourceLanguage,
                  ),
                ),
              SelectableText(
                translation.sourceText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.stone700,
                ),
              ),

              const Divider(height: 32),

              // Translation section.
              Text(
                'TRANSLATION',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.stone500,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                translation.translatedText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Context.
              if (translation.context != null &&
                  translation.context!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Context',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.stone500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translation.context!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.stone700,
                  ),
                ),
              ],

              // Pronunciation.
              if (translation.pronunciation != null &&
                  translation.pronunciation!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pronunciation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.stone500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translation.pronunciation!,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.stone500,
                    letterSpacing: 0.8,
                    height: 1.6,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl3),

              // Action buttons.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.content_copy,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: translation.translatedText),
                      );
                      if (context.mounted) {
                        AppSnackbar.success(context, 'Translation copied');
                      }
                    },
                  ),
                  _ActionButton(
                    icon: translation.isFavorite
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: translation.isFavorite ? 'Saved' : 'Save',
                    color: translation.isFavorite
                        ? AppColors.terracotta
                        : null,
                    onTap: onToggleFavorite,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl3),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.stone600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
