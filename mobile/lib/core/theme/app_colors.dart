import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Identity - Deep Emerald Green
  static const Color primary = Color(0xFF087F5B);
  static const Color primaryDark = Color(0xFF065F44);
  static const Color primaryLight = Color(0xFFE6F5F0);
  static const Color primaryBorder = Color(0xFFBFE3D7);

  // Background & Surfaces
  static const Color background = Color(0xFFF8F8F5); // Warm Off-White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3F4F6);

  // Text Hierarchy
  static const Color textDark = Color(0xFF171717); // Near Black
  static const Color textMuted = Color(0xFF667085); // Slate Gray
  static const Color textLight = Color(0xFF9CA3AF);

  // Dividers & Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF1F2F4);

  // Feedback & Statuses
  static const Color success = Color(0xFF087F5B);
  static const Color successLight = Color(0xFFE6F5F0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Subtle shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
