import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_theme_extension.dart';

/// Provides [ThemeData] for light and dark modes.
class AppTheme {
  AppTheme._();

  /// Light theme.
  static final ThemeData light = _buildLightTheme();

  /// Dark theme.
  static final ThemeData dark = _buildDarkTheme();

  static ThemeData _buildLightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.terracotta,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.terracottaFaint,
          onPrimaryContainer: AppColors.terracottaDark,
          secondary: AppColors.bilbaoBlue,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.bilbaoBlueFaint,
          onSecondaryContainer: AppColors.bilbaoBlueDark,
          tertiary: AppColors.saffron,
          onTertiary: AppColors.white,
          tertiaryContainer: AppColors.saffronFaint,
          onTertiaryContainer: AppColors.saffronDark,
          error: AppColors.error,
          onError: AppColors.white,
          errorContainer: AppColors.errorLight,
          onErrorContainer: AppColors.error,
          surface: AppColors.stone50,
          onSurface: AppColors.stone900,
          surfaceContainerHighest: AppColors.stone100,
          onSurfaceVariant: AppColors.stone600,
          outline: AppColors.stone300,
          outlineVariant: AppColors.stone200,
          shadow: AppColors.stone950,
          scrim: AppColors.stone950,
          inverseSurface: AppColors.stone900,
          onInverseSurface: AppColors.stone100,
          inversePrimary: AppColors.terracottaLight,
        ),
        textTheme: _buildTextTheme(Brightness.light),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bilbaoBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: -0.3,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.stone50,
          indicatorColor: AppColors.terracottaFaint,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: AppColors.terracotta,
                size: 24,
              );
            }
            return const IconThemeData(
              color: AppColors.stone500,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.terracotta,
              );
            }
            return const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.stone500,
            );
          }),
          elevation: 8,
          shadowColor: AppColors.stone950,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.stone200),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracotta,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.terracotta,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.terracotta, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.stone100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.stone300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.stone300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.terracotta, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5),
          ),
          hintStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            color: AppColors.stone500,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.stone200,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.stone900,
          contentTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            color: AppColors.stone100,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        extensions: const [AppThemeExtension.light],
      );

  static ThemeData _buildDarkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.terracottaLight,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.terracottaDark,
          onPrimaryContainer: AppColors.terracottaFaint,
          secondary: AppColors.bilbaoBlueLight,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.bilbaoBlueDark,
          onSecondaryContainer: AppColors.bilbaoBlueFaint,
          tertiary: AppColors.saffron,
          onTertiary: AppColors.stone950,
          tertiaryContainer: Color(0xFF3D2E00),
          onTertiaryContainer: AppColors.saffronLight,
          error: Color(0xFFEF9A9A),
          onError: Color(0xFF7F0000),
          errorContainer: Color(0xFF7F0000),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: AppColors.stone900,
          onSurface: AppColors.stone100,
          surfaceContainerHighest: AppColors.stone800,
          onSurfaceVariant: AppColors.stone400,
          outline: AppColors.stone700,
          outlineVariant: AppColors.stone800,
          shadow: AppColors.stone950,
          scrim: AppColors.stone950,
          inverseSurface: AppColors.stone100,
          onInverseSurface: AppColors.stone900,
          inversePrimary: AppColors.terracotta,
        ),
        textTheme: _buildTextTheme(Brightness.dark),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bilbaoBlueDark,
          foregroundColor: AppColors.stone100,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.stone900,
          indicatorColor: AppColors.terracottaDark,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: AppColors.terracottaLight,
                size: 24,
              );
            }
            return const IconThemeData(
              color: AppColors.stone500,
              size: 24,
            );
          }),
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          color: AppColors.stone900,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.stone700),
          ),
        ),
        extensions: const [AppThemeExtension.dark],
      );

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textPrimary = brightness == Brightness.light
        ? AppColors.stone900
        : AppColors.stone100;
    final Color textSecondary = brightness == Brightness.light
        ? AppColors.stone600
        : AppColors.stone400;

    return TextTheme(
      // Display -- Large hero text (onboarding, empty states)
      displayLarge: AppFonts.nunito(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -1.5,
        height: 1.12,
      ),
      displayMedium: AppFonts.nunito(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.16,
      ),
      displaySmall: AppFonts.nunito(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0,
        height: 1.22,
      ),
      // Headline -- Screen titles, section headers
      headlineLarge: AppFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineMedium: AppFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
        height: 1.29,
      ),
      headlineSmall: AppFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.33,
      ),
      // Title -- Card titles, list item primaries, dialog titles
      titleLarge: AppFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.27,
      ),
      titleMedium: AppFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      titleSmall: AppFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      // Body -- Main readable text
      bodyLarge: AppFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.15,
        height: 1.6,
      ),
      bodyMedium: AppFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.25,
        height: 1.57,
      ),
      bodySmall: AppFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.4,
        height: 1.5,
      ),
      // Label -- Buttons, badges, captions, tab labels
      labelLarge: AppFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: AppFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: AppFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }
}
