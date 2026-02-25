import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shadow definitions for the elevation system.
class AppShadow {
  AppShadow._();

  /// Level 0 -- Flat (used with borders instead).
  static const List<BoxShadow> none = [];

  /// Level 1 -- Subtle lift (cards, input fields).
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A1A1410),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x081A1410),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  /// Level 2 -- Standard card shadow.
  static const List<BoxShadow> md = [
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
  ];

  /// Level 3 -- Elevated panels, bottom sheets.
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x181A1410),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x121A1410),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  /// Level 4 -- Bottom nav, modals, overlays.
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x201A1410),
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x181A1410),
      offset: Offset(0, 16),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  /// Mic button idle glow -- terracotta inner glow.
  static List<BoxShadow> micButtonIdle = [
    BoxShadow(
      color: AppColors.terracotta.withValues(alpha: 0.3),
      offset: const Offset(0, 4),
      blurRadius: 20,
    ),
    BoxShadow(
      color: AppColors.terracotta.withValues(alpha: 0.15),
      offset: const Offset(0, 8),
      blurRadius: 40,
    ),
  ];

  /// Mic button recording glow -- intense pulse.
  static List<BoxShadow> micButtonRecording = [
    BoxShadow(
      color: AppColors.terracotta.withValues(alpha: 0.5),
      blurRadius: 30,
      spreadRadius: 8,
    ),
    BoxShadow(
      color: AppColors.terracotta.withValues(alpha: 0.25),
      blurRadius: 60,
      spreadRadius: 16,
    ),
  ];
}
