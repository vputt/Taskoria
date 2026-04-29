import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile> userAsync = ref.watch(effectiveUserProvider);
    final AsyncValue<List<Task>> tasksAsync = ref.watch(tasksProvider);
    final int unlockedAchievements =
        ref
            .watch(achievementsProvider)
            .valueOrNull
            ?.where((AchievementProgress item) => item.isUnlocked)
            .length ??
        userAsync.valueOrNull?.achievementsCount ??
        0;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        bottom: false,
        child: userAsync.when(
          loading: () => const _ProfileLoadingState(),
          error: (Object error, StackTrace stackTrace) => _ProfileStateCard(
            title: 'Не удалось загрузить профиль',
            description:
                'Попробуй обновить данные. Я заново подтяну прогресс, серию и статистику.',
            actionLabel: 'Повторить',
            onAction: () => ref.invalidate(userProvider),
          ),
          data: (UserProfile user) => tasksAsync.when(
            loading: () => const _ProfileLoadingState(),
            error: (Object error, StackTrace stackTrace) => _ProfileStateCard(
              title: 'Не удалось собрать статистику',
              description:
                  'Профиль уже есть, но задачи не подгрузились. Повторный запрос должен это исправить.',
              actionLabel: 'Повторить',
              onAction: () => ref.invalidate(tasksProvider),
            ),
            data: (List<Task> tasks) => _ProfileBody(
              user: user,
              tasks: tasks,
              unlockedAchievements: unlockedAchievements,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.tasks,
    required this.unlockedAchievements,
  });

  final UserProfile user;
  final List<Task> tasks;
  final int unlockedAchievements;

  @override
  Widget build(BuildContext context) {
    final DateTime anchorDate = _resolveAnchorDate(user, tasks);
    final double xpProgress = user.xpNextLevelTotal == 0
        ? 0
        : ((user.xpCurrent / user.xpNextLevelTotal) * 100).clamp(0, 100);
    final List<Task> completedTasks = tasks
        .where((Task task) => task.status == TaskStatus.completed)
        .toList(growable: false);
    final int tasksThisWeek = completedTasks.where((Task task) {
      final DateTime? completedAt = task.completedAt;
      if (completedAt == null) {
        return false;
      }
      final DateTime normalized = _stripTime(completedAt);
      final DateTime start = _stripTime(
        anchorDate,
      ).subtract(const Duration(days: 6));
      return !normalized.isBefore(start) &&
          !normalized.isAfter(_stripTime(anchorDate));
    }).length;
    final List<int> activity = _buildActivity(completedTasks, anchorDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Профиль', style: AppTextStyles.display)),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: AppRadius.avatar,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const PixelImage(AssetPaths.avatar),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(user.username, style: AppTextStyles.title),
                            const SizedBox(height: 2),
                            Text(
                              'В городе с ${_formatDate(user.createdAt)}',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DecoratedBox(
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: AppRadius.chip,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Уровень ${user.level}',
                                  style: AppTextStyles.tiny.copyWith(
                                    color: AppColors.accentBrownDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: AppRadius.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Опыт до следующего уровня',
                                style: AppTextStyles.caption,
                              ),
                            ),
                            Text(
                              '${user.xpCurrent} / ${user.xpNextLevelTotal} XP',
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.accentBrownDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: AppRadius.card,
                          child: LinearProgressIndicator(
                            value: xpProgress / 100,
                            minHeight: 12,
                            backgroundColor: AppColors.surfaceMuted,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          title: 'Монеты',
                          value: '${user.coins}',
                          leading: const PixelImage(
                            AssetPaths.coin,
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MetricCard(
                          title: 'Серия',
                          value: '${user.streak} дней',
                          leading: const Icon(
                            Icons.local_fire_department_outlined,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  title: 'Закрыто',
                  value: '${user.tasksCompleted}',
                  icon: Icons.task_alt_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  title: 'За 7 дней',
                  value: '$tasksThisWeek',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  title: 'Зданий',
                  value: '${user.buildingsCount}',
                  icon: Icons.location_city_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Активность', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Последние 7 недель относительно текущего прогресса.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activity.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      final int intensity = activity[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: _activityColor(intensity),
                          borderRadius: AppRadius.chip,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Text('7 недель назад', style: AppTextStyles.tiny),
                      const Spacer(),
                      Text('Сейчас', style: AppTextStyles.tiny),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickActionCard(
                  title: 'Достижения',
                  subtitle: '$unlockedAchievements открыто',
                  icon: Icons.workspace_premium_outlined,
                  onTap: () => context.push('/profile/achievements'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionCard(
                  title: 'Магазин',
                  subtitle: '${user.coins} монет',
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => context.go('/shop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.leading,
  });

  final String title;
  final String value;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.accentOliveDark),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 24, color: AppColors.accentBrownDark),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStateCard extends StatelessWidget {
  const _ProfileStateCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      child: Column(
        children: List<Widget>.generate(
          5,
          (int index) => Padding(
            padding: EdgeInsets.only(bottom: index == 4 ? 0 : AppSpacing.md),
            child: Container(
              width: double.infinity,
              height: index == 0 ? 72 : (index == 1 ? 240 : 132),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary.withValues(alpha: 0.86),
                borderRadius: AppRadius.card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

DateTime _resolveAnchorDate(UserProfile user, List<Task> tasks) {
  DateTime anchor = user.lastActivityDate ?? user.createdAt;
  for (final Task task in tasks) {
    final DateTime? completedAt = task.completedAt;
    if (completedAt != null && completedAt.isAfter(anchor)) {
      anchor = completedAt;
    }
  }
  return anchor;
}

List<int> _buildActivity(List<Task> tasks, DateTime anchorDate) {
  final DateTime end = DateTime(
    anchorDate.year,
    anchorDate.month,
    anchorDate.day,
  );
  final Map<DateTime, int> counts = <DateTime, int>{};
  for (final Task task in tasks) {
    final DateTime? completedAt = task.completedAt;
    if (completedAt == null) {
      continue;
    }
    final DateTime key = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );
    counts.update(key, (int value) => value + 1, ifAbsent: () => 1);
  }

  return List<int>.generate(49, (int index) {
    final DateTime day = end.subtract(Duration(days: 48 - index));
    return (counts[day] ?? 0).clamp(0, 4);
  });
}

Color _activityColor(int intensity) {
  switch (intensity) {
    case 0:
      return AppColors.surfaceMuted;
    case 1:
      return const Color(0xFFD7E4B8);
    case 2:
      return const Color(0xFFBFD191);
    case 3:
      return AppColors.accentOlive;
    default:
      return AppColors.accentOliveDark;
  }
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}

DateTime _stripTime(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
