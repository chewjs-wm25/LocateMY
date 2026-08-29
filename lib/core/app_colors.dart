import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Tech Blue
  static const Color primaryBase = Color(0xFF1E40AF); // Blue 800
  static const Color primaryBaseAlternative = Color(0xFF2563EB); // Blue 600
  static const Color primaryHover = Color(0xFF1D4ED8); // Blue 700
  static const Color primaryContainer = Color(0xFFEFF6FF); // Blue 50
  static const Color primaryTint = Color(0xFF38BDF8); // Sky Blue 400

  // Semantic & Functional Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successContainer = Color(0xFFECFDF5); // Emerald 50
  
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningContainer = Color(0xFFFFFBEB); // Amber 50
  
  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color dangerContainer = Color(0xFFFEF2F2); // Red 50
  
  static const Color info = Color(0xFF06B6D4); // Cyan 500
  static const Color infoContainer = Color(0xFFECFEFF); // Cyan 50
  
  static const Color accent = Color(0xFFF97316); // Orange 500
  static const Color accentContainer = Color(0xFFFFF7ED); // Orange 50

  // Neutral & Surface Colors
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundDark = Color(0xFF0B0F19); // Deep Navy
  
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceDark = Color(0xFF131B2E); // Navy Slate
  
  static const Color surfaceSubLight = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceSubDark = Color(0xFF1E293B); // Slate 800
  
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderDark = Color(0xFF2E3A52); // Slate 700
  
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500

  // Card Shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 16.0,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
}
