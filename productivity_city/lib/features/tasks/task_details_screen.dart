import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/features/tasks/task_ui.dart';
import 'package:productivity_city/features/tasks/widgets/subtask_tile.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/network/api_exceptions.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/providers/repositories.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? parsedTaskId = int.tryParse(taskId);
    if (parsedTaskId == null) {
      return _TaskPageShell(
        title: 'Задача',
        onBack: () => _handleBack(context),
        child: _TaskStateCard(
          title: 'Не удалось открыть задачу',
          description: 'Маршрут передал некорректный идентификатор задачи.',
          actionLabel: 'К списку задач',
          onAction: () => context.go('/tasks'),
        ),
      );
    }

    final AsyncValue<TaskWithSubtasks> taskAsync = ref.watch(
      taskDetailProvider(parsedTaskId),
    );

    return _TaskPageShell(
      title: 'Задача',
      onBack: () => _handleBack(context),
      actions: taskAsync.maybeWhen(
        data: (TaskWithSubtasks task) => <Widget>[
          _HeaderActionButton(
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/tasks/${task.id}/edit'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _HeaderActionButton(
            icon: Icons.delete_outline_rounded,
            foregroundColor: AppColors.danger,
            onPressed: () => _handleDelete(context, ref, task),
          ),
        ],
        orElse: () => const <Widget>[],
      ),
      child: taskAsync.when(
        loading: () => const _TaskDetailsLoadingState(),
        error: (Object error, StackTrace stackTrace) => _TaskStateCard(
          title: 'Не удалось загрузить задачу',
          description:
              'Попробуй обновить экран. Если проблема повторится, я заново запрошу данные.',
          actionLabel: 'Повторить',
          onAction: () => ref.invalidate(taskDetailProvider(parsedTaskId)),
        ),
        data: (TaskWithSubtasks task) => _TaskDetailsBody(
          task: task,
          onSplit: () => _handleSplit(context, ref, task),
          onStart: task.status == TaskStatus.active
              ? () => _handleStart(context, ref, task)
              : null,
          onComplete: task.status == TaskStatus.completed
              ? null
              : () => _handleComplete(context, ref, task),
          onToggleSubtask: (Subtask subtask, bool completed) =>
              _handleToggleSubtask(context, ref, task, subtask, completed),
        ),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    TaskWithSubtasks task,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Удалить задачу?'),
          content: Text('Задача "${task.title}" исчезнет из списка задач.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(tasksProvider.notifier).deleteTask(task.id);
    if (!context.mounted) {
      return;
    }
    context.go('/tasks');
  }

  Future<void> _handleSplit(
    BuildContext context,
    WidgetRef ref,
    TaskWithSubtasks task,
  ) async {
    bool replaceExisting = false;
    if (task.subtasks.isNotEmpty) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text(
              '\u041f\u0435\u0440\u0435\u0441\u043e\u0431\u0440\u0430\u0442\u044c \u043f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0438?',
            ),
            content: const Text(
              '\u0422\u0435\u043a\u0443\u0449\u0438\u0435 \u043f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0438 \u0431\u0443\u0434\u0443\u0442 \u0437\u0430\u043c\u0435\u043d\u0435\u043d\u044b \u043d\u043e\u0432\u044b\u043c \u043d\u0430\u0431\u043e\u0440\u043e\u043c \u0448\u0430\u0433\u043e\u0432.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  '\u041e\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u043a\u0430\u043a \u0435\u0441\u0442\u044c',
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  '\u041f\u0435\u0440\u0435\u0441\u043e\u0431\u0440\u0430\u0442\u044c',
                ),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      replaceExisting = true;
    }
    _showBlockingProgress(
      context,
      title:
          '\u0421\u043e\u0431\u0438\u0440\u0430\u0435\u043c \u043f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0438',
      message:
          '\u0416\u0434\u0435\u043c \u043e\u0442\u0432\u0435\u0442 \u043c\u043e\u0434\u0435\u043b\u0438 \u0438 \u043d\u043e\u0432\u044b\u0439 \u0441\u043f\u0438\u0441\u043e\u043a \u0448\u0430\u0433\u043e\u0432.',
    );
    try {
      await ref
          .read(tasksProvider.notifier)
          .splitTask(task.id, replaceExisting: replaceExisting);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u041f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0438 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u044b.',
          ),
        ),
      );
    } on SubtasksAlreadyExistException {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0423 \u044d\u0442\u043e\u0439 \u0437\u0430\u0434\u0430\u0447\u0438 \u0443\u0436\u0435 \u0435\u0441\u0442\u044c \u043f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0438.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0431\u0440\u0430\u0442\u044c \u043f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0438. \u041f\u043e\u043f\u0440\u043e\u0431\u0443\u0439 \u0435\u0449\u0435 \u0440\u0430\u0437.',
          ),
        ),
      );
    }
  }

  Future<void> _handleStart(
    BuildContext context,
    WidgetRef ref,
    TaskWithSubtasks task,
  ) async {
    await ref
        .read(tasksProvider.notifier)
        .updateTask(
          task.id,
          const TaskUpdateInput(status: TaskStatus.inProgress),
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Задача переведена в работу.')),
    );
  }

  Future<void> _handleComplete(
    BuildContext context,
    WidgetRef ref,
    TaskWithSubtasks task,
  ) async {
    _showBlockingProgress(
      context,
      title:
          '\u0417\u0430\u0432\u0435\u0440\u0448\u0430\u0435\u043c \u0437\u0430\u0434\u0430\u0447\u0443',
      message:
          '\u041e\u0431\u043d\u043e\u0432\u043b\u044f\u0435\u043c \u043d\u0430\u0433\u0440\u0430\u0434\u0443, \u043f\u0440\u043e\u0444\u0438\u043b\u044c \u0438 \u0433\u043e\u0440\u043e\u0434.',
    );
    late final TaskCompleteResult result;
    try {
      result = await ref.read(tasksProvider.notifier).completeTask(task.id);
    } on ApiException {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      return;
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    unawaited(ref.read(userProvider.notifier).refresh());
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: task.category.color,
                  borderRadius: AppRadius.card,
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: PixelImage(
                    task.category.iconAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '\u0417\u0430\u0434\u0430\u0447\u0430 \u0437\u0430\u043a\u0440\u044b\u0442\u0430',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _RewardMetric(
                      label: '\u041e\u043f\u044b\u0442',
                      value: '+${result.xpEarned} XP',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _RewardMetric(
                      label: '\u041c\u043e\u043d\u0435\u0442\u044b',
                      value: '+${result.coinsEarned}',
                      icon: const PixelImage(
                        AssetPaths.coinSmall,
                        width: 12,
                        height: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (result.levelUp && result.newLevel != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: AppRadius.card,
                  ),
                  child: Text(
                    '\u041d\u043e\u0432\u044b\u0439 \u0443\u0440\u043e\u0432\u0435\u043d\u044c: ${result.newLevel}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text(
                    '\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleToggleSubtask(
    BuildContext context,
    WidgetRef ref,
    TaskWithSubtasks task,
    Subtask subtask,
    bool completed,
  ) async {
    if (!completed && subtask.status == SubtaskStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0412\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u043d\u0443\u044e \u043f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0443 \u043d\u0435\u043b\u044c\u0437\u044f \u0432\u0435\u0440\u043d\u0443\u0442\u044c \u043d\u0430\u0437\u0430\u0434. \u041e\u043d\u0430 \u0441\u043e\u0445\u0440\u0430\u043d\u044f\u0435\u0442\u0441\u044f \u0434\u043b\u044f \u0441\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043a\u0438.',
          ),
        ),
      );
      return;
    }
    try {
      await ref
          .read(tasksProvider.notifier)
          .updateSubtask(
            task.id,
            subtask.id,
            SubtaskUpdateInput(
              status: completed
                  ? SubtaskStatus.completed
                  : SubtaskStatus.notStarted,
            ),
          );
    } on ApiException {
      if (!context.mounted) {
        return;
      }
      return;
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u043f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0443. \u041f\u043e\u043f\u0440\u043e\u0431\u0443\u0439 \u0435\u0449\u0435 \u0440\u0430\u0437.',
          ),
        ),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? '\u041f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0430 \u043e\u0442\u043c\u0435\u0447\u0435\u043d\u0430 \u043a\u0430\u043a \u0433\u043e\u0442\u043e\u0432\u0430\u044f.'
              : '\u041f\u043e\u0434\u0437\u0430\u0434\u0430\u0447\u0430 \u0441\u043d\u043e\u0432\u0430 \u0430\u043a\u0442\u0438\u0432\u043d\u0430.',
        ),
      ),
    );
  }

  void _showBlockingProgress(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: <Widget>[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: AppTextStyles.subtitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/tasks');
  }
}

class _TaskPageShell extends StatelessWidget {
  const _TaskPageShell({
    required this.title,
    required this.child,
    required this.onBack,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget child;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _HeaderActionButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 20,
                        color: const Color(0xFF70441C),
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty) ...actions,
                ],
              ),
              const SizedBox(height: 18),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskDetailsBody extends StatelessWidget {
  const _TaskDetailsBody({
    required this.task,
    required this.onSplit,
    required this.onStart,
    required this.onComplete,
    required this.onToggleSubtask,
  });

  final TaskWithSubtasks task;
  final Future<void> Function() onSplit;
  final Future<void> Function()? onStart;
  final Future<void> Function()? onComplete;
  final Future<void> Function(Subtask subtask, bool completed) onToggleSubtask;

  @override
  Widget build(BuildContext context) {
    final List<Subtask> subtasks = <Subtask>[...task.subtasks]
      ..sort((Subtask a, Subtask b) => a.orderIndex.compareTo(b.orderIndex));
    final int completedSubtasks = subtasks
        .where((Subtask item) => item.status == SubtaskStatus.completed)
        .length;
    final double progress = subtasks.isEmpty
        ? 0
        : completedSubtasks / subtasks.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TaskHeaderCard(task: task),
          const SizedBox(height: AppSpacing.md),
          _TaskSummaryGrid(task: task),
          const SizedBox(height: AppSpacing.md),
          _ProgressCard(
            task: task,
            completedSubtasks: completedSubtasks,
            totalSubtasks: subtasks.length,
            progress: progress,
            onSplit: onSplit,
          ),
          if (subtasks.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text('Подзадачи', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            ...subtasks.map(
              (Subtask subtask) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SubtaskTile(
                  subtask: subtask,
                  enabled: task.status != TaskStatus.completed,
                  onToggle: (bool completed) =>
                      onToggleSubtask(subtask, completed),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (task.status == TaskStatus.completed)
            const _CompletedTaskBanner()
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onStart == null ? null : () => onStart!(),
                    child: Text(
                      task.status == TaskStatus.inProgress
                          ? 'В процессе'
                          : 'Начать',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: onComplete == null ? null : () => onComplete!(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBrown,
                    ),
                    child: const Text('Завершить'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TaskHeaderCard extends StatelessWidget {
  const _TaskHeaderCard({required this.task});

  final TaskWithSubtasks task;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: task.category.color,
                    borderRadius: AppRadius.card,
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: PixelImage(
                      task.category.iconAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          _Tag(text: task.category.label),
                          _Tag(text: task.priority.label),
                          _StatusTag(task.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(task.title, style: AppTextStyles.title),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DifficultyStars(difficulty: task.difficulty),
              ],
            ),
            if (task.description?.trim().isNotEmpty ?? false) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                task.description!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskSummaryGrid extends StatelessWidget {
  const _TaskSummaryGrid({required this.task});

  final TaskWithSubtasks task;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: 'Дедлайн',
                value: task.deadline == null
                    ? 'Без даты'
                    : DateFormat('dd.MM.yyyy').format(task.deadline!),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Сложность',
                value: task.difficulty.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: 'Награда',
                valueWidget: Row(
                  children: <Widget>[
                    RichText(
                      text: TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${task.xpReward}',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: ' XP',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const PixelImage(
                      AssetPaths.coinSmall,
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.coinsReward}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentBrownDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Создана',
                value: DateFormat('dd.MM.yyyy').format(task.createdAt),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.task,
    required this.completedSubtasks,
    required this.totalSubtasks,
    required this.progress,
    required this.onSplit,
  });

  final TaskWithSubtasks task;
  final int completedSubtasks;
  final int totalSubtasks;
  final double progress;
  final Future<void> Function() onSplit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Прогресс', style: AppTextStyles.subtitle),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    totalSubtasks == 0
                        ? 'Нет подзадач'
                        : '$completedSubtasks / $totalSubtasks',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.card,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentBrown,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              totalSubtasks == 0
                  ? 'Разбей задачу на шаги, чтобы с ней было проще работать каждый день.'
                  : 'Если структура устарела, можно пересобрать список подзадач заново.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onSplit(),
                child: Text(
                  task.subtasks.isEmpty
                      ? 'Собрать подзадачи'
                      : 'Пересобрать подзадачи',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, this.value, this.valueWidget})
    : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 102),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.sm),
              if (valueWidget != null)
                valueWidget!
              else
                Text(value!, style: AppTextStyles.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardMetric extends StatelessWidget {
  const _RewardMetric({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[icon!, const SizedBox(width: 4)],
                Flexible(child: Text(value, style: AppTextStyles.subtitle)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedTaskBanner extends StatelessWidget {
  const _CompletedTaskBanner();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFE2ECD3),
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Задача уже закрыта. Награда начислена, а прогресс сохранен.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStateCard extends StatelessWidget {
  const _TaskStateCard({
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.card,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
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
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentBrown,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDetailsLoadingState extends StatelessWidget {
  const _TaskDetailsLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List<Widget>.generate(
          5,
          (int index) => Padding(
            padding: EdgeInsets.only(bottom: index == 4 ? 0 : AppSpacing.sm),
            child: Container(
              width: double.infinity,
              height: index == 0 ? 180 : 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: AppRadius.card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onPressed,
    this.foregroundColor = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: 48,
        height: 40,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: foregroundColor),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          text,
          style: AppTextStyles.tiny.copyWith(
            color: AppColors.accentBrownDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag(this.status);

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.tintColor,
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          status.label,
          style: AppTextStyles.tiny.copyWith(
            color: status.color,
            fontWeight: FontWeight.w700,
          ),
        ),
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
            width: 12,
            height: 12,
          ),
        );
      }),
    );
  }
}
