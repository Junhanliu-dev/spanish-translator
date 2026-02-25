import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Horizontal scrollable row of filter chips for the history screen.
///
/// Supports All, Speech, Photo, and Text filters.
class HistoryFilterChips extends StatelessWidget {
  const HistoryFilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  /// Current active filter: null = All, 'speech', 'photo', 'text'.
  final String? activeFilter;

  /// Called when a chip is tapped.
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            icon: null,
            isSelected: activeFilter == null,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: 'Speech',
            icon: Icons.mic,
            isSelected: activeFilter == 'speech',
            onTap: () => onFilterChanged('speech'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: 'Photo',
            icon: Icons.camera_alt,
            isSelected: activeFilter == 'photo',
            onTap: () => onFilterChanged('photo'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: 'Text',
            icon: Icons.text_fields,
            isSelected: activeFilter == 'text',
            onTap: () => onFilterChanged('text'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppSpacing.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.terracotta
              : (isDark ? AppColors.stone800 : AppColors.stone100),
          borderRadius: BorderRadius.circular(999),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.stone700 : AppColors.stone300,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.stone600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.stone600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
