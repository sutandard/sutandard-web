import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand / Primary — 수원대 블루 계열
  static const primary = Color(0xFF4A6CF7);
  static const primaryHigh = Color(0xFF2B4ACF);
  static const primaryLight = Color(0xFFADB8FF);
  static const onPrimary = Color(0xFFFFFFFF);

  // Background & Surface
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const cardBackground = Color(0xFFF0F1F7);
  static const cardSolid = Color(0xFFE8EAF2);

  // Text
  static const textPrimary = Color(0xFF1A1D2B);
  static const textSecondary = Color(0xFF5A5F72);
  static const textTertiary = Color(0xFF8B90A0);
  static const textHint = Color(0xFFA0A4B2);

  // Border / Divider
  static const border = Color(0xFFE0E2EA);
  static const divider = Color(0xFFEBEDF5);
  static const disabled = Color(0xFFCBD0DD);

  // Semantic
  static const error = Color(0xFFF87171);
  static const errorHigh = Color(0xFFEF4444);
  static const success = Color(0xFF34D399);
  static const successHigh = Color(0xFF10B981);
  static const warning = Color(0xFFFBBF24);

  // Accent (보조 강조)
  static const accent = Color(0xFF6366F1);
  static const accentLight = Color(0xFFEEF2FF);

  // Timetable lecture card background colors
  static const List<Color> lectureBackgrounds = [
    Color(0xFFDBEAFE),
    Color(0xFFFCE7F3),
    Color(0xFFD1FAE5),
    Color(0xFFFED7AA),
    Color(0xFFE9D5FF),
    Color(0xFFCFFAFE),
    Color(0xFFFEF9C3),
    Color(0xFFFFE4E6),
    Color(0xFFE0E7FF),
    Color(0xFFF3E8FF),
  ];

  static const List<Color> lectureForegrounds = [
    Color(0xFF1E40AF),
    Color(0xFF9D174D),
    Color(0xFF065F46),
    Color(0xFF9A3412),
    Color(0xFF6B21A8),
    Color(0xFF155E75),
    Color(0xFF854D0E),
    Color(0xFF9F1239),
    Color(0xFF3730A3),
    Color(0xFF6B21A8),
  ];
}
