import 'package:flutter/animation.dart';

/// Animation timing constants.
class AppDurations {
  AppDurations._();

  static const Duration instant = Duration.zero;
  static const Duration micro = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasis = Duration(milliseconds: 300);
  static const Duration deliberate = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration pulse = Duration(milliseconds: 1200);
  static const Duration shimmer = Duration(milliseconds: 1500);
}

/// Animation curve presets.
class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve spring = Curves.elasticOut;
  static const Curve emphasize = Curves.easeOutCubic;
}
