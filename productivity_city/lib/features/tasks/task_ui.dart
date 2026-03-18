import 'package:flutter/material.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';

extension TaskCategoryPresentation on TaskCategory {
  String get label {
    switch (this) {
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

  String get shortLabel {
    switch (this) {
      case TaskCategory.study:
        return 'У';
      case TaskCategory.work:
        return 'Р';
      case TaskCategory.health:
        return 'З';
      case TaskCategory.personal:
        return 'Л';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.study:
        return AppColors.categoryStudy;
      case TaskCategory.work:
        return AppColors.categoryWork;
      case TaskCategory.health:
        return AppColors.categoryHealth;
      case TaskCategory.personal:
        return AppColors.categoryPersonal;
    }
  }

  String get iconAsset {
    switch (this) {
      case TaskCategory.study:
        return AssetPaths.categoryStudy;
      case TaskCategory.work:
        return AssetPaths.categoryWork;
      case TaskCategory.health:
        return AssetPaths.categoryHealth;
      case TaskCategory.personal:
        return AssetPaths.categoryPersonal;
    }
  }
}

extension TaskPriorityPresentation on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.high:
        return 'Высокий';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return AppColors.accentOlive;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return AppColors.danger;
    }
  }
}

extension TaskStatusPresentation on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.active:
        return 'Активна';
      case TaskStatus.inProgress:
        return 'В процессе';
      case TaskStatus.completed:
        return 'Выполнена';
      case TaskStatus.cancelled:
        return 'Отменена';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.active:
        return AppColors.accentBrown;
      case TaskStatus.inProgress:
        return AppColors.warning;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.cancelled:
        return AppColors.textMuted;
    }
  }

  Color get tintColor {
    switch (this) {
      case TaskStatus.active:
        return AppColors.surfaceSecondary;
      case TaskStatus.inProgress:
        return const Color(0xFFF7E5C8);
      case TaskStatus.completed:
        return const Color(0xFFE2ECD3);
      case TaskStatus.cancelled:
        return AppColors.surfaceMuted;
    }
  }
}

extension TaskDifficultyPresentation on TaskDifficulty {
  String get label {
    switch (this) {
      case TaskDifficulty.easy:
        return 'Низкая';
      case TaskDifficulty.medium:
        return 'Средняя';
      case TaskDifficulty.hard:
        return 'Высокая';
    }
  }

  int get filledStars {
    switch (this) {
      case TaskDifficulty.easy:
        return 2;
      case TaskDifficulty.medium:
        return 3;
      case TaskDifficulty.hard:
        return 4;
    }
  }
}

extension SubtaskStatusPresentation on SubtaskStatus {
  String get label {
    switch (this) {
      case SubtaskStatus.notStarted:
        return 'Не начато';
      case SubtaskStatus.inProgress:
        return 'В работе';
      case SubtaskStatus.completed:
        return 'Готово';
    }
  }

  Color get color {
    switch (this) {
      case SubtaskStatus.notStarted:
        return AppColors.textSecondary;
      case SubtaskStatus.inProgress:
        return AppColors.warning;
      case SubtaskStatus.completed:
        return AppColors.success;
    }
  }

  Color get tintColor {
    switch (this) {
      case SubtaskStatus.notStarted:
        return AppColors.surfaceSoft;
      case SubtaskStatus.inProgress:
        return const Color(0xFFF7E5C8);
      case SubtaskStatus.completed:
        return const Color(0xFFE2ECD3);
    }
  }
}

int xpRewardForDifficulty(TaskDifficulty difficulty) {
  switch (difficulty) {
    case TaskDifficulty.easy:
      return 60;
    case TaskDifficulty.medium:
      return 120;
    case TaskDifficulty.hard:
      return 180;
  }
}

int coinRewardForDifficulty(TaskDifficulty difficulty) {
  switch (difficulty) {
    case TaskDifficulty.easy:
      return 20;
    case TaskDifficulty.medium:
      return 40;
    case TaskDifficulty.hard:
      return 60;
  }
}
