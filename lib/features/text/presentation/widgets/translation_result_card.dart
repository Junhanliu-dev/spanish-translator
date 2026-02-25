import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/openai_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Card displaying the text translation result with collapsible Context
/// and Pronunciation sections.
///
/// Enters with a slide-up + fade-in animation (250ms, easeOutCubic).
class TranslationResultCard extends StatelessWidget {
  const TranslationResultCard({
    super.key,
    required this.result,
    this.sourceText,
    this.detectedLanguage,
    this.contextExpanded = false,
    this.pronunciationExpanded = false,
    this.isFavorite = false,
    this.onToggleContext,
    this.onTogglePronunciation,
    this.onCopyTranslation,
    this.onCopyAll,
    this.onToggleFavorite,
  });

  /// The translation response data.
  final TranslationResponse result;

  /// The original input text.
  final String? sourceText;

  /// The detected source language.
  final String? detectedLanguage;

  /// Whether the context section is expanded.
  final bool contextExpanded;

  /// Whether the pronunciation section is expanded.
  final bool pronunciationExpanded;

  /// Whether this translation is bookmarked.
  final bool isFavorite;

  /// Called to toggle context expansion.
  final VoidCallback? onToggleContext;

  /// Called to toggle pronunciation expansion.
  final VoidCallback? onTogglePronunciation;

  /// Called to copy the translation text.
  final VoidCallback? onCopyTranslation;

  /// Called to copy all sections.
  final VoidCallback? onCopyAll;

  /// Called to toggle bookmark.
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121A1410),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x0C1A1410),
            offset: Offset(0, 4),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source section.
          if (sourceText != null && sourceText!.isNotEmpty) ...[
            if (detectedLanguage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Detected: ${detectedLanguage!.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: AppColors.stone500,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sourceText!,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: AppColors.stone600,
                      height: 1.57,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1),
            ),
          ],
          // Translation section.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Translation',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: AppColors.stone500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      result.translatedText,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCopyTranslation,
                icon: const Icon(Icons.content_copy, size: 20),
                color: AppColors.terracotta,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                tooltip: 'Copy translation',
              ),
            ],
          ),
          // Collapsible: Context & Explanation.
          if (result.context != null && result.context!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CollapsibleSection(
              title: 'Context & Explanation',
              isExpanded: contextExpanded,
              onToggle: onToggleContext,
              child: Text(
                result.context!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.stone700,
                  height: 1.6,
                ),
              ),
            ),
          ],
          // Collapsible: Pronunciation Guide.
          if (result.pronunciation != null &&
              result.pronunciation!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CollapsibleSection(
              title: 'Pronunciation Guide',
              isExpanded: pronunciationExpanded,
              onToggle: onTogglePronunciation,
              child: Text(
                result.pronunciation!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.stone500,
                  letterSpacing: 0.8,
                  height: 1.6,
                ),
              ),
            ),
          ],
          // Bottom actions.
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onCopyAll,
                icon: const Icon(Icons.copy_all, size: 20),
                color: AppColors.stone400,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                tooltip: 'Copy all',
              ),
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  size: 24,
                ),
                color: isFavorite ? AppColors.terracotta : AppColors.stone400,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                tooltip: isFavorite ? 'Remove bookmark' : 'Bookmark',
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 250.ms);
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.isExpanded,
    this.onToggle,
    required this.child,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row.
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Semantics(
            label: '$title, ${isExpanded ? "expanded" : "collapsed"}. '
                'Double tap to ${isExpanded ? "collapse" : "expand"}.',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      size: 20,
                      color: AppColors.stone500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.stone500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expandable content.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    bottom: 8,
                  ),
                  child: child,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
