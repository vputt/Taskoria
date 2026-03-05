import 'package:flutter/material.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.pageGradient),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 5),
                  const _SplashLogo(),
                  const SizedBox(height: 30),
                  Text(
                    'Taskoria',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.display.copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Строй город через маленькие победы каждый день',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SplashLoadingBar(),
                  const Spacer(flex: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 156,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold.withValues(alpha: 0.12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.20),
                  blurRadius: 42,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
          const PixelImage(AssetPaths.cityEmblem, width: 210, height: 140),
        ],
      ),
    );
  }
}

class _SplashLoadingBar extends StatelessWidget {
  const _SplashLoadingBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 5,
          backgroundColor: AppColors.surfaceMuted.withValues(alpha: 0.88),
          color: AppColors.accentBrown,
        ),
      ),
    );
  }
}
