import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';

/// Animated concentric pulse rings for the microphone recording state.
///
/// Two rings expand outward and fade, staggered by 400ms, creating
/// a breathing ripple effect.
class PulseRingAnimation extends StatefulWidget {
  const PulseRingAnimation({
    super.key,
    this.size = 88.0,
    this.isAnimating = false,
  });

  /// Diameter of the base circle that the rings originate from.
  final double size;

  /// Whether the animation is currently running.
  final bool isAnimating;

  @override
  State<PulseRingAnimation> createState() => _PulseRingAnimationState();
}

class _PulseRingAnimationState extends State<PulseRingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controllerA;
  late final AnimationController _controllerB;

  @override
  void initState() {
    super.initState();

    _controllerA = AnimationController(
      vsync: this,
      duration: AppDurations.pulse,
    );
    _controllerB = AnimationController(
      vsync: this,
      duration: AppDurations.pulse,
    );

    if (widget.isAnimating) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(PulseRingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimation();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _controllerA.repeat();
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted && widget.isAnimating) {
        _controllerB.repeat();
      }
    });
  }

  void _stopAnimation() {
    _controllerA.stop();
    _controllerA.reset();
    _controllerB.stop();
    _controllerB.reset();
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) {
      return SizedBox(
        width: widget.size * 2,
        height: widget.size * 2,
      );
    }

    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulseRing(
            controller: _controllerA,
            baseSize: widget.size,
            maxScale: 1.5,
            startOpacity: 0.4,
          ),
          _PulseRing(
            controller: _controllerB,
            baseSize: widget.size,
            maxScale: 1.8,
            startOpacity: 0.25,
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends AnimatedWidget {
  const _PulseRing({
    required AnimationController controller,
    required this.baseSize,
    required this.maxScale,
    required this.startOpacity,
  }) : super(listenable: controller);

  final double baseSize;
  final double maxScale;
  final double startOpacity;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as AnimationController;
    final scale = 1.0 + (maxScale - 1.0) * Curves.easeOut.transform(animation.value);
    final opacity = startOpacity * (1.0 - Curves.easeOut.transform(animation.value));

    return Container(
      width: baseSize * scale,
      height: baseSize * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.terracotta.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}
