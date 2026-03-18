import 'package:flutter/material.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/features/tasks/task_ui.dart';
import 'package:productivity_city/shared/models/models.dart';

class SubtaskTile extends StatelessWidget {
  const SubtaskTile({
    required this.subtask,
    this.onToggle,
    this.enabled = true,
    super.key,
  });

  final Subtask subtask;
  final ValueChanged<bool>? onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = subtask.status == SubtaskStatus.completed;
    final bool interactive = enabled && onToggle != null && !isCompleted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.surfaceSoft
            : AppColors.surfacePrimary.withValues(alpha: 0.92),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isCompleted ? AppColors.accentOlive : AppColors.borderSoft,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: interactive ? () => onToggle?.call(!isCompleted) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Checkbox(
                    value: isCompleted,
                    onChanged: interactive
                        ? (bool? value) => onToggle?.call(value ?? false)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        subtask.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (subtask.description?.trim().isNotEmpty ??
                          false) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtask.description!,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: subtask.status.tintColor,
                        borderRadius: AppRadius.chip,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 4,
                        ),
                        child: Text(
                          subtask.status.label,
                          style: AppTextStyles.tiny.copyWith(
                            color: subtask.status.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (subtask.estimatedTime != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        '${subtask.estimatedTime} мин',
                        style: AppTextStyles.tiny,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
