enum TaskCategory {
  study('учеба'),
  work('работа'),
  health('здоровье'),
  personal('личное');

  const TaskCategory(this.apiValue);

  final String apiValue;

  static TaskCategory fromApi(String value) {
    return values.firstWhere(
      (TaskCategory item) => item.apiValue == value,
      orElse: () => TaskCategory.personal,
    );
  }
}

enum TaskPriority {
  low('низкая'),
  medium('средняя'),
  high('высокая');

  const TaskPriority(this.apiValue);

  final String apiValue;

  static TaskPriority fromApi(String value) {
    return values.firstWhere(
      (TaskPriority item) => item.apiValue == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  active('активная'),
  inProgress('в процессе'),
  completed('выполнена'),
  cancelled('отменена');

  const TaskStatus(this.apiValue);

  final String apiValue;

  static TaskStatus fromApi(String value) {
    return values.firstWhere(
      (TaskStatus item) => item.apiValue == value,
      orElse: () => TaskStatus.active,
    );
  }
}

enum TaskDifficulty {
  easy('легкая'),
  medium('средняя'),
  hard('сложная');

  const TaskDifficulty(this.apiValue);

  final String apiValue;

  static TaskDifficulty fromApi(String value) {
    return values.firstWhere(
      (TaskDifficulty item) => item.apiValue == value,
      orElse: () => TaskDifficulty.medium,
    );
  }
}

enum SubtaskStatus {
  notStarted('не начата'),
  inProgress('в процессе'),
  completed('выполнена');

  const SubtaskStatus(this.apiValue);

  final String apiValue;

  static SubtaskStatus fromApi(String value) {
    return values.firstWhere(
      (SubtaskStatus item) => item.apiValue == value,
      orElse: () => SubtaskStatus.notStarted,
    );
  }
}

enum ShopItemType {
  decoration('decoration'),
  character('character'),
  special('special');

  const ShopItemType(this.apiValue);

  final String apiValue;

  static ShopItemType fromApi(String value) {
    return values.firstWhere(
      (ShopItemType item) => item.apiValue == value,
      orElse: () => ShopItemType.decoration,
    );
  }
}
