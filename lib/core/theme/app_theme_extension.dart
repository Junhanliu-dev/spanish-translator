import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Custom theme tokens beyond Material 3's [ColorScheme].
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.micButtonColor,
    required this.micButtonGlowColor,
    required this.sourcePanelColor,
    required this.translationPanelColor,
    required this.languageBadgeSpanishColor,
    required this.languageBadgeBasqueColor,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color micButtonColor;
  final Color micButtonGlowColor;
  final Color sourcePanelColor;
  final Color translationPanelColor;
  final Color languageBadgeSpanishColor;
  final Color languageBadgeBasqueColor;
  final Color shimmerBase;
  final Color shimmerHighlight;

  /// Light theme variant.
  static const AppThemeExtension light = AppThemeExtension(
    micButtonColor: AppColors.terracotta,
    micButtonGlowColor: Color(0x4DC4602A),
    sourcePanelColor: AppColors.bilbaoBlueFaint,
    translationPanelColor: AppColors.white,
    languageBadgeSpanishColor: AppColors.spanishBadge,
    languageBadgeBasqueColor: AppColors.basqueBadge,
    shimmerBase: AppColors.stone200,
    shimmerHighlight: AppColors.white,
  );

  /// Dark theme variant.
  static const AppThemeExtension dark = AppThemeExtension(
    micButtonColor: AppColors.terracottaLight,
    micButtonGlowColor: Color(0x4DE07848),
    sourcePanelColor: AppColors.bilbaoBlueDark,
    translationPanelColor: AppColors.stone900,
    languageBadgeSpanishColor: Color(0xFFEF9A9A),
    languageBadgeBasqueColor: Color(0xFF81C784),
    shimmerBase: AppColors.stone800,
    shimmerHighlight: AppColors.stone700,
  );

  @override
  AppThemeExtension copyWith({
    Color? micButtonColor,
    Color? micButtonGlowColor,
    Color? sourcePanelColor,
    Color? translationPanelColor,
    Color? languageBadgeSpanishColor,
    Color? languageBadgeBasqueColor,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) =>
      AppThemeExtension(
        micButtonColor: micButtonColor ?? this.micButtonColor,
        micButtonGlowColor: micButtonGlowColor ?? this.micButtonGlowColor,
        sourcePanelColor: sourcePanelColor ?? this.sourcePanelColor,
        translationPanelColor:
            translationPanelColor ?? this.translationPanelColor,
        languageBadgeSpanishColor:
            languageBadgeSpanishColor ?? this.languageBadgeSpanishColor,
        languageBadgeBasqueColor:
            languageBadgeBasqueColor ?? this.languageBadgeBasqueColor,
        shimmerBase: shimmerBase ?? this.shimmerBase,
        shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      );

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      micButtonColor: Color.lerp(micButtonColor, other.micButtonColor, t)!,
      micButtonGlowColor:
          Color.lerp(micButtonGlowColor, other.micButtonGlowColor, t)!,
      sourcePanelColor:
          Color.lerp(sourcePanelColor, other.sourcePanelColor, t)!,
      translationPanelColor:
          Color.lerp(translationPanelColor, other.translationPanelColor, t)!,
      languageBadgeSpanishColor: Color.lerp(
        languageBadgeSpanishColor,
        other.languageBadgeSpanishColor,
        t,
      )!,
      languageBadgeBasqueColor: Color.lerp(
        languageBadgeBasqueColor,
        other.languageBadgeBasqueColor,
        t,
      )!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}
