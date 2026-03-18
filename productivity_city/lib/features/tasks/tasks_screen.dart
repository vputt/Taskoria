import 'dart:async';
import 'dart:math' as math;

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
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

enum _TaskTab { active, completed }

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _TaskTab _selectedTab = _TaskTab.active;
  _TaskFilterData _filters = const _TaskFilterData();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Task>> tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const PixelImage(AssetPaths.onboarding1, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: tasksAsync.when(
              loading: _buildLoadingState,
              error: (Object error, StackTrace stackTrace) => _TasksErrorState(
                onRetry: () => ref.invalidate(tasksProvider),
              ),
              data: (List<Task> tasks) => _buildDataState(context, tasks),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataState(BuildContext context, List<Task> tasks) {
    final List<Task> filteredTasks = _filterTasks(tasks);
    final List<_TaskSectionData> sections = _buildSections(filteredTasks);
    final double chromeScale = _chromeScale(context);
    final double searchHeight = 35 * chromeScale;
    final double filterSize = 35 * chromeScale;
    final BorderRadius chromeRadius = BorderRadius.circular(10 * chromeScale);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: searchHeight,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SearchField(
                    height: searchHeight,
                    borderRadius: chromeRadius,
                    controller: _searchController,
                    onChanged: (String value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  active: _filters.hasActiveFilters,
                  count: _filters.activeCount,
                  size: filterSize,
                  iconWidth: 18 * chromeScale,
                  iconHeight: 16 * chromeScale,
                  borderRadius: chromeRadius,
                  onTap: () => _openFilterSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _TaskTabs(
            selectedTab: _selectedTab,
            onSelected: (_TaskTab tab) => setState(() => _selectedTab = tab),
          ),
          if (_filters.hasActiveFilters) ...<Widget>[
            const SizedBox(height: 12),
            _ActiveFiltersBar(
              filters: _filters,
              onClear: () => setState(() => _filters = const _TaskFilterData()),
            ),
          ],
          const SizedBox(height: 18),
          if (sections.isEmpty)
            _TasksEmptyState(
              onCreateTask: () => context.push('/tasks/create'),
              hasFilters:
                  _filters.hasActiveFilters || _searchQuery.trim().isNotEmpty,
              onClearFilters: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _filters = const _TaskFilterData();
                });
              },
            )
          else
            ...sections.expand(
              (_TaskSectionData section) => <Widget>[
                Text(
                  section.title,
                  style: AppTextStyles.title.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                ...section.tasks.map(
                  (Task task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: task,
                      onTap: () => context.push('/tasks/${task.id}'),
                      onComplete: _selectedTab == _TaskTab.active
                          ? () => _handleTaskCompletion(context, task.id)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }

  double _chromeScale(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    return math
        .min(screenSize.width / 414, screenSize.height / 917)
        .clamp(0.9, 1.06)
        .toDouble();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    final DateTime today = DateTime.now();
    final DateTime startOfToday = DateTime(today.year, today.month, today.day);

    final Iterable<Task> scoped = tasks.where((Task task) {
      final bool matchesTab = _selectedTab == _TaskTab.active
          ? task.status != TaskStatus.completed &&
                task.status != TaskStatus.cancelled
          : task.status == TaskStatus.completed;
      final bool matchesSearch = _searchQuery.trim().isEmpty
          ? true
          : task.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final bool matchesCategory =
          _filters.category == null || task.category == _filters.category;
      final bool matchesPriority =
          _filters.priority == null || task.priority == _filters.priority;
      final bool matchesDifficulty =
          _filters.difficulty == null || task.difficulty == _filters.difficulty;
      final bool matchesOverdue = !_filters.overdueOnly
          ? true
          : task.deadline != null &&
                task.status != TaskStatus.completed &&
                DateTime(
                  task.deadline!.year,
                  task.deadline!.month,
                  task.deadline!.day,
                ).isBefore(startOfToday);

      return matchesTab &&
          matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesDifficulty &&
          matchesOverdue;
    });

    final List<Task> sorted = scoped.toList()
      ..sort((Task a, Task b) {
        final DateTime first = a.deadline ?? a.updatedAt;
        final DateTime second = b.deadline ?? b.updatedAt;
        return first.compareTo(second);
      });

    return sorted;
  }

  List<_TaskSectionData> _buildSections(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const <_TaskSectionData>[];
    }

    if (_selectedTab == _TaskTab.completed) {
      return <_TaskSectionData>[
        _TaskSectionData(title: 'Выполненные', tasks: tasks),
      ];
    }

    final DateTime today = DateTime.now();
    final DateTime startOfToday = DateTime(today.year, today.month, today.day);
    final List<Task> todayTasks = <Task>[];
    final List<Task> nextWeekTasks = <Task>[];

    for (final Task task in tasks) {
      final DateTime date = task.deadline ?? task.updatedAt;
      final int difference = date.difference(startOfToday).inDays;

      if (difference <= 0) {
        todayTasks.add(task);
      } else {
        nextWeekTasks.add(task);
      }
    }

    return <_TaskSectionData>[
      if (todayTasks.isNotEmpty)
        _TaskSectionData(title: 'Сегодня', tasks: todayTasks),
      if (nextWeekTasks.isNotEmpty)
        _TaskSectionData(title: '7 дней', tasks: nextWeekTasks),
    ];
  }

  Widget _buildLoadingState() {
    final double chromeScale = _chromeScale(context);
    final double searchHeight = 35 * chromeScale;
    final double filterSize = 35 * chromeScale;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: searchHeight,
            child: Row(
              children: <Widget>[
                Expanded(child: _SkeletonLine(height: searchHeight)),
                const SizedBox(width: 8),
                _SkeletonLine(width: filterSize, height: filterSize),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SkeletonLine(height: 50),
          const SizedBox(height: 18),
          ...List<Widget>.generate(
            4,
            (int index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _SkeletonLine(height: 146),
            ),
          ),
        ],
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
    }
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final _TaskFilterData? result = await showModalBottomSheet<_TaskFilterData>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _TaskFilterSheet(initialValue: _filters);
      },
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() => _filters = result);
  }
}

class _TaskSectionData {
  const _TaskSectionData({required this.title, required this.tasks});

  final String title;
  final List<Task> tasks;
}

class _TaskFilterData {
  const _TaskFilterData({
    this.category,
    this.priority,
    this.difficulty,
    this.overdueOnly = false,
  });

  final TaskCategory? category;
  final TaskPriority? priority;
  final TaskDifficulty? difficulty;
  final bool overdueOnly;

  bool get hasActiveFilters =>
      category != null || priority != null || difficulty != null || overdueOnly;

  int get activeCount {
    int count = 0;
    if (category != null) {
      count++;
    }
    if (priority != null) {
      count++;
    }
    if (difficulty != null) {
      count++;
    }
    if (overdueOnly) {
      count++;
    }
    return count;
  }

  _TaskFilterData copyWith({
    TaskCategory? category,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    bool? overdueOnly,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearDifficulty = false,
  }) {
    return _TaskFilterData(
      category: clearCategory ? null : (category ?? this.category),
      priority: clearPriority ? null : (priority ?? this.priority),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      overdueOnly: overdueOnly ?? this.overdueOnly,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.height,
    required this.borderRadius,
    required this.controller,
    required this.onChanged,
  });

  final double height;
  final BorderRadius borderRadius;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final double iconSize = height * 0.6;
    final double iconInset = ((height - iconSize) / 2).clamp(4, 8).toDouble();

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          boxShadow: AppTheme.softShadow,
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accentBrownDark,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Поиск задач',
            prefixIcon: Padding(
              padding: EdgeInsets.all(iconInset),
              child: PixelImage(
                AssetPaths.search,
                width: iconSize,
                height: iconSize,
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: height,
              minHeight: height,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: math.max(8, height * 0.36),
              vertical: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.active,
    required this.count,
    required this.size,
    required this.iconWidth,
    required this.iconHeight,
    required this.borderRadius,
    required this.onTap,
  });

  final bool active;
  final int count;
  final double size;
  final double iconWidth;
  final double iconHeight;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: active ? const Color(0xFFF8EAD5) : Colors.white,
                borderRadius: borderRadius,
                boxShadow: AppTheme.softShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: math.max(6, size * 0.2),
                      vertical: math.max(6, size * 0.22),
                    ),
                    child: PixelImage(
                      AssetPaths.filter,
                      width: iconWidth,
                      height: iconHeight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (active)
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
                  '$count',
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

class _TaskTabs extends StatelessWidget {
  const _TaskTabs({required this.selectedTab, required this.onSelected});

  final _TaskTab selectedTab;
  final ValueChanged<_TaskTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.card,
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _TaskTabButton(
                  label: 'Активные',
                  selected: selectedTab == _TaskTab.active,
                  onTap: () => onSelected(_TaskTab.active),
                ),
              ),
              Expanded(
                child: _TaskTabButton(
                  label: 'Выполнены',
                  selected: selectedTab == _TaskTab.completed,
                  onTap: () => onSelected(_TaskTab.completed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTabButton extends StatelessWidget {
  const _TaskTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
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
            color: selected ? const Color(0xFFF1DFC5) : Colors.transparent,
            borderRadius: AppRadius.card,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF6F431D),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({required this.filters, required this.onClear});

  final _TaskFilterData filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      if (filters.category != null) filters.category!.label,
      if (filters.priority != null) filters.priority!.label,
      if (filters.difficulty != null) filters.difficulty!.label,
      if (filters.overdueOnly) 'Просроченные',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ...labels.map(
          (String label) => DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF7EBDD),
              borderRadius: AppRadius.chip,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF8B7058),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Сбросить',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TasksEmptyState extends StatelessWidget {
  const _TasksEmptyState({
    required this.onCreateTask,
    required this.hasFilters,
    required this.onClearFilters,
  });

  final VoidCallback onCreateTask;
  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            const PixelImage(
              AssetPaths.categoryPersonal,
              width: 64,
              height: 64,
            ),
            const SizedBox(height: 10),
            Text(
              hasFilters ? 'Ничего не найдено' : 'Пока здесь пусто',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Попробуй ослабить фильтры или сбросить поиск, чтобы вернуть задачи в список.'
                  : 'Создай первую задачу и начни развивать город.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: hasFilters ? onClearFilters : onCreateTask,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentBrown,
                ),
                child: Text(hasFilters ? 'Сбросить фильтры' : 'Создать задачу'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksErrorState extends StatelessWidget {
  const _TasksErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.card,
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Не удалось загрузить задачи',
                    style: AppTextStyles.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Повтори загрузку, и список появится снова.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBrown,
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskFilterSheet extends StatefulWidget {
  const _TaskFilterSheet({required this.initialValue});

  final _TaskFilterData initialValue;

  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  late _TaskFilterData _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(child: Text('Фильтры', style: AppTextStyles.title)),
                  TextButton(
                    onPressed: () =>
                        setState(() => _draft = const _TaskFilterData()),
                    child: Text(
                      'Сбросить',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentBrownDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _FilterSection<TaskCategory>(
                title: 'Категория',
                selected: _draft.category,
                options: TaskCategory.values,
                labelBuilder: (TaskCategory item) => item.label,
                onSelected: (TaskCategory? value) {
                  setState(() {
                    _draft = _draft.copyWith(
                      category: value,
                      clearCategory: value == null,
                    );
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterSection<TaskPriority>(
                title: 'Приоритет',
                selected: _draft.priority,
                options: TaskPriority.values,
                singleLine: true,
                labelBuilder: (TaskPriority item) => item.label,
                onSelected: (TaskPriority? value) {
                  setState(() {
                    _draft = _draft.copyWith(
                      priority: value,
                      clearPriority: value == null,
                    );
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterSection<TaskDifficulty>(
                title: 'Сложность',
                selected: _draft.difficulty,
                options: TaskDifficulty.values,
                singleLine: true,
                labelBuilder: (TaskDifficulty item) => item.label,
                onSelected: (TaskDifficulty? value) {
                  setState(() {
                    _draft = _draft.copyWith(
                      difficulty: value,
                      clearDifficulty: value == null,
                    );
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile.adaptive(
                value: _draft.overdueOnly,
                onChanged: (bool value) {
                  setState(() {
                    _draft = _draft.copyWith(overdueOnly: value);
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.accentOliveDark,
                title: Text(
                  'Только просроченные',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Показывать задачи с дедлайном раньше сегодняшнего дня.',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_draft),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentBrown,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
    this.singleLine = false,
  });

  final String title;
  final T? selected;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onSelected;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      _FilterChip(
        label: 'Все',
        selected: selected == null,
        onTap: () => onSelected(null),
      ),
      ...options.map(
        (T item) => _FilterChip(
          label: labelBuilder(item),
          selected: selected == item,
          onTap: () => onSelected(item),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.sm),
        if (singleLine)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          )
        else
          Wrap(spacing: 0, runSpacing: 0, children: chips),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: AppTextStyles.tiny.copyWith(
            color: const Color(0xFF6F431D),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: true,
        checkmarkColor: const Color(0xFF6F431D),
        selectedColor: const Color(0xFFF1DFC5),
        backgroundColor: const Color(0xFFF7EBDD),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
        labelPadding: const EdgeInsets.symmetric(horizontal: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width = double.infinity, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: AppRadius.card,
      ),
    );
  }
}
