import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Source/target language direction toggle.
///
/// Shows the current translation direction (e.g., "English -> Spanish")
/// with a swap button that rotates on tap.
class DirectionToggle extends StatelessWidget {
  const DirectionToggle({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.isReversed,
    required this.onToggle,
  });

  /// Display name of the source language.
  final String sourceLanguage;

  /// Display name of the target language.
  final String targetLanguage;

  /// Whether the direction is currently reversed.
  final bool isReversed;

  /// Called when the user taps to swap direction.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Source language label.
          _LanguageLabel(name: sourceLanguage),
          const SizedBox(width: AppSpacing.md),
          // Swap button.
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle();
            },
            child: Semantics(
              label: 'Swap translation direction',
              button: true,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.stone200,
                  shape: BoxShape.circle,
                ),
                child: AnimatedRotation(
                  turns: isReversed ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.swap_horiz,
                    size: 20,
                    color: AppColors.stone600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Target language label.
          _LanguageLabel(name: targetLanguage),
        ],
      ),
    );
  }
}

class _LanguageLabel extends StatelessWidget {
  const _LanguageLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.stone700,
      ),
    );
  }
}
