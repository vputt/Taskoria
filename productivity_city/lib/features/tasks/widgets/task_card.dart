import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/features/tasks/task_ui.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({required this.task, this.onTap, this.onComplete, super.key});

  final Task task;
  final VoidCallback? onTap;
  final Future<void> Function()? onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TaskWithSubtasks> detailAsync = ref.watch(
      taskDetailProvider(task.id),
    );

    final List<Subtask> subtasks = detailAsync.maybeWhen(
      data: (TaskWithSubtasks detail) => detail.subtasks,
      orElse: () => const <Subtask>[],
    );
    final int completedSubtasks = subtasks
        .where((Subtask item) => item.status == SubtaskStatus.completed)
        .length;
    final int totalSubtasks = subtasks.length;
    final double progress = totalSubtasks == 0
        ? 0
        : completedSubtasks / totalSubtasks;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: AppRadius.card,
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _TaskLeadingBadge(task: task),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF5E3718),
                              height: 1.14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _TaskMetaRow(task: task),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          _DifficultyStars(difficulty: task.difficulty),
                          const SizedBox(height: 6),
                          _RewardRow(task: task),
                        ],
                      ),
                    ),
                  ],
                ),
                if (totalSubtasks > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Text(
                        'Подзадачи',
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF8B7058),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedSubtasks/$totalSubtasks',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppRadius.card,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE8DDD0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentBrown,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 170,
                    height: 34,
                    child: FilledButton(
                      onPressed: onComplete == null
                          ? null
                          : () async {
                              await onComplete?.call();
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: onComplete == null
                            ? AppColors.accentOlive
                            : AppColors.accentOliveDark,
                        disabledBackgroundColor: AppColors.accentOlive,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        onComplete == null ? 'Выполнено' : 'Завершить',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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

class _TaskLeadingBadge extends StatelessWidget {
  const _TaskLeadingBadge({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: task.category.color,
        borderRadius: AppRadius.card,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: PixelImage(
          task.category.iconAsset,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _TaskMetaRow extends StatelessWidget {
  const _TaskMetaRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _TaskMetaChip(label: task.category.label)),
        const SizedBox(width: 6),
        Expanded(child: _TaskMetaChip(label: task.priority.label)),
        const SizedBox(width: 6),
        Expanded(
          child: _TaskMetaChip(
            label: task.deadline == null
                ? 'Дедлайн'
                : DateFormat('dd.MM').format(task.deadline!),
          ),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const PixelImage(AssetPaths.starFilled, width: 12, height: 12),
          const SizedBox(width: 2),
          RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '${task.xpReward}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentBrownDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: ' xp',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.accentBrownDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const PixelImage(AssetPaths.coinSmall, width: 11, height: 11),
          const SizedBox(width: 2),
          Text(
            '${task.coinsReward}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentBrownDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  const _DifficultyStars({required this.difficulty});

  final TaskDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (int index) {
        return Padding(
          padding: const EdgeInsets.only(left: 1),
          child: PixelImage(
            index < difficulty.filledStars
                ? AssetPaths.starFilled
                : AssetPaths.starEmpty,
            width: 15,
            height: 15,
          ),
        );
      }),
    );
  }
}

class _TaskMetaChip extends StatelessWidget {
  const _TaskMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF7EBDD),
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF8B7058),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
