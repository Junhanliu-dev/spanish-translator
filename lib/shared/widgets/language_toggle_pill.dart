import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../models/target_language.dart';

/// Two-segment pill toggle for switching between Spanish (ES) and Basque (EU).
///
/// 80dp wide x 32dp tall, fully rounded, with animated segment slide.
class LanguageTogglePill extends StatelessWidget {
  const LanguageTogglePill({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// The currently selected target language.
  final TargetLanguage selected;

  /// Called when the user taps a segment.
  final ValueChanged<TargetLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.light
        ? AppColors.stone200
        : AppColors.stone800;
    final unselectedTextColor = brightness == Brightness.light
        ? AppColors.stone600
        : AppColors.stone400;

    return Semantics(
      label: 'Target language: ${selected.displayName}',
      hint: selected == TargetLanguage.spanish
          ? 'Double tap to switch to Basque'
          : 'Double tap to switch to Spanish',
      toggled: true,
      child: Container(
        width: 80,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            // Animated selected indicator.
            AnimatedAlign(
              duration: AppDurations.fast,
              curve: Curves.easeInOut,
              alignment: selected == TargetLanguage.spanish
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: 37,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            // Labels row.
            Row(
              children: [
                _Segment(
                  label: 'ES',
                  isSelected: selected == TargetLanguage.spanish,
                  unselectedColor: unselectedTextColor,
                  onTap: () {
                    if (selected != TargetLanguage.spanish) {
                      HapticFeedback.selectionClick();
                      onChanged(TargetLanguage.spanish);
                    }
                  },
                ),
                _Segment(
                  label: 'EU',
                  isSelected: selected == TargetLanguage.basque,
                  unselectedColor: unselectedTextColor,
                  onTap: () {
                    if (selected != TargetLanguage.basque) {
                      HapticFeedback.selectionClick();
                      onChanged(TargetLanguage.basque);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.unselectedColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isSelected ? AppColors.white : unselectedColor,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
