import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  static const double _referenceScreenWidth = 414;
  static const double _referenceNavWidth = 380;
  static const double navBarHeight = 52;
  static const double bottomSpacing = 30;

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItemData> _items = <_NavItemData>[
    _NavItemData(
      iconAsset: AssetPaths.navCity,
      semanticLabel: 'Город',
      iconWidth: 50,
      iconHeight: 35,
    ),
    _NavItemData(
      iconAsset: AssetPaths.navTasks,
      semanticLabel: 'Задачи',
      iconWidth: 38,
      iconHeight: 38,
    ),
    _NavItemData(
      iconAsset: AssetPaths.navCalendar,
      semanticLabel: 'Календарь',
      iconWidth: 38,
      iconHeight: 37,
    ),
    _NavItemData(
      iconAsset: AssetPaths.navShop,
      semanticLabel: 'Корзина',
      iconWidth: 38,
      iconHeight: 36,
    ),
    _NavItemData(
      iconAsset: AssetPaths.navProfile,
      semanticLabel: 'Профиль',
      iconWidth: 61,
      iconHeight: 61,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double screenScale = math
        .min(math.max(screenSize.width / _referenceScreenWidth, 0.84), 1.08)
        .toDouble();
    final double navWidth = math.max(
      0,
      math.min(
        screenSize.width - (AppSpacing.md * 2),
        _referenceNavWidth * screenScale,
      ),
    );
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: navBarHeight + bottomSpacing + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          bottomSpacing + bottomInset,
        ),
        child: Center(
          child: SizedBox(
            width: navWidth,
            height: navBarHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.navBackground,
                borderRadius: AppRadius.bottomNav,
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: List<Widget>.generate(_items.length, (int index) {
                  final bool isSelected = index == currentIndex;
                  final _NavItemData item = _items[index];

                  return Expanded(
                    child: Semantics(
                      selected: isSelected,
                      button: true,
                      label: item.semanticLabel,
                      child: InkWell(
                        borderRadius: AppRadius.card,
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          height: navBarHeight,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.navSelected
                                : Colors.transparent,
                            borderRadius: AppRadius.card,
                          ),
                          child: Center(
                            child: PixelImage(
                              item.iconAsset,
                              width: item.iconWidth * screenScale,
                              height: item.iconHeight * screenScale,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.iconAsset,
    required this.semanticLabel,
    required this.iconWidth,
    required this.iconHeight,
  });

  final String iconAsset;
  final String semanticLabel;
  final double iconWidth;
  final double iconHeight;
}
