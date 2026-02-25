import 'package:flutter/material.dart';

import '../../core/theme/app_durations.dart';
import '../../core/theme/app_theme_extension.dart';

/// A shimmer loading placeholder that sweeps left-to-right.
///
/// Wraps a child widget (usually a [Container] with rounded corners) and
/// applies a shimmer gradient animation over it.
class ShimmerPlaceholder extends StatefulWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  /// Width of the placeholder rectangle.
  final double width;

  /// Height of the placeholder rectangle.
  final double height;

  /// Border radius of the placeholder rectangle.
  final double borderRadius;

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [
                ext.shimmerBase,
                ext.shimmerHighlight,
                ext.shimmerBase,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A pre-built shimmer skeleton for translation cards.
class TranslationCardShimmer extends StatelessWidget {
  const TranslationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerPlaceholder(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          const ShimmerPlaceholder(width: 250, height: 14),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          const ShimmerPlaceholder(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          const ShimmerPlaceholder(width: 300, height: 16),
          const SizedBox(height: 8),
          const ShimmerPlaceholder(width: 200, height: 16),
          const SizedBox(height: 12),
          Row(
            children: const [
              ShimmerPlaceholder(width: 60, height: 24),
              SizedBox(width: 8),
              ShimmerPlaceholder(width: 60, height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
