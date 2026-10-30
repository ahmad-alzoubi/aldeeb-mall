import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Carrefour Hypermarket Style)
  static const Color primary = Color(0xFF0D47A1);        // Deep Royal Carrefour Blue
  static const Color primaryLight = Color(0xFF1976D2);   // Vibrant Blue
  static const Color primaryDark = Color(0xFF0A2E6B);    // Navy Accent
  static const Color secondary = Color(0xFFE53935);      // Vibrant Carrefour Red (Offers/Badges)
  static const Color secondaryLight = Color(0xFFFFEBEE); // Soft Red Tint
  static const Color accent = Color(0xFFFFB300);         // Gold / Loyalty Points Star
  static const Color accentLight = Color(0xFFFFF8E1);

  // Fresh Produce & Organic Accents
  static const Color freshGreen = Color(0xFF10B981);
  static const Color freshGreenLight = Color(0xFFECFDF5);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC);     // Soft Pearl White/Grey
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F6);

  // Typography & Text
  static const Color textPrimary = Color(0xFF0F172A);    // Deep Slate
  static const Color textSecondary = Color(0xFF64748B);  // Muted Slate
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Elevation Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0x0A0F172A),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: const Color(0x1F0D47A1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
