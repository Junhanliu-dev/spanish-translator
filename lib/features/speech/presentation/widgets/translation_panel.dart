import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extension.dart';

/// Displays the translated text with TTS playback and action buttons.
///
/// Slides up and fades in when a translation result arrives (250ms,
/// easeOutCubic).
class TranslationPanel extends StatelessWidget {
  const TranslationPanel({
    super.key,
    this.text,
    this.targetLanguage,
    this.isTTSPlaying = false,
    this.isSaved = false,
    this.onPlayTTS,
    this.onStopTTS,
    this.onCopy,
    this.onSave,
    this.isLoading = false,
  });

  /// The translated text. Null when no translation is available.
  final String? text;

  /// Display name for the target language (e.g., "Spanish").
  final String? targetLanguage;

  /// Whether TTS audio is currently playing.
  final bool isTTSPlaying;

  /// Whether the translation has been saved to history.
  final bool isSaved;

  /// Called to start TTS playback.
  final VoidCallback? onPlayTTS;

  /// Called to stop TTS playback.
  final VoidCallback? onStopTTS;

  /// Called when the user taps copy.
  final VoidCallback? onCopy;

  /// Called when the user taps save/bookmark.
  final VoidCallback? onSave;

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
        color: ext.translationPanelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: isLoading
          ? _buildShimmer(ext)
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasText = text != null && text!.isNotEmpty;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              targetLanguage ?? 'Translation',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.stone500,
              ),
            ),
            const Spacer(),
            if (hasText)
              _TTSButton(
                isPlaying: isTTSPlaying,
                onPlay: onPlayTTS,
                onStop: onStopTTS,
              ),
          ],
        ),
        if (hasText) ...[
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            text!,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onSave,
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 24,
                ),
                color: isSaved ? AppColors.terracotta : AppColors.stone400,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                tooltip: isSaved ? 'Saved' : 'Save to history',
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy, size: 20),
                color: AppColors.stone400,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                tooltip: 'Copy translation',
              ),
            ],
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Translation appears here',
              style: const TextStyle(fontFamily: 'Nunito', 
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.stone400,
              ),
            ),
          ),
      ],
    );

    if (hasText) {
      content = content
          .animate()
          .slideY(
            begin: 0.15,
            end: 0,
            duration: 250.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: 250.ms);
    }

    return content;
  }

  Widget _buildShimmer(AppThemeExtension ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 14,
          decoration: BoxDecoration(
            color: ext.shimmerBase,
            borderRadius: BorderRadius.circular(4),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: ext.shimmerHighlight),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 18,
          decoration: BoxDecoration(
            color: ext.shimmerBase,
            borderRadius: BorderRadius.circular(4),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: ext.shimmerHighlight),
        const SizedBox(height: 8),
        Container(
          width: 250,
          height: 18,
          decoration: BoxDecoration(
            color: ext.shimmerBase,
            borderRadius: BorderRadius.circular(4),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: ext.shimmerHighlight),
        const SizedBox(height: 8),
        Container(
          width: 150,
          height: 18,
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

class _TTSButton extends StatelessWidget {
  const _TTSButton({
    required this.isPlaying,
    this.onPlay,
    this.onStop,
  });

  final bool isPlaying;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    Widget icon = Icon(
      isPlaying ? Icons.stop_circle : Icons.volume_up,
      size: 24,
      color: AppColors.stone600,
    );

    if (isPlaying) {
      icon = icon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.2, 1.2),
            duration: 800.ms,
          );
    }

    return Semantics(
      label: isPlaying ? 'Stop translation audio' : 'Play translation audio',
      button: true,
      child: IconButton(
        onPressed: isPlaying ? onStop : onPlay,
        icon: icon,
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        tooltip: isPlaying ? 'Stop audio' : 'Play audio',
      ),
    );
  }
}
