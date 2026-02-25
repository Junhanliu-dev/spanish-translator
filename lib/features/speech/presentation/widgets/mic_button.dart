import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_shadow.dart';
import '../../../../shared/models/speech_state.dart';
import 'pulse_ring_animation.dart';

/// The signature microphone button for the speech translation screen.
///
/// An 88dp terracotta circle with contextual animations: idle glow,
/// recording pulse rings, processing spinner, and error shake.
class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.state,
    required this.onTap,
  });

  /// Current speech state determines the button appearance.
  final SpeechState state;

  /// Called when the user taps the button (start/stop recording).
  final VoidCallback onTap;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == SpeechState.error &&
        oldWidget.state != SpeechState.error) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    setState(() => _scale = 0.95);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
  }

  void _handleTapCancel() {
    setState(() => _scale = 1.0);
  }

  void _handleTap() {
    if (widget.state == SpeechState.processing) return;

    if (widget.state == SpeechState.idle ||
        widget.state == SpeechState.success) {
      HapticFeedback.mediumImpact();
    } else if (widget.state == SpeechState.recording) {
      HapticFeedback.lightImpact();
    }

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state == SpeechState.recording;
    final isProcessing = widget.state == SpeechState.processing;
    final isError = widget.state == SpeechState.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 176,
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse rings (behind button).
              PulseRingAnimation(
                size: 88,
                isAnimating: isRecording,
              ),
              // Shake wrapper.
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      isError ? _shakeAnimation.value : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: AnimatedScale(
                  scale: _scale,
                  duration: AppDurations.micro,
                  curve: Curves.easeOut,
                  child: GestureDetector(
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    onTap: _handleTap,
                    child: Semantics(
                      label: _semanticsLabel,
                      button: true,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.terracotta.withValues(
                            alpha: isProcessing ? 0.8 : 1.0,
                          ),
                          boxShadow: isRecording
                              ? AppShadow.micButtonRecording
                              : AppShadow.micButtonIdle,
                        ),
                        child: Center(child: _buildIcon()),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _statusLabel,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isRecording
                ? AppColors.terracotta
                : isError
                    ? AppColors.error
                    : AppColors.stone500,
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    if (widget.state == SpeechState.processing) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 3,
        ),
      );
    }
    return const Icon(
      Icons.mic,
      size: 36,
      color: AppColors.white,
    );
  }

  String get _statusLabel {
    switch (widget.state) {
      case SpeechState.idle:
      case SpeechState.success:
        return 'Tap to speak';
      case SpeechState.recording:
        return 'Tap to stop';
      case SpeechState.processing:
        return 'Translating...';
      case SpeechState.error:
        return 'Translation failed';
    }
  }

  String get _semanticsLabel {
    switch (widget.state) {
      case SpeechState.idle:
      case SpeechState.success:
        return 'Start recording. Double tap to activate.';
      case SpeechState.recording:
        return 'Stop recording. Double tap to stop.';
      case SpeechState.processing:
        return 'Translating your speech. Please wait.';
      case SpeechState.error:
        return 'Translation failed. Double tap to try again.';
    }
  }
}
