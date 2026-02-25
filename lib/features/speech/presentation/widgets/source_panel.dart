import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extension.dart';

/// Displays the source/transcribed text in the speech translation screen.
///
/// Shows a language detection badge, the transcribed text, and a copy button.
class SourcePanel extends StatelessWidget {
  const SourcePanel({
    super.key,
    this.text,
    this.detectedLanguage,
    this.onCopy,
    this.isLoading = false,
  });

  /// The transcribed source text. Null when no recording has been processed.
  final String? text;

  /// The detected language code (e.g., 'en', 'es').
  final String? detectedLanguage;

  /// Called when the user taps the copy button.
  final VoidCallback? onCopy;

  /// Whether the panel is in a loading/shimmer state.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ext.sourcePanelColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isLoading ? _buildShimmer(ext) : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasText = text != null && text!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (detectedLanguage != null && hasText)
              _LanguageBadge(languageCode: detectedLanguage!)
                  .animate()
                  .fadeIn(duration: 200.ms),
            const Spacer(),
            if (hasText)
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy, size: 20),
                color: AppColors.stone400,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                tooltip: 'Copy source text',
              ),
          ],
        ),
        if (hasText) ...[
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            text!,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.stone700,
              height: 1.6,
            ),
          ).animate().fadeIn(duration: 200.ms),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Your words appear here',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.stone400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer(AppThemeExtension ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 20,
          decoration: BoxDecoration(
            color: ext.shimmerBase,
            borderRadius: BorderRadius.circular(4),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: ext.shimmerHighlight),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: ext.shimmerBase,
            borderRadius: BorderRadius.circular(4),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: ext.shimmerHighlight),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 14,
          decoration: BoxDecoration(
            color: ext.shimmerBase,
            borderRadius: BorderRadius.circular(4),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: ext.shimmerHighlight),
      ],
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = _badgeData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) get _badgeData {
    switch (languageCode) {
      case 'es':
      case 'spanish':
        return (AppColors.spanishBadge, AppColors.spanishBadgeBg, 'ES DETECTED');
      case 'eu':
      case 'basque':
        return (AppColors.basqueBadge, AppColors.basqueBadgeBg, 'EU DETECTED');
      case 'en':
      case 'english':
        return (AppColors.englishBadge, AppColors.englishBadgeBg, 'EN DETECTED');
      case 'zh':
      case 'mandarin':
        return (AppColors.mandarinBadge, AppColors.mandarinBadgeBg, 'ZH DETECTED');
      default:
        return (
          AppColors.stone600,
          AppColors.stone100,
          '${languageCode.toUpperCase()} DETECTED'
        );
    }
  }
}
