import 'package:flutter/material.dart';

/// Warm & Friendly Family Palette
class AppColors {
  // Primary Warm Tones
  static const Color primary = Color(0xFFE0533C); // Warm Terracotta / Coral
  static const Color primaryLight = Color(0xFFFFECE8);
  static const Color secondary = Color(0xFF2C6B6F); // Warm Teal Sage
  static const Color secondaryLight = Color(0xFFE7F3F3);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFBF9F6); // Warm porcelain cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E242B);
  static const Color textMuted = Color(0xFF6B7280);

  // Member Color Accents (Pastels)
  static const List<Color> memberPalette = [
    Color(0xFF3B82F6), // Warm Slate Blue (e.g., Dad)
    Color(0xFFF43F5E), // Warm Coral Rose (e.g., Mom)
    Color(0xFF10B981), // Warm Emerald Mint (e.g., Grandpa)
    Color(0xFFF59E0B), // Warm Marigold Amber (e.g., Grandma)
    Color(0xFF8B5CF6), // Warm Lavender Purple (e.g., Self)
    Color(0xFFEC4899), // Warm Bubblegum
  ];

  // AHA Blood Pressure Classification Badges
  static const Color bpNormal = Color(0xFF10B981); // Green
  static const Color bpElevated = Color(0xFFF59E0B); // Amber / Yellow
  static const Color bpStage1 = Color(0xFFF97316); // Orange
  static const Color bpStage2 = Color(0xFFEF4444); // Red
  static const Color bpCrisis = Color(0xFF991B1B); // Crimson Red

  // ADA Diabetes / Glucose Badges
  static const Color glucoseLow = Color(0xFF3B82F6); // Blue (Hypoglycemia alert)
  static const Color glucoseNormal = Color(0xFF10B981); // Green
  static const Color glucoseElevated = Color(0xFFF59E0B); // Amber
  static const Color glucoseHigh = Color(0xFFEF4444); // Red
}
