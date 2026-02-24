import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/widgets/app_bottom_nav.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final Widget? fab = _buildFab(context);
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final bool showTaskFade = navigationShell.currentIndex == 1;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: navigationShell),
          if (showTaskFade)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height:
                  bottomInset +
                  AppBottomNav.bottomSpacing +
                  AppBottomNav.navBarHeight +
                  132,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.58),
                        Colors.black.withValues(alpha: 0.94),
                      ],
                      stops: const <double>[0, 0.56, 1],
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomNav(
              currentIndex: navigationShell.currentIndex,
              onTap: (int index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
          if (fab != null)
            Positioned(
              right: 16,
              bottom:
                  bottomInset +
                  AppBottomNav.bottomSpacing +
                  AppBottomNav.navBarHeight +
                  24,
              child: fab,
            ),
        ],
      ),
    );
  }

  Widget? _buildFab(BuildContext context) {
    final double screenScale = (MediaQuery.sizeOf(context).width / 414)
        .clamp(0.86, 1.08)
        .toDouble();
    final double fabSize = 56 * screenScale;
    final double iconSize = 34 * screenScale;

    switch (navigationShell.currentIndex) {
      case 0:
      case 1:
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: AppRadius.card,
            boxShadow: AppTheme.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.card,
              onTap: () => context.push('/tasks/create'),
              child: SizedBox(
                width: fabSize,
                height: fabSize,
                child: Center(
                  child: PixelImage(
                    AssetPaths.fabEdit,
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
              ),
            ),
          ),
        );
      default:
        return null;
    }
  }
}
