import 'package:flutter/cupertino.dart'
    show CupertinoThemeData, CupertinoTextThemeData;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AiVieColors extends ThemeExtension<AiVieColors> {
  final Color background;
  final Color surface;
  final Color surfaceTint;
  final Color primary;
  final Color primarySoft;
  final Color text;
  final Color muted;
  final Color border;
  final Color borderStrong;
  final Color historyBorder;
  final Color success;
  final Color warning;
  final Color error;
  final Color errorBorder;
  final Color purpleSoft;
  final Color purpleBorder;

  const AiVieColors({
    required this.background,
    required this.surface,
    required this.surfaceTint,
    required this.primary,
    required this.primarySoft,
    required this.text,
    required this.muted,
    required this.border,
    required this.borderStrong,
    required this.historyBorder,
    required this.success,
    required this.warning,
    required this.error,
    required this.errorBorder,
    required this.purpleSoft,
    required this.purpleBorder,
  });

  static const light = AiVieColors(
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFF3F4F6),
    primary: Color(0xFF2563EB),
    primarySoft: Color(0xFFEAF2FF),
    text: Color(0xFF1F2937),
    muted: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    borderStrong: Color(0xFFD1D5DB),
    historyBorder: Color(0x40000000),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    error: Color(0xFFB91C1C),
    errorBorder: Color(0xFFFECACA),
    purpleSoft: Color(0xFFF5F3FF),
    purpleBorder: Color(0xFFC4B5FD),
  );

  static const dark = AiVieColors(
    background: Color(0xFF111827),
    surface: Color(0xFF1B2433),
    surfaceTint: Color(0xFF263244),
    primary: Color(0xFF93B4FF),
    primarySoft: Color(0xFF263B61),
    text: Color(0xFFF3F4F6),
    muted: Color(0xFFB5BFCE),
    border: Color(0xFF354154),
    borderStrong: Color(0xFF526078),
    historyBorder: Color(0x66FFFFFF),
    success: Color(0xFF86EFAC),
    warning: Color(0xFFF6BE75),
    error: Color(0xFFFCA5A5),
    errorBorder: Color(0xFF854545),
    purpleSoft: Color(0xFF302747),
    purpleBorder: Color(0xFF7962A6),
  );

  @override
  AiVieColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceTint,
    Color? primary,
    Color? primarySoft,
    Color? text,
    Color? muted,
    Color? border,
    Color? borderStrong,
    Color? historyBorder,
    Color? success,
    Color? warning,
    Color? error,
    Color? errorBorder,
    Color? purpleSoft,
    Color? purpleBorder,
  }) {
    return AiVieColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      historyBorder: historyBorder ?? this.historyBorder,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      errorBorder: errorBorder ?? this.errorBorder,
      purpleSoft: purpleSoft ?? this.purpleSoft,
      purpleBorder: purpleBorder ?? this.purpleBorder,
    );
  }

  @override
  AiVieColors lerp(covariant AiVieColors? other, double t) {
    if (other == null) return this;

    return AiVieColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      historyBorder: Color.lerp(historyBorder, other.historyBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      purpleSoft: Color.lerp(purpleSoft, other.purpleSoft, t)!,
      purpleBorder: Color.lerp(purpleBorder, other.purpleBorder, t)!,
    );
  }
}

class AiVieTheme {
  static const background = Color(0xFFF7F8FA);
  static const primary = Color(0xFF2563EB);
  static const text = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const action = Color(0xFF2563EB);
  static const double contentWidth = 1120;

  static AiVieColors of(BuildContext context) {
    final theme = Theme.of(context);

    return theme.extension<AiVieColors>() ??
        (theme.brightness == Brightness.dark
            ? AiVieColors.dark
            : AiVieColors.light);
  }

  static TextStyle secondary(BuildContext context, {double? fontSize}) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: of(context).muted,
    );
  }

  static ThemeData get light => _build(Brightness.light, AiVieColors.light);

  static ThemeData get dark => _build(Brightness.dark, AiVieColors.dark);

  static ThemeData _build(Brightness brightness, AiVieColors colors) {
    final dark = brightness == Brightness.dark;
    final onPrimary = dark ? colors.background : Colors.white;

    TextStyle type(double size, FontWeight weight, {double height = 1.4}) {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: colors.text,
        height: height,
        letterSpacing: 0,
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.border),
    );

    final scheme =
        ColorScheme.fromSeed(
          seedColor: action,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: onPrimary,
          primaryContainer: colors.primarySoft,
          onPrimaryContainer: colors.text,
          secondary: colors.primary,
          onSecondary: onPrimary,
          secondaryContainer: colors.primarySoft,
          onSecondaryContainer: colors.text,
          surface: colors.surface,
          onSurface: colors.text,
          onSurfaceVariant: colors.muted,
          surfaceDim: colors.background,
          surfaceBright: colors.surface,
          surfaceContainerLowest: colors.surface,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: colors.surface,
          surfaceContainerHighest: colors.surfaceTint,
          surfaceTint: Colors.transparent,
          outline: colors.borderStrong,
          outlineVariant: colors.border,
          error: colors.error,
          onError: dark ? colors.background : Colors.white,
          errorContainer: colors.errorBorder,
          onErrorContainer: colors.text,
          inverseSurface: colors.text,
          onInverseSurface: colors.background,
        );

    Color overlay(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.transparent;
      }

      final alpha = states.contains(WidgetState.pressed)
          ? 0.12
          : states.contains(WidgetState.focused)
          ? 0.10
          : states.contains(WidgetState.hovered)
          ? 0.06
          : 0.0;

      return colors.primary.withValues(alpha: alpha);
    }

    ButtonStyle button({bool filled = false}) {
      return ButtonStyle(
        textStyle: WidgetStatePropertyAll(type(14, FontWeight.w500)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        splashFactory: NoSplash.splashFactory,
        backgroundColor: filled
            ? WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return colors.text.withValues(alpha: 0.12);
                }

                return action;
              })
            : null,
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.muted;
          }

          return filled ? Colors.white : colors.primary;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }

          final alpha = states.contains(WidgetState.focused)
              ? 0.10
              : states.contains(WidgetState.pressed)
              ? 0.06
              : states.contains(WidgetState.hovered)
              ? 0.03
              : 0.0;

          return (filled ? Colors.white : colors.primary).withValues(
            alpha: alpha,
          );
        }),
        animationDuration: const Duration(milliseconds: 150),
      );
    }

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: type(14, FontWeight.w500).copyWith(color: colors.muted),
      hintStyle: type(14, FontWeight.w400).copyWith(color: colors.muted),
      helperStyle: type(12, FontWeight.w400).copyWith(color: colors.muted),
      errorStyle: type(12, FontWeight.w600).copyWith(color: colors.error),
      prefixIconColor: colors.muted,
      suffixIconColor: colors.muted,
      border: inputBorder(colors.border),
      enabledBorder: inputBorder(colors.border),
      focusedBorder: inputBorder(colors.primary, 2),
      errorBorder: inputBorder(colors.error),
      focusedErrorBorder: inputBorder(colors.error, 2),
    );

    final dateForeground = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return colors.muted.withValues(alpha: 0.45);
      }

      return states.contains(WidgetState.selected) ? onPrimary : colors.text;
    });

    final dateBackground = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.transparent;
      }

      return states.contains(WidgetState.selected)
          ? colors.primary
          : Colors.transparent;
    });

    final dateOverlay = WidgetStateProperty.resolveWith<Color?>(overlay);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [colors],
      scaffoldBackgroundColor: colors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: colors.primary.withValues(alpha: 0.04),
      hoverColor: colors.primary.withValues(alpha: 0.03),
      focusColor: colors.primary.withValues(alpha: 0.10),
      applyElevationOverlayColor: false,
    );

    return base.copyWith(
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colors.primary,
        scaffoldBackgroundColor: colors.background,
        barBackgroundColor: colors.surface,
        textTheme: CupertinoTextThemeData(
          textStyle: type(14, FontWeight.w500),
          pickerTextStyle: type(27, FontWeight.w500),
          dateTimePickerTextStyle: type(22, FontWeight.w500),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: colors.text, displayColor: colors.text)
          .copyWith(
            displayLarge: type(57, FontWeight.w600, height: 1.2),
            displayMedium: type(45, FontWeight.w600, height: 1.2),
            displaySmall: type(36, FontWeight.w600, height: 1.2),
            headlineLarge: type(32, FontWeight.w600, height: 1.3),
            headlineMedium: type(28, FontWeight.w600, height: 1.3),
            headlineSmall: type(24, FontWeight.w600, height: 1.3),
            titleLarge: type(20, FontWeight.w600, height: 1.3),
            titleMedium: type(16, FontWeight.w600, height: 1.3),
            titleSmall: type(14, FontWeight.w600, height: 1.3),
            bodyLarge: type(15, FontWeight.w500, height: 1.5),
            bodyMedium: type(14, FontWeight.w500, height: 1.5),
            bodySmall: type(12, FontWeight.w400),
            labelLarge: type(14, FontWeight.w500),
            labelMedium: type(12, FontWeight.w500),
            labelSmall: type(11, FontWeight.w400),
          ),
      iconTheme: IconThemeData(color: colors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: type(20, FontWeight.w600, height: 1.3),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        barrierColor: Colors.black54,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: type(20, FontWeight.w600, height: 1.3),
        contentTextStyle: type(14, FontWeight.w500, height: 1.5),
        shape: shape,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        headerBackgroundColor: colors.surface,
        headerForegroundColor: colors.text,
        headerHeadlineStyle: type(32, FontWeight.w600, height: 1.2),
        headerHelpStyle: type(12, FontWeight.w500),
        subHeaderForegroundColor: colors.text,
        toggleButtonTextStyle: type(14, FontWeight.w500),
        weekdayStyle: type(13, FontWeight.w500).copyWith(color: colors.muted),
        dayStyle: type(14, FontWeight.w500),
        dayForegroundColor: dateForeground,
        dayBackgroundColor: dateBackground,
        dayOverlayColor: dateOverlay,
        todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.muted.withValues(alpha: 0.45);
          }

          return states.contains(WidgetState.selected)
              ? onPrimary
              : colors.primary;
        }),
        todayBackgroundColor: dateBackground,
        todayBorder: BorderSide(color: colors.primary),
        yearStyle: type(14, FontWeight.w500),
        yearForegroundColor: dateForeground,
        yearBackgroundColor: dateBackground,
        yearOverlayColor: dateOverlay,
        rangePickerBackgroundColor: colors.surface,
        rangePickerSurfaceTintColor: Colors.transparent,
        rangePickerShape: shape,
        rangePickerHeaderBackgroundColor: colors.surface,
        rangePickerHeaderForegroundColor: colors.text,
        rangePickerHeaderHeadlineStyle: type(28, FontWeight.w600, height: 1.2),
        rangePickerHeaderHelpStyle: type(12, FontWeight.w500),
        rangeSelectionBackgroundColor: colors.primarySoft,
        rangeSelectionOverlayColor: dateOverlay,
        dividerColor: colors.border,
        inputDecorationTheme: inputTheme,
        cancelButtonStyle: button(),
        confirmButtonStyle: button(),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.surface,
        shape: shape,
        dialBackgroundColor: colors.surfaceTint,
        dialHandColor: colors.primary,
        dialTextColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? onPrimary : colors.text,
        ),
        dialTextStyle: type(14, FontWeight.w500),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primarySoft
              : colors.surfaceTint,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.text,
        ),
        hourMinuteTextStyle: type(40, FontWeight.w600, height: 1.2),
        dayPeriodColor: colors.primarySoft,
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.text,
        ),
        dayPeriodTextStyle: type(14, FontWeight.w500),
        dayPeriodBorderSide: BorderSide(color: colors.borderStrong),
        entryModeIconColor: colors.primary,
        helpTextStyle: type(12, FontWeight.w500).copyWith(color: colors.muted),
        inputDecorationTheme: inputTheme,
        cancelButtonStyle: button(),
        confirmButtonStyle: button(),
      ),
      filledButtonTheme: FilledButtonThemeData(style: button(filled: true)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: button()),
      textButtonTheme: TextButtonThemeData(style: button()),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return states.contains(WidgetState.disabled)
                ? colors.muted
                : colors.primary;
          }),
        ),
      ),
      inputDecorationTheme: inputTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.20),
        selectionHandleColor: colors.primary,
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: type(14, FontWeight.w500),
        shape: shape,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(shape),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: type(14, FontWeight.w500),
        inputDecorationTheme: inputTheme,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(shape),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.text,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: type(12, FontWeight.w400).copyWith(color: colors.background),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surface,
        contentTextStyle: type(14, FontWeight.w500),
        actionTextColor: colors.primary,
        disabledActionTextColor: colors.muted,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: shape,
      ),
    );
  }
}
