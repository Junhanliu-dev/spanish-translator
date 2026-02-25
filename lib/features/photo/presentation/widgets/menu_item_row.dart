import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/menu_item.dart';

/// A single expandable menu item row.
///
/// Collapsed: shows original name, translation snippet, and price.
/// Expanded: adds description and pronunciation guide (accordion behavior).
class MenuItemRow extends StatelessWidget {
  const MenuItemRow({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  /// The menu item data.
  final MenuItem item;

  /// Whether this item is currently expanded.
  final bool isExpanded;

  /// Called when the user taps to expand/collapse.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final expandedBg = brightness == Brightness.light
        ? AppColors.terracottaFaint
        : AppColors.terracottaDark.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isExpanded ? expandedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(AppSpacing.listItemPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: original name + price + chevron.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.originalName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.translatedName,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: AppColors.stone500,
                        ),
                        maxLines: isExpanded ? null : 1,
                        overflow:
                            isExpanded ? null : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (item.price != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    item.price!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.stone700,
                        ),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.stone400,
                  ),
                ),
              ],
            ),
            // Expanded content.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? _ExpandedContent(item: item)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        if (item.description != null && item.description!.isNotEmpty) ...[
          Text(
            'Description:',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.stone500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description!,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.stone700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (item.pronunciation != null &&
            item.pronunciation!.isNotEmpty) ...[
          Text(
            'Pronunciation:',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.stone500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.pronunciation!,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.stone500,
              letterSpacing: 0.8,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}
