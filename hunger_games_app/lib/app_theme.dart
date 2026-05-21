import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF080808);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceVariant = Color(0xFF1E1E1E);
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8C97A);
  static const Color goldDark = Color(0xFF8B6914);
  static const Color deathRed = Color(0xFFCC1A1A);
  static const Color deathRedDark = Color(0xFF7A0000);
  static const Color offWhite = Color(0xFFE8E0D0);
  static const Color muted = Color(0xFF777770);
  static const Color border = Color(0xFF2A2820);
  static const Color goldBorder = Color(0xFF4A3A14);
}

class AppTextStyles {
  static TextStyle capitolTitle(double size) => GoogleFonts.cinzel(
        fontSize: size,
        color: AppColors.gold,
        fontWeight: FontWeight.w700,
        letterSpacing: 4.0,
      );

  static TextStyle capitolSubtitle(double size) => GoogleFonts.cinzel(
        fontSize: size,
        color: AppColors.offWhite,
        fontWeight: FontWeight.w400,
        letterSpacing: 3.0,
      );

  static TextStyle capitolSmall(double size) => GoogleFonts.cinzel(
        fontSize: size,
        color: AppColors.muted,
        fontWeight: FontWeight.w400,
        letterSpacing: 2.0,
      );

  static TextStyle narrative(double size) => TextStyle(
        fontSize: size,
        color: AppColors.offWhite,
        height: 1.6,
        fontFamily: 'serif',
      );

  static TextStyle deathNarrative(double size) => TextStyle(
        fontSize: size,
        color: AppColors.deathRed,
        height: 1.6,
        fontWeight: FontWeight.w500,
        fontFamily: 'serif',
      );

  static TextStyle ui(double size, {Color? color}) => TextStyle(
        fontSize: size,
        color: color ?? AppColors.offWhite,
      );

  static TextStyle label(double size) => TextStyle(
        fontSize: size,
        color: AppColors.muted,
        letterSpacing: 1.5,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.deathRed,
      surface: AppColors.surface,
      onPrimary: AppColors.background,
      onSecondary: AppColors.offWhite,
      onSurface: AppColors.offWhite,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: GoogleFonts.cinzel(
        fontSize: 16,
        color: AppColors.gold,
        fontWeight: FontWeight.w700,
        letterSpacing: 3.0,
      ),
      iconTheme: const IconThemeData(color: AppColors.gold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        textStyle: GoogleFonts.cinzel(
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.goldBorder),
        textStyle: GoogleFonts.cinzel(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.deathRed),
        borderRadius: BorderRadius.circular(2),
      ),
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    dividerColor: AppColors.border,
    cardColor: AppColors.surface,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surfaceVariant),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.offWhite),
    ),
  );
}
