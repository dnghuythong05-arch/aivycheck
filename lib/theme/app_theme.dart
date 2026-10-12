import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiVieTheme {
  static const background = Color(0xFFF7F8FA);
  static const primary = Color(0xFF2563EB);
  static const text = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);

  static const double contentWidth = 1120;

  static TextStyle _type(
    double size,
    FontWeight weight, {
    double height = 1.4,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: text,
      height: height,
      letterSpacing: 0,
    );
  }

  static WidgetStateProperty<Color?> _overlay(Color color) {
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.transparent;
      }

      if (states.contains(WidgetState.focused)) {
        return color.withValues(alpha: 0.10);
      }

      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: 0.06);
      }

      if (states.contains(WidgetState.hovered)) {
        return color.withValues(alpha: 0.03);
      }

      return Colors.transparent;
    });
  }

  static ButtonStyle _buttonStyle({bool filled = false}) {
    return ButtonStyle(
      textStyle: WidgetStatePropertyAll(_type(14, FontWeight.w500)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      splashFactory: NoSplash.splashFactory,
      overlayColor: _overlay(filled ? Colors.white : primary),
      animationDuration: const Duration(milliseconds: 150),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.light,
          ).copyWith(
            primary: primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: text,
            onSurfaceVariant: muted,
            outline: border,
            outlineVariant: border,
          ),
      scaffoldBackgroundColor: background,

      // Không tạo vòng màu lan rộng khi nhấn.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,

      highlightColor: primary.withValues(alpha: 0.04),
      hoverColor: primary.withValues(alpha: 0.03),
      focusColor: primary.withValues(alpha: 0.10),
    );

    final typography = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: text, displayColor: text);

    return base.copyWith(
      textTheme: typography.copyWith(
        headlineSmall: _type(24, FontWeight.w600, height: 1.3),
        titleLarge: _type(20, FontWeight.w600, height: 1.3),
        titleMedium: _type(16, FontWeight.w500, height: 1.3),
        bodyLarge: _type(15, FontWeight.w400, height: 1.5),
        bodyMedium: _type(14, FontWeight.w400, height: 1.5),
        bodySmall: _type(12, FontWeight.w400),
        labelLarge: _type(14, FontWeight.w500),
        labelMedium: _type(12, FontWeight.w500),
        labelSmall: _type(11, FontWeight.w400),
      ),
      primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _type(20, FontWeight.w600, height: 1.3),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(filled: true),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle()),
      textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          overlayColor: _overlay(primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(fontSize: 14, color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB91C1C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB91C1C), width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }
}
