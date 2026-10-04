import 'package:flutter/material.dart';

/// Tailwind colors used by the Figma Make design.
class Tw {
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);
  static const muted = Color(0xFF717182);

  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue300 = Color(0xFF93C5FD);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue900 = Color(0xFF1E3A8A);

  static const indigo50 = Color(0xFFEEF2FF);
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);

  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green600 = Color(0xFF16A34A);
  static const green700 = Color(0xFF15803D);
  static const emerald600 = Color(0xFF059669);

  static const orange100 = Color(0xFFFFEDD5);
  static const orange600 = Color(0xFFEA580C);
  static const yellow100 = Color(0xFFFEF9C3);
  static const yellow700 = Color(0xFFA16207);
  static const amber50 = Color(0xFFFFFBEB);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber700 = Color(0xFFB45309);

  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red700 = Color(0xFFB91C1C);

  static const cyan100 = Color(0xFFCFFAFE);
  static const cyan600 = Color(0xFF0891B2);
  static const sky500 = Color(0xFF0EA5E9);
}

class AppTheme {
  static const Color primaryBlue = Tw.blue600;
  static const Color primaryBlueDark = Tw.blue700;
  static const Color primaryIndigo = Tw.indigo600;
  static const Color accentIndigo = Tw.indigo700;

  static const Color successGreen = Tw.green600;
  static const Color successGreenLight = Tw.green50;
  static const Color warningOrange = Tw.orange600;
  static const Color warningOrangeLight = Color(0xFFFFF7ED);
  static const Color destructiveRed = Tw.red600;

  static const Color backgroundLight = Tw.gray50;
  static const Color backgroundWhite = Colors.white;
  static const Color cardBorder = Tw.gray200;
  static const Color textPrimary = Tw.gray900;
  static const Color textSecondary = Tw.muted;
  static const Color textTertiary = Tw.gray400;
  static const Color divider = Tw.gray100;

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Tw.blue600, Tw.indigo700],
  );

  static const actionGradient = LinearGradient(colors: [Tw.blue600, Tw.indigo600]);

  static ThemeData get lightTheme {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Tw.gray200),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: primaryBlueDark,
        secondary: primaryIndigo,
        tertiary: successGreen,
        surface: backgroundWhite,
        error: destructiveRed,
      ),
      textTheme: const TextTheme(
        displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Tw.gray200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Tw.blue300,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: Tw.gray200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tw.gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Tw.blue500, width: 2)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Tw.red400)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Tw.red400, width: 2)),
        hintStyle: const TextStyle(color: Tw.gray400, fontSize: 14),
        prefixIconColor: Tw.gray400,
        suffixIconColor: Tw.gray400,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Tw.blue600 : Tw.gray200,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerColor: Tw.gray100,
    );
  }
}
