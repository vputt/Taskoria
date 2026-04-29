import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AchievementProgress>> achievementsAsync = ref.watch(
      achievementsProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
          bottom: false,
          child: achievementsAsync.when(
            loading: () => const _AchievementsLoadingState(),
            error: (Object error, StackTrace stackTrace) => _AchievementsStateCard(
              title: 'Не удалось загрузить достижения',
              description:
                  'Попробуй обновить данные. Прогресс и награды подтянутся из текущего состояния приложения.',
              actionLabel: 'Повторить',
              onAction: () => ref.invalidate(achievementsProvider),
            ),
            data: (List<AchievementProgress> items) =>
                _AchievementsBody(items: items),
          ),
        ),
      ),
    );
  }
}

class _AchievementsBody extends StatelessWidget {
  const _AchievementsBody({required this.items});

  final List<AchievementProgress> items;

  @override
  Widget build(BuildContext context) {
    final int unlockedCount = items.where((AchievementProgress item) {
      return item.isUnlocked;
    }).length;
    final int totalCount = items.length;
    final double ratio = totalCount == 0 ? 0 : unlockedCount / totalCount;
    final List<AchievementProgress> sorted = <AchievementProgress>[
      ...items.where((AchievementProgress item) => item.isUnlocked),
      ...items.where((AchievementProgress item) => !item.isUnlocked),
    ];

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            120,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: AppColors.borderSoft),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Достижения', style: AppTextStyles.display),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SummaryCard(
                unlockedCount: unlockedCount,
                totalCount: totalCount,
                ratio: ratio,
              ),
              const SizedBox(height: AppSpacing.lg),
              ...sorted.map(
                (AchievementProgress item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AchievementCard(item: item),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.unlockedCount,
    required this.totalCount,
    required this.ratio,
  });

  final int unlockedCount;
  final int totalCount;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.accentGold,
        borderRadius: AppRadius.modal,
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.workspace_premium_rounded,
              size: 56,
              color: AppColors.textOnDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$unlockedCount из $totalCount',
              style: AppTextStyles.display.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'достижений уже открыто',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.card,
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                backgroundColor: AppColors.textOnDark.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.surfacePrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final AchievementProgress item;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = item.isUnlocked;
    final Color accent = _accentForCode(item.achievement.code);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.modal,
        border: Border.all(
          color: unlocked
              ? accent.withValues(alpha: 0.7)
              : AppColors.borderSoft,
          width: unlocked ? 1.4 : 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? accent.withValues(alpha: 0.16)
                        : AppColors.surfaceSoft,
                    borderRadius: AppRadius.card,
                  ),
                  child: Icon(
                    unlocked
                        ? _iconForCode(item.achievement.code)
                        : Icons.lock_outline_rounded,
                    color: unlocked ? accent : AppColors.textMuted,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.achievement.name,
                              style: AppTextStyles.title,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusPill(unlocked: unlocked, accent: accent),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.achievement.description ??
                            'Награда за прогресс в городе.',
                        style: AppTextStyles.body.copyWith(
                          color: unlocked
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          _RewardChip(
                            icon: Icons.auto_awesome_rounded,
                            label: '${item.achievement.xpReward} XP',
                            color: AppColors.accentBrownDark,
                          ),
                          _RewardChip(
                            icon: Icons.toll_rounded,
                            label: '${item.achievement.coinsReward}',
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!unlocked) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Text('Прогресс', style: AppTextStyles.caption),
                  const Spacer(),
                  Text(
                    '${item.current}/${item.target}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.card,
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.unlocked, required this.accent});

  final bool unlocked;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: unlocked
            ? accent.withValues(alpha: 0.14)
            : AppColors.surfaceSoft,
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          unlocked ? 'Открыто' : 'В пути',
          style: AppTextStyles.tiny.copyWith(
            color: unlocked ? accent : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AchievementsStateCard extends StatelessWidget {
  const _AchievementsStateCard({
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

class _AchievementsLoadingState extends StatelessWidget {
  const _AchievementsLoadingState();

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
              height: index == 0 ? 60 : (index == 1 ? 180 : 156),
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

IconData _iconForCode(String code) {
  switch (code) {
    case 'first_task':
      return Icons.flag_rounded;
    case 'task_master_10':
      return Icons.workspace_premium_rounded;
    case 'streak_7':
      return Icons.local_fire_department_rounded;
    case 'city_builder':
      return Icons.location_city_rounded;
    case 'study_master':
      return Icons.menu_book_rounded;
    default:
      return Icons.star_rounded;
  }
}

Color _accentForCode(String code) {
  switch (code) {
    case 'first_task':
      return AppColors.accentBrown;
    case 'task_master_10':
      return AppColors.warning;
    case 'streak_7':
      return AppColors.danger;
    case 'city_builder':
      return AppColors.accentOliveDark;
    case 'study_master':
      return AppColors.categoryStudy;
    default:
      return AppColors.accentBrownDark;
  }
}
