import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Language detection badge showing a colored dot and language name.
///
/// Pill-shaped, 24dp tall, with language-specific color coding.
class LanguageBadge extends StatelessWidget {
  const LanguageBadge({
    super.key,
    required this.languageCode,
    this.suffix = 'detected',
  });

  /// ISO 639-1 language code (e.g., 'es', 'eu', 'en', 'zh').
  final String languageCode;

  /// Text after the language name (default: "detected").
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final config = _colorConfig(languageCode);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: config.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: config.dot.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: config.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${config.name} $suffix',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: config.dot,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _BadgeColors _colorConfig(String code) {
    return switch (code.toLowerCase()) {
      'es' => const _BadgeColors(
          dot: AppColors.spanishBadge,
          background: AppColors.spanishBadgeBg,
          name: 'Spanish',
        ),
      'eu' => const _BadgeColors(
          dot: AppColors.basqueBadge,
          background: AppColors.basqueBadgeBg,
          name: 'Basque',
        ),
      'en' => const _BadgeColors(
          dot: AppColors.englishBadge,
          background: AppColors.englishBadgeBg,
          name: 'English',
        ),
      'zh' => const _BadgeColors(
          dot: AppColors.mandarinBadge,
          background: AppColors.mandarinBadgeBg,
          name: 'Mandarin',
        ),
      _ => _BadgeColors(
          dot: AppColors.stone600,
          background: AppColors.stone200,
          name: code.toUpperCase(),
        ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.dot,
    required this.background,
    required this.name,
  });

  final Color dot;
  final Color background;
  final String name;
}
