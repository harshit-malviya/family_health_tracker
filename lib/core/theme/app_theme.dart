import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static const String fontOutfit = 'Outfit';
  static const String fontNotoSansDevanagari = 'NotoSansDevanagari';

  static ThemeData get lightTheme => getTheme();

  static ThemeData getTheme([Locale? locale]) {
    final isHindi = locale?.languageCode == 'hi';
    final primaryFontFamily = isHindi ? fontNotoSansDevanagari : fontOutfit;
    final fallbackFamilies = isHindi ? const [fontOutfit] : const [fontNotoSansDevanagari];

    final defaultTextTheme = Typography.material2021().black;
    final baseTextTheme = defaultTextTheme.apply(
      fontFamily: primaryFontFamily,
      fontFamilyFallback: fallbackFamilies,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: primaryFontFamily,
      fontFamilyFallback: fallbackFamilies,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFamilies,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFamilies,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFamilies,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textDark,
          fontSize: 16,
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFamilies,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textMuted,
          fontSize: 14,
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFamilies,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.12),
            width: 1.2,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFamilies,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: primaryFontFamily,
            fontFamilyFallback: fallbackFamilies,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
