import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/features/tasks/task_ui.dart';
import 'package:productivity_city/features/tasks/widgets/task_card.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  bool _alignedWithTasks = false;

  static const List<String> _monthNames = <String>[
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  static const List<String> _dayNames = <String>[
    'Вс',
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
  ];

  @override
  void initState() {
    super.initState();
    final DateTime today = _stripTime(DateTime.now());
    _selectedDate = today;
    _currentMonth = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Task>> tasksAsync = ref.watch(tasksProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        bottom: false,
        child: tasksAsync.when(
          loading: _buildLoadingState,
          error: (Object error, StackTrace stackTrace) => _CalendarStateCard(
            title: 'Не удалось загрузить календарь',
            description:
                'Попробуй обновить данные. Я заново соберу дедлайны и задачи по дням.',
            actionLabel: 'Повторить',
            onAction: () => ref.invalidate(tasksProvider),
          ),
          data: (List<Task> tasks) => _buildDataState(context, tasks),
        ),
      ),
    );
  }

  Widget _buildDataState(BuildContext context, List<Task> tasks) {
    _alignInitialSelection(tasks);

    final List<Task> selectedTasks = _tasksForDate(tasks, _selectedDate);
    final int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final int firstDayOffset =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final int cellCount = firstDayOffset + daysInMonth;
    final int totalCells = cellCount + ((7 - (cellCount % 7)) % 7);

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
          Text('Календарь', style: AppTextStyles.display),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Здесь видно дедлайны и весь план по дням.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _MonthNavButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month - 1,
                          );
                        }),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                            style: AppTextStyles.subtitle,
                          ),
                        ),
                      ),
                      _MonthNavButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month + 1,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: _dayNames
                        .map(
                          (String label) => Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(label, style: AppTextStyles.tiny),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalCells,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.94,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      final int dayNumber = index - firstDayOffset + 1;
                      if (index < firstDayOffset || dayNumber > daysInMonth) {
                        return const SizedBox.shrink();
                      }

                      final DateTime day = DateTime(
                        _currentMonth.year,
                        _currentMonth.month,
                        dayNumber,
                      );
                      final bool isSelected = _isSameDay(day, _selectedDate);
                      final bool isToday = _isSameDay(
                        day,
                        _stripTime(DateTime.now()),
                      );
                      final List<Task> dayTasks = _tasksForDate(tasks, day);

                      return _DayCell(
                        dayNumber: dayNumber,
                        isSelected: isSelected,
                        isToday: isToday,
                        tasks: dayTasks,
                        onTap: () => setState(() => _selectedDate = day),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Задачи на ${_formatHumanDate(_selectedDate)}',
                  style: AppTextStyles.title,
                ),
              ),
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
                    '${selectedTasks.length}',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.accentBrownDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selectedTasks.isEmpty)
            _CalendarEmptyState(
              onCreateTask: () => context.push('/tasks/create'),
            )
          else
            ...selectedTasks.map(
              (Task task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(
                  task: task,
                  onTap: () => context.push('/tasks/${task.id}'),
                  onComplete:
                      task.status == TaskStatus.completed ||
                          task.status == TaskStatus.cancelled
                      ? null
                      : () => _handleTaskCompletion(context, task.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      child: Column(
        children: List<Widget>.generate(
          4,
          (int index) => Padding(
            padding: EdgeInsets.only(bottom: index == 3 ? 0 : AppSpacing.md),
            child: Container(
              width: double.infinity,
              height: index == 0 ? 80 : (index == 1 ? 360 : 140),
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

  Future<void> _handleTaskCompletion(BuildContext context, int taskId) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      final TaskCompleteResult result = await ref
          .read(tasksProvider.notifier)
          .completeTask(taskId);
      if (!mounted) {
        return;
      }
      unawaited(ref.read(userProvider.notifier).refresh());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '+${result.xpEarned} XP и ${result.coinsEarned} монет начислены',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Не удалось завершить задачу. Попробуй еще раз.'),
        ),
      );
    }
  }

  void _alignInitialSelection(List<Task> tasks) {
    if (_alignedWithTasks) {
      return;
    }

    final List<Task> datedTasks =
        tasks
            .where((Task task) => task.deadline != null)
            .toList(growable: false)
          ..sort((Task a, Task b) => a.deadline!.compareTo(b.deadline!));
    _alignedWithTasks = true;

    if (datedTasks.isEmpty) {
      return;
    }

    final DateTime target = _stripTime(datedTasks.first.deadline!);
    if (_isSameDay(target, _selectedDate)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedDate = target;
        _currentMonth = DateTime(target.year, target.month);
      });
    });
  }

  List<Task> _tasksForDate(List<Task> tasks, DateTime date) {
    final DateTime normalized = _stripTime(date);
    final List<Task> items = tasks
        .where((Task task) {
          if (task.deadline == null) {
            return false;
          }
          return _isSameDay(task.deadline!, normalized);
        })
        .toList(growable: false);

    items.sort((Task a, Task b) {
      final DateTime first = a.deadline ?? a.updatedAt;
      final DateTime second = b.deadline ?? b.updatedAt;
      return first.compareTo(second);
    });

    return items;
  }

  String _formatHumanDate(DateTime value) {
    return '${value.day} ${_monthNames[value.month - 1].toLowerCase()}';
  }

  DateTime _stripTime(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.textPrimary),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.isSelected,
    required this.isToday,
    required this.tasks,
    required this.onTap,
  });

  final int dayNumber;
  final bool isSelected;
  final bool isToday;
  final List<Task> tasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasMarkers = tasks.isNotEmpty;
    final Color backgroundColor = isSelected
        ? AppColors.accentOliveDark
        : isToday
        ? AppColors.surfaceSecondary
        : AppColors.surfacePrimary;
    final Color foregroundColor = isSelected
        ? AppColors.textOnDark
        : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double availableHeight = constraints.maxHeight;
            final double verticalPadding = availableHeight < 38 ? 2 : 4;
            final double numberFontSize = availableHeight < 38 ? 12 : 14;
            final double dotSize = availableHeight < 38 ? 4 : 6;
            final double gap = availableHeight < 38 ? 1 : 3;

            return Ink(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: AppRadius.card,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentOliveDark
                      : AppColors.borderSoft,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: 4,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$dayNumber',
                        style: AppTextStyles.body.copyWith(
                          fontSize: numberFontSize,
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (hasMarkers) ...<Widget>[
                      SizedBox(height: gap),
                      SizedBox(
                        height: dotSize,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: tasks
                              .take(3)
                              .map(
                                (Task task) => Container(
                                  width: dotSize,
                                  height: dotSize,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.textOnDark
                                        : task.category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  const _CalendarEmptyState({required this.onCreateTask});

  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            Image.asset(
              AssetPaths.emptyState,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('На эту дату задач нет', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Можно выбрать другой день или сразу добавить новую задачу.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onCreateTask,
              child: const Text('Создать задачу'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarStateCard extends StatelessWidget {
  const _CalendarStateCard({
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
