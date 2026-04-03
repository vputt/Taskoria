import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/features/home/widgets/isometric_city_map.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/widgets/app_state_widgets.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile> userAsync = ref.watch(effectiveUserProvider);
    final AsyncValue<CityState> cityAsync = ref.watch(cityProvider);
    final List<ShopItem> placedItems =
        (ref.watch(shopProvider).valueOrNull ?? const <ShopItem>[])
            .where((ShopItem item) => item.isOwned && item.isPlaced)
            .toList(growable: false);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: userAsync.when(
        loading: () => const _HomeLoadingState(),
        error: (Object error, StackTrace stackTrace) => _HomeErrorState(
          onRetry: () {
            ref.invalidate(userProvider);
            ref.invalidate(cityProvider);
          },
        ),
        data: (UserProfile user) => cityAsync.when(
          loading: () => const _HomeLoadingState(),
          error: (Object error, StackTrace stackTrace) => _HomeErrorState(
            onRetry: () {
              ref.invalidate(userProvider);
              ref.invalidate(cityProvider);
            },
          ),
          data: (CityState cityState) => _HomeContent(
            user: user,
            cityState: cityState,
            placedItems: placedItems,
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.user,
    required this.cityState,
    required this.placedItems,
  });

  final UserProfile user;
  final CityState cityState;
  final List<ShopItem> placedItems;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: _CityScene(
            cityState: cityState,
            placedItems: placedItems,
            onBuildingTap: (Building building) =>
                _showBuildingSheet(context, building),
            onTownHallTap: () => _showTownHallSheet(context, user, cityState),
            onCharacterTap: (Character character) =>
                _showCharacterDialog(context, character),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: _HomeTopBar(user: user),
          ),
        ),
      ],
    );
  }

  void _showBuildingSheet(BuildContext context, Building building) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        final double maxHeight = MediaQuery.sizeOf(context).height * 0.82;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_buildingLabel(building), style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Категория: ${_categoryLabel(building.category)}',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Уровень: ${building.level}', style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _buildingDescription(building),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Понятно'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTownHallSheet(
    BuildContext context,
    UserProfile user,
    CityState cityState,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        final double maxHeight = MediaQuery.sizeOf(context).height * 0.82;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Ратуша', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Уровень профиля: ${user.level}',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Выполнено задач: ${user.tasksCompleted}',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Суммарный уровень зданий: ${cityState.response.totalLevel}',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...cityState.response.buildings.map((Building building) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '${_categoryLabel(building.category)}: уровень ${building.level}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Понятно'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCharacterDialog(BuildContext context, Character character) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const PixelImage(AssetPaths.hero, width: 56, height: 56),
              const SizedBox(height: AppSpacing.sm),
              Text(character.name, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              Text(
                character.message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final double progress = user.xpNextLevelTotal == 0
        ? 0
        : (user.xpCurrent / user.xpNextLevelTotal).clamp(0, 1);

    return SizedBox(
      height: 66,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _ChromeIconButton(
            assetPath: AssetPaths.notifications,
            semanticLabel: 'Уведомления',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Центр уведомлений добавим следующим этапом.'),
              ),
            ),
          ),
          const Spacer(),
          _ProfileCluster(
            coins: user.coins,
            username: user.username,
            level: user.level,
            progress: progress,
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCluster extends StatelessWidget {
  const _ProfileCluster({
    required this.coins,
    required this.username,
    required this.level,
    required this.progress,
    required this.onTap,
  });

  final int coins;
  final String username;
  final int level;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 198,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(right: 72, top: 12, child: _CoinBadge(coins: coins)),
          Positioned(
            right: 0,
            top: 1,
            child: _AvatarBadge(
              username: username,
              level: level,
              progress: progress,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityScene extends StatelessWidget {
  const _CityScene({
    required this.cityState,
    required this.placedItems,
    required this.onBuildingTap,
    required this.onTownHallTap,
    required this.onCharacterTap,
  });

  final CityState cityState;
  final List<ShopItem> placedItems;
  final ValueChanged<Building> onBuildingTap;
  final VoidCallback onTownHallTap;
  final ValueChanged<Character> onCharacterTap;

  @override
  Widget build(BuildContext context) {
    return IsometricCityMap(
      cityState: cityState,
      placedItems: placedItems,
      onBuildingTap: onBuildingTap,
      onTownHallTap: onTownHallTap,
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          118,
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 64,
              child: Row(
                children: <Widget>[
                  _SkeletonBox(width: 45, height: 45),
                  Spacer(),
                  _SkeletonBox(width: 165, height: 64),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(child: _SkeletonBox(width: double.infinity, height: 320)),
          ],
        ),
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppStateCard(
        title: 'Не удалось загрузить город',
        description:
            'Повтори загрузку, и главный экран снова соберет здания, декор и прогресс.',
        actionLabel: 'Повторить',
        onAction: onRetry,
      ),
    );
  }
}

class _ChromeIconButton extends ConsumerWidget {
  const _ChromeIconButton({
    required this.assetPath,
    required this.semanticLabel,
    required this.onTap,
  });

  final String assetPath;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isNotifications = assetPath == AssetPaths.notifications;
    final int badgeCount = isNotifications
        ? ref.watch(unreadNotificationsCountProvider)
        : 0;
    final VoidCallback resolvedOnTap = isNotifications
        ? () => context.push('/notifications')
        : onTap;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              boxShadow: AppTheme.softShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.card,
                onTap: resolvedOnTap,
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: Center(
                    child: PixelImage(assetPath, width: 21, height: 21),
                  ),
                ),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.accentBrown,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${badgeCount.clamp(0, 9)}',
                  style: AppTextStyles.tiny.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        boxShadow: AppTheme.softShadow,
      ),
      child: SizedBox(
        width: 126,
        height: 34,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  NumberFormat.decimalPattern('en_US').format(coins),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const PixelImage(AssetPaths.coin, width: 18, height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.username,
    required this.level,
    required this.progress,
    required this.onTap,
  });

  final String username;
  final int level;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Профиль пользователя $username',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 70,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.accentGold.withValues(alpha: 0.12),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.accentGold.withValues(
                                  alpha: 0.34,
                                ),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          size: const Size.square(64),
                          painter: _AvatarProgressPainter(progress: progress),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAD5FF),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const PixelImage(
                              AssetPaths.avatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfacePrimary,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        child: Text(
                          '$level',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary.withValues(alpha: 0.82),
        borderRadius: AppRadius.card,
      ),
    );
  }
}

class _AvatarProgressPainter extends CustomPainter {
  const _AvatarProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint progressGlowPaint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final Paint progressPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path outline = _buildCounterClockwiseRoundedRectPath(
      size,
      radius: 16,
      inset: 3.5,
    );
    canvas.drawPath(outline, trackPaint);

    for (final PathMetric metric in outline.computeMetrics()) {
      final Path part = metric.extractPath(
        0,
        metric.length * progress.clamp(0, 1),
      );
      canvas.drawPath(part, progressGlowPaint);
      canvas.drawPath(part, progressPaint);
    }
  }

  Path _buildCounterClockwiseRoundedRectPath(
    Size size, {
    required double radius,
    required double inset,
  }) {
    final Rect rect =
        Offset(inset, inset) &
        Size(size.width - inset * 2, size.height - inset * 2);
    final double safeRadius = math.min(
      radius,
      math.min(rect.width, rect.height) / 2,
    );

    return Path()
      ..moveTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.right - safeRadius, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - safeRadius),
        radius: Radius.circular(safeRadius),
        clockwise: false,
      )
      ..lineTo(rect.right, rect.top + safeRadius)
      ..arcToPoint(
        Offset(rect.right - safeRadius, rect.top),
        radius: Radius.circular(safeRadius),
        clockwise: false,
      )
      ..lineTo(rect.left + safeRadius, rect.top)
      ..arcToPoint(
        Offset(rect.left, rect.top + safeRadius),
        radius: Radius.circular(safeRadius),
        clockwise: false,
      )
      ..lineTo(rect.left, rect.bottom - safeRadius)
      ..arcToPoint(
        Offset(rect.left + safeRadius, rect.bottom),
        radius: Radius.circular(safeRadius),
        clockwise: false,
      )
      ..lineTo(rect.center.dx, rect.bottom);
  }

  @override
  bool shouldRepaint(covariant _AvatarProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

String _buildingLabel(Building building) {
  switch (building.category) {
    case TaskCategory.study:
      return 'Школа';
    case TaskCategory.work:
      return 'Офис';
    case TaskCategory.health:
      return 'Госпиталь';
    case TaskCategory.personal:
      return 'Личное';
  }
}

String _categoryLabel(TaskCategory category) {
  switch (category) {
    case TaskCategory.study:
      return 'Учеба';
    case TaskCategory.work:
      return 'Работа';
    case TaskCategory.health:
      return 'Здоровье';
    case TaskCategory.personal:
      return 'Личное';
  }
}

String _buildingDescription(Building building) {
  switch (building.category) {
    case TaskCategory.study:
      return 'Школа отражает прогресс в учебных задачах. Чем выше уровень, тем заметнее развивается учебный квартал города.';
    case TaskCategory.work:
      return 'Офис показывает развитие рабочих задач и карьерного темпа. Рост уровня означает стабильное движение в категории работы.';
    case TaskCategory.health:
      return 'Госпиталь связан с задачами на здоровье, восстановление и полезные привычки. Уровень здания показывает вклад этой категории в город.';
    case TaskCategory.personal:
      return 'Личное здание хранит прогресс по повседневным и личным делам. Повышение уровня делает эту часть города более живой и уютной.';
  }
}
