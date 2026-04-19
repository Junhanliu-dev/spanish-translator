import 'package:flutter/material.dart';

/// Local font helpers backed by bundled assets.
///
/// Drop-in replacement for the prior `GoogleFonts` call-sites: same kwargs,
/// but no runtime network fetch and no extra dependency.
class AppFonts {
  AppFonts._();

  static const String nunitoFamily = 'Nunito';
  static const String dmSansFamily = 'DMSans';

  static TextStyle nunito({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    Paint? background,
    Paint? foreground,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextBaseline? textBaseline,
    Locale? locale,
    String? debugLabel,
  }) =>
      TextStyle(
        fontFamily: nunitoFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height,
        fontStyle: fontStyle,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        background: background,
        foreground: foreground,
        shadows: shadows,
        fontFeatures: fontFeatures,
        fontVariations: fontVariations,
        textBaseline: textBaseline,
        locale: locale,
        debugLabel: debugLabel,
      );

  static TextStyle dmSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    Paint? background,
    Paint? foreground,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextBaseline? textBaseline,
    Locale? locale,
    String? debugLabel,
  }) =>
      TextStyle(
        fontFamily: dmSansFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height,
        fontStyle: fontStyle,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        background: background,
        foreground: foreground,
        shadows: shadows,
        fontFeatures: fontFeatures,
        fontVariations: fontVariations,
        textBaseline: textBaseline,
        locale: locale,
        debugLabel: debugLabel,
      );
}
