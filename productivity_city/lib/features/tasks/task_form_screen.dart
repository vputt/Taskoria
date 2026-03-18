import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key, this.taskId, this.isEditing = false});

  final String? taskId;
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isEditing) {
      return const _TaskFormView();
    }

    final int? parsedTaskId = int.tryParse(taskId ?? '');
    if (parsedTaskId == null) {
      return const _TaskFormScaffold(
        title: 'Редактирование',
        child: _TaskFormStateCard(
          title: 'Не удалось открыть форму',
          description: 'Передан некорректный идентификатор задачи.',
        ),
      );
    }

    final AsyncValue<TaskWithSubtasks> taskAsync = ref.watch(
      taskDetailProvider(parsedTaskId),
    );

    return _TaskFormScaffold(
      title: 'Редактирование',
      child: taskAsync.when(
        loading: () => const _TaskFormLoadingState(),
        error: (Object error, StackTrace stackTrace) => _TaskFormStateCard(
          title: 'Не удалось загрузить задачу',
          description: 'Попробуй еще раз, чтобы открыть форму редактирования.',
          actionLabel: 'Повторить',
          onAction: () => ref.invalidate(taskDetailProvider(parsedTaskId)),
        ),
        data: (TaskWithSubtasks task) => _TaskFormView(
          taskId: parsedTaskId,
          initialTask: task,
          isEditing: true,
          showScaffold: false,
        ),
      ),
    );
  }
}

class _TaskFormView extends ConsumerStatefulWidget {
  const _TaskFormView({
    this.taskId,
    this.initialTask,
    this.isEditing = false,
    this.showScaffold = true,
  });

  final int? taskId;
  final TaskWithSubtasks? initialTask;
  final bool isEditing;
  final bool showScaffold;

  @override
  ConsumerState<_TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends ConsumerState<_TaskFormView> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskCategory _category;
  late TaskPriority _priority;
  late TaskDifficulty _difficulty;
  DateTime? _deadline;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final TaskWithSubtasks? task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _category = task?.category ?? TaskCategory.study;
    _priority = task?.priority ?? TaskPriority.medium;
    _difficulty = task?.difficulty ?? TaskDifficulty.medium;
    _deadline = task?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit =
        !_isSaving && _titleController.text.trim().isNotEmpty;

    final Widget content = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Название задачи*'),
          const SizedBox(height: 10),
          _TextInput(
            controller: _titleController,
            hintText: 'Коротко опиши задачу в 2-5 словах',
            maxLines: 1,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Описание'),
          const SizedBox(height: 10),
          _TextInput(
            controller: _descriptionController,
            hintText:
                'Что именно нужно сделать и какой результат ты считаешь готовым?',
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Приоритет'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _ChoiceTile(
                  label: 'Низкий',
                  stars: 1,
                  selected: _priority == TaskPriority.low,
                  onTap: () => setState(() => _priority = TaskPriority.low),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceTile(
                  label: 'Средний',
                  stars: 2,
                  selected: _priority == TaskPriority.medium,
                  onTap: () => setState(() => _priority = TaskPriority.medium),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceTile(
                  label: 'Высокий',
                  stars: 3,
                  selected: _priority == TaskPriority.high,
                  onTap: () => setState(() => _priority = TaskPriority.high),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Категория'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
            children: <Widget>[
              _CategoryTile(
                label: 'Учеба',
                iconAsset: AssetPaths.categoryStudy,
                selected: _category == TaskCategory.study,
                onTap: () => setState(() => _category = TaskCategory.study),
              ),
              _CategoryTile(
                label: 'Работа',
                iconAsset: AssetPaths.categoryWork,
                selected: _category == TaskCategory.work,
                onTap: () => setState(() => _category = TaskCategory.work),
              ),
              _CategoryTile(
                label: 'Здоровье',
                iconAsset: AssetPaths.categoryHealth,
                selected: _category == TaskCategory.health,
                onTap: () => setState(() => _category = TaskCategory.health),
              ),
              _CategoryTile(
                label: 'Личное',
                iconAsset: AssetPaths.categoryPersonal,
                selected: _category == TaskCategory.personal,
                onTap: () => setState(() => _category = TaskCategory.personal),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Сложность'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _ChoiceTile(
                  label: 'Низкая',
                  stars: 1,
                  selected: _difficulty == TaskDifficulty.easy,
                  onTap: () =>
                      setState(() => _difficulty = TaskDifficulty.easy),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceTile(
                  label: 'Средняя',
                  stars: 2,
                  selected: _difficulty == TaskDifficulty.medium,
                  onTap: () =>
                      setState(() => _difficulty = TaskDifficulty.medium),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceTile(
                  label: 'Высокая',
                  stars: 3,
                  selected: _difficulty == TaskDifficulty.hard,
                  onTap: () =>
                      setState(() => _difficulty = TaskDifficulty.hard),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Дедлайн'),
          const SizedBox(height: 10),
          _DeadlineField(
            value: _deadline == null
                ? 'ДД.ММ.ГГГГ'
                : DateFormat('dd.MM.yyyy').format(_deadline!),
            isPlaceholder: _deadline == null,
            onTap: _pickDeadline,
          ),
          if (_deadline != null) ...<Widget>[
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => setState(() => _deadline = null),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.accentBrownDark,
              ),
              child: Text(
                'Сбросить дату',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentBrown,
                disabledBackgroundColor: AppColors.accentBrown.withValues(
                  alpha: 0.45,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditing
                          ? 'Сохранить изменения'
                          : 'Создать задачу',
                      style: AppTextStyles.button.copyWith(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );

    if (!widget.showScaffold) {
      return content;
    }

    return _TaskFormScaffold(
      title: widget.isEditing ? 'Редактирование' : 'Новая задача',
      child: content,
    );
  }

  Future<void> _pickDeadline() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _deadline ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Добавь название задачи.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing && widget.taskId != null) {
        final Task updated = await ref
            .read(tasksProvider.notifier)
            .updateTask(
              widget.taskId!,
              TaskUpdateInput(
                title: title,
                description: _normalizedDescription,
                category: _category,
                priority: _priority,
                difficulty: _difficulty,
                deadline: _deadline,
                clearDeadline: _deadline == null,
              ),
            );
        if (!mounted) {
          return;
        }
        context.go('/tasks/${updated.id}');
      } else {
        final Task task = await ref
            .read(tasksProvider.notifier)
            .createTask(
              TaskCreateInput(
                title: title,
                description: _normalizedDescription,
                category: _category,
                priority: _priority,
                difficulty: _difficulty,
                deadline: _deadline,
              ),
            );
        if (!mounted) {
          return;
        }
        context.go('/tasks/${task.id}');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
    }
  }

  String? get _normalizedDescription {
    final String value = _descriptionController.text.trim();
    return value.isEmpty ? null : value;
  }
}

class _TaskFormScaffold extends StatelessWidget {
  const _TaskFormScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

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
                  DecoratedBox(
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
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                            return;
                          }
                          context.go('/tasks');
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: Color(0xFF8C603A),
                        ),
                      ),
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.body.copyWith(
        fontSize: 16,
        color: const Color(0xFF7A5432),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hintText,
    required this.maxLines,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(
        fontSize: 16,
        color: const Color(0xFF5E3718),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(
          fontSize: 15,
          color: const Color(0xFFC8BCB4),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: Color(0xFFA88B66), width: 0.9),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: Color(0xFFA16437), width: 1.1),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.stars,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int stars;
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
          height: 76,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1D3A8) : const Color(0xFFE7D8CC),
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? const Color(0xFFC89B5B) : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(3, (int index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: PixelImage(
                        index < stars
                            ? AssetPaths.starFilled
                            : AssetPaths.starEmpty,
                        width: 25,
                        height: 25,
                      ),
                    );
                  }),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF70441C),
                    fontWeight: FontWeight.w800,
                    height: 1,
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFF1D3A8)
                  : const Color(0xFFEAD8C8),
              borderRadius: AppRadius.card,
              border: Border.all(
                color: selected ? const Color(0xFFC89B5B) : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  PixelImage(iconAsset, width: 34, height: 34),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF70441C),
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
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

class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.input,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.input,
            border: Border.all(color: const Color(0xFFA88B66), width: 0.9),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      color: isPlaceholder
                          ? const Color(0xFFC8BCB4)
                          : const Color(0xFF5E3718),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const PixelImage(AssetPaths.navCalendar, width: 22, height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskFormStateCard extends StatelessWidget {
  const _TaskFormStateCard({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                blurRadius: 24,
                offset: Offset(0, 10),
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
                if (actionLabel != null && onAction != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBrown,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskFormLoadingState extends StatelessWidget {
  const _TaskFormLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: List<Widget>.generate(
        6,
        (int index) => Padding(
          padding: EdgeInsets.only(bottom: index == 5 ? 0 : 14),
          child: Container(
            width: double.infinity,
            height: index == 1 ? 110 : 82,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: AppRadius.card,
            ),
          ),
        ),
      ),
    );
  }
}
