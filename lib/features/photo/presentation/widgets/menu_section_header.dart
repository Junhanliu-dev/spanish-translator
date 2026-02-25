import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Section header for menu translation results.
///
/// Displays the original and translated section titles in uppercase with
/// a horizontal divider below.
class MenuSectionHeader extends StatelessWidget {
  const MenuSectionHeader({
    super.key,
    required this.originalTitle,
    required this.translatedTitle,
  });

  /// The original section title (e.g., "AURREPLATOAK").
  final String originalTitle;

  /// The translated section title (e.g., "STARTERS").
  final String translatedTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${originalTitle.toUpperCase()} / ${translatedTitle.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
