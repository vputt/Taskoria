import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:productivity_city/app/theme/app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get display => GoogleFonts.montserrat(
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get title => GoogleFonts.montserrat(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get subtitle => GoogleFonts.montserrat(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.montserrat(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get caption => GoogleFonts.montserrat(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get tiny => GoogleFonts.montserrat(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle get button => GoogleFonts.montserrat(
    fontSize: 14,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: AppColors.textOnDark,
  );

  static TextStyle get metric => GoogleFonts.montserrat(
    fontSize: 18,
    height: 1.05,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    displayMedium: display,
    headlineMedium: title,
    titleLarge: title,
    titleMedium: subtitle,
    titleSmall: subtitle,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: caption.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );
}
