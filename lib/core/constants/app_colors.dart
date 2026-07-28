import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0F172A); // Deep slate blue
  static const Color darkSurface = Color(0xFF1E293B);    // Slate surface
  static const Color darkSurfaceCard = Color(0xCC1E293B); // Semi-transparent for glassmorphism
  static const Color darkBorder = Color(0x3394A3B8);      // Slate border

  // Premium Accents
  static const Color primary = Color(0xFF6366F1);     // Indigo
  static const Color secondary = Color(0xFF06B6D4);   // Neon Cyan
  static const Color tertiary = Color(0xFF8B5CF6);    // Violet

  // Status Colors
  static const Color success = Color(0xFF10B981);     // Emerald green
  static const Color warning = Color(0xFFF59E0B);     // Amber orange
  static const Color danger = Color(0xFFEF4444);      // Rose red

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);   // Off white
  static const Color textSecondary = Color(0xFF94A3B8); // Cool grey
  static const Color textMuted = Color(0xFF64748B);     // Slate grey

  // Utility to parse Hex Colors from CategoryModel
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
