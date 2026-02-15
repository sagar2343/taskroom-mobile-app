import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_pallete.dart';

class AppTheme {
  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderSide: BorderSide(color: color, width: 1.5),
    borderRadius: BorderRadius.circular(12),
  );

  /// Common TextTheme using Inter font (matching HTML design)
  static TextTheme _textTheme(Color textColor) =>
      GoogleFonts.interTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      );

  /// Card decoration for light theme
  static BoxDecoration lightCardDecoration = BoxDecoration(
    color: Pallete.surfaceLight,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Pallete.borderLight, width: 1),
    boxShadow: [
      BoxShadow(
        color: Pallete.shadowLight,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Card decoration for dark theme
  static BoxDecoration darkCardDecoration = BoxDecoration(
    color: Pallete.surfaceDark,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Pallete.borderDark, width: 1),
    boxShadow: [
      BoxShadow(
        color: Pallete.shadowDark,
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static final darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Pallete.backgroundDark,
    textTheme: _textTheme(Pallete.textPrimaryDark),

    // Colors
    colorScheme: const ColorScheme.dark(
      primary: Pallete.primaryColor,
      secondary: Pallete.primaryLightColor,
      surface: Pallete.surfaceDark,
      error: Pallete.errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Pallete.textPrimaryDark,
      onError: Colors.white,
      outline: Pallete.borderDark,
    ),

    // AppBar - matching HTML sticky header
    appBarTheme: AppBarTheme(
      backgroundColor: Pallete.backgroundDark,
      foregroundColor: Pallete.textPrimaryDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Pallete.textPrimaryDark,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: Pallete.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Pallete.borderDark, width: 1),
      ),
      shadowColor: Pallete.shadowDark,
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(20),
      enabledBorder: _border(Pallete.borderDark),
      focusedBorder: _border(Pallete.primaryColor),
      errorBorder: _border(Pallete.errorColor),
      focusedErrorBorder: _border(Pallete.errorColor),
      filled: true,
      fillColor: Pallete.surfaceDark,
      hintStyle: TextStyle(color: Pallete.textSecondaryDark),
      labelStyle: TextStyle(color: Pallete.textSecondaryDark),
    ),

    // Buttons - iOS style from HTML
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Pallete.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shadowColor: Pallete.primaryColor.withValues(alpha: 0.2),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Pallete.primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pallete.primaryColor,
        side: BorderSide(color: Pallete.borderDark, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Bottom Navigation - matching HTML design
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Pallete.surfaceDark,
      selectedItemColor: Pallete.primaryColor,
      unselectedItemColor: Pallete.inactiveIcon,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    ),

    // SnackBars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Pallete.surfaceDark,
      contentTextStyle: GoogleFonts.inter(
        color: Pallete.textPrimaryDark,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Pallete.dividerDark,
      thickness: 1,
      space: 1,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: Pallete.surfaceDark,
      selectedColor: Pallete.primaryColor.withValues(alpha: 0.2),
      disabledColor: Pallete.surfaceDark.withValues(alpha: 0.5),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Pallete.borderDark),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: Pallete.textPrimaryDark,
      size: 24,
    ),
  );

  static final lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Pallete.backgroundLight,
    textTheme: _textTheme(Pallete.textPrimaryLight),

    // Colors
    colorScheme: const ColorScheme.light(
      primary: Pallete.primaryColor,
      secondary: Pallete.primaryLightColor,
      surface: Pallete.surfaceLight,
      error: Pallete.errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Pallete.textPrimaryLight,
      onError: Colors.white,
      outline: Pallete.borderLight,
    ),

    // AppBar - matching HTML sticky header
    appBarTheme: AppBarTheme(
      backgroundColor: Pallete.backgroundLight,
      foregroundColor: Pallete.textPrimaryLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Pallete.textPrimaryLight,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: Pallete.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Pallete.borderLight, width: 1),
      ),
      shadowColor: Pallete.shadowLight,
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(20),
      enabledBorder: _border(Pallete.borderLight),
      focusedBorder: _border(Pallete.primaryColor),
      errorBorder: _border(Pallete.errorColor),
      focusedErrorBorder: _border(Pallete.errorColor),
      filled: true,
      fillColor: Pallete.surfaceLight,
      hintStyle: TextStyle(color: Pallete.textSecondaryLight),
      labelStyle: TextStyle(color: Pallete.textSecondaryLight),
    ),

    // Buttons - iOS style from HTML
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Pallete.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shadowColor: Pallete.primaryColor.withValues(alpha: 0.2),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Pallete.primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pallete.primaryColor,
        side: BorderSide(color: Pallete.borderLight, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Bottom Navigation - matching HTML design
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Pallete.surfaceLight,
      selectedItemColor: Pallete.primaryColor,
      unselectedItemColor: Pallete.inactiveIcon,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    ),

    // SnackBars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Pallete.surfaceLight,
      contentTextStyle: GoogleFonts.inter(
        color: Pallete.textPrimaryLight,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Pallete.divider,
      thickness: 1,
      space: 1,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: Pallete.surfaceLight,
      selectedColor: Pallete.primaryColor.withValues(alpha: 0.1),
      disabledColor: Pallete.surfaceLight.withValues(alpha: 0.5),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Pallete.borderLight),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: Pallete.textPrimaryLight,
      size: 24,
    ),
  );
}