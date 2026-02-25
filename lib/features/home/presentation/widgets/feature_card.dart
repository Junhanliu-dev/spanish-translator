import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadow.dart';

/// A feature card displayed on the home screen (Speech, Photo, Text).
///
/// Shows an icon, title, subtitle, and a trailing chevron.
/// Supports disabled state when permission is missing.
class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isEnabled = true,
    this.disabledSubtitle,
  });

  /// The icon to display in the colored container.
  final IconData icon;

  /// Card title (e.g., "Speech Translation").
  final String title;

  /// Card subtitle (e.g., "Speak and hear it").
  final String subtitle;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Whether the feature is enabled (permission granted).
  final bool isEnabled;

  /// Subtitle shown when disabled (e.g., "Tap to enable microphone").
  final String? disabledSubtitle;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.stone900 : AppColors.white;
    final pressedBg = isDark ? AppColors.stone800 : AppColors.stone100;
    final borderColor = isDark ? AppColors.stone700 : AppColors.stone200;

    final iconContainerBg = widget.isEnabled
        ? theme.colorScheme.primaryContainer
        : (isDark ? AppColors.stone800 : AppColors.stone200);
    final iconColor = widget.isEnabled
        ? theme.colorScheme.primary
        : AppColors.stone400;
    final titleColor = widget.isEnabled
        ? theme.colorScheme.onSurface
        : AppColors.stone400;
    final subtitleText = widget.isEnabled
        ? widget.subtitle
        : (widget.disabledSubtitle ?? widget.subtitle);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 100,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: _pressed ? pressedBg : bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: AppShadow.sm,
          ),
          child: Row(
            children: [
              // Icon container.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconContainerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(widget.icon, size: 28, color: iconColor),
                    ),
                    if (!widget.isEnabled)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.stone600,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 10,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title and subtitle.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.stone500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.isEnabled)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.stone400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
