import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _suite = 'SUITE';
  static const _serif = 'InstrumentSerif';

  // Logo (Instrument Serif, italic)

  static const logo = TextStyle(
    fontFamily: _serif,
    fontStyle: FontStyle.italic,
    fontSize: 28,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const logoSmall = TextStyle(
    fontFamily: _serif,
    fontStyle: FontStyle.italic,
    fontSize: 20,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Headings (SUITE)

  static const heading1 = TextStyle(
    fontFamily: _suite,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const heading2 = TextStyle(
    fontFamily: _suite,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const heading3 = TextStyle(
    fontFamily: _suite,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Nav / Subtitle

  static const nav = TextStyle(
    fontFamily: _suite,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const subtitle = TextStyle(
    fontFamily: _suite,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Body

  static const body = TextStyle(
    fontFamily: _suite,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodyLight = TextStyle(
    fontFamily: _suite,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: _suite,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.5,
  );

  // Caption / Small

  static const caption = TextStyle(
    fontFamily: _suite,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
  );

  static const captionBold = TextStyle(
    fontFamily: _suite,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.4,
  );

  // Button

  static const button = TextStyle(
    fontFamily: _suite,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  // Timetable Cell

  static const timetableLabel = TextStyle(
    fontFamily: _suite,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const timetableSublabel = TextStyle(
    fontFamily: _suite,
    fontSize: 9,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  // Search

  static const searchHint = TextStyle(
    fontFamily: _suite,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.5,
  );

  // Field / Forms

  static const fieldLabel = TextStyle(
    fontFamily: _suite,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const fieldHint = TextStyle(
    fontFamily: _suite,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.5,
  );

  static const fieldInput = TextStyle(
    fontFamily: _suite,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Error

  static const error = TextStyle(
    fontFamily: _suite,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.errorHigh,
    height: 1.5,
  );
}
