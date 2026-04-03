import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const background  = Color(0xFF0D1117);
  static const surface     = Color(0xFF161B27);
  static const card        = Color(0xFF1E2438);
  static const cardHover   = Color(0xFF262D47);

  // Brand
  static const primary     = Color(0xFF4FC3F7);
  static const primaryDark = Color(0xFF0288D1);

  // Money / Gold
  static const gold        = Color(0xFFFFD700);
  static const goldLight   = Color(0xFFFFE57F);

  // Status
  static const profit      = Color(0xFF4CAF50);
  static const profitLight = Color(0xFFA5D6A7);
  static const loss        = Color(0xFFEF5350);
  static const lossLight   = Color(0xFFEF9A9A);
  static const warning     = Color(0xFFFF9800);
  static const info        = Color(0xFF29B6F6);

  // Text
  static const textPrimary   = Color(0xFFE8EAED);
  static const textSecondary = Color(0xFF9AA0A6);
  static const textHint      = Color(0xFF5F6368);

  // Border & Divider
  static const border  = Color(0xFF2D3148);
  static const divider = Color(0xFF1E243E);
}

class AppTheme {
  static ThemeData get dark {
    final base = GoogleFonts.cairoTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: base.copyWith(
        displayLarge:  base.displayLarge!.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: base.displayMedium!.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: base.headlineLarge!.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium:base.headlineMedium!.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: base.headlineSmall!.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge:    base.titleLarge!.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium:   base.titleMedium!.copyWith(color: AppColors.textPrimary),
        titleSmall:    base.titleSmall!.copyWith(color: AppColors.textSecondary),
        bodyLarge:     base.bodyLarge!.copyWith(color: AppColors.textPrimary),
        bodyMedium:    base.bodyMedium!.copyWith(color: AppColors.textSecondary),
        bodySmall:     base.bodySmall!.copyWith(color: AppColors.textHint),
        labelLarge:    base.labelLarge!.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.loss),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.loss, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black87,
        elevation: 4,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.card),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
