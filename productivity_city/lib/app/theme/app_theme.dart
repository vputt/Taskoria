import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';

abstract final class AppTheme {
  static const List<BoxShadow> softShadow = <BoxShadow>[
    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const LinearGradient primaryScreenGradient = pageGradient;

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.pageBackground,
      AppColors.pageBackground,
      AppColors.pageBackground,
    ],
    stops: <double>[0, 0.65, 1],
  );

  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accentOliveDark,
      onPrimary: AppColors.textOnDark,
      secondary: AppColors.accentGold,
      onSecondary: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.textOnDark,
      surface: AppColors.surfacePrimary,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      canvasColor: AppColors.pageBackground,
      shadowColor: AppColors.shadow,
      textTheme: GoogleFonts.montserratTextTheme(AppTextStyles.textTheme),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accentBrown,
        selectionColor: AppColors.surfaceSecondary,
        selectionHandleColor: AppColors.accentBrown,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.accentBrownDark,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textOnDark,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfacePrimary,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSoft,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modal),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modal),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBrown,
        linearTrackColor: AppColors.surfaceMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        indicatorColor: AppColors.navSelected,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.surfaceSecondary,
        side: const BorderSide(color: AppColors.borderSoft),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentOliveDark;
          }
          return AppColors.surfacePrimary;
        }),
        checkColor: const WidgetStatePropertyAll<Color>(AppColors.textOnDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfacePrimary,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        labelStyle: AppTextStyles.caption,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.accentOliveDark, width: 1.2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentOliveDark,
          foregroundColor: AppColors.textOnDark,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          side: const BorderSide(color: AppColors.borderSoft),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
    );
  }
}
