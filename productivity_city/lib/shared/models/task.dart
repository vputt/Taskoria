import 'package:productivity_city/shared/models/enums.dart';
import 'package:productivity_city/shared/models/subtask.dart';

class Task {
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.difficulty,
    required this.xpReward,
    required this.coinsReward,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.deadline,
    this.completedAt,
  });

  final int id;
  final int userId;
  final String title;
  final String? description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime? deadline;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final int xpReward;
  final int coinsReward;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? deadline,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    int? xpReward,
    int? coinsReward,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      coinsReward: coinsReward ?? this.coinsReward,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category.apiValue,
      'priority': priority.apiValue,
      'deadline': deadline?.toIso8601String(),
      'status': status.apiValue,
      'difficulty': difficulty.apiValue,
      'xp_reward': xpReward,
      'coins_reward': coinsReward,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: TaskCategory.fromApi(json['category'] as String),
      priority: TaskPriority.fromApi(json['priority'] as String),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      status: TaskStatus.fromApi(json['status'] as String),
      difficulty: TaskDifficulty.fromApi(json['difficulty'] as String),
      xpReward: json['xp_reward'] as int,
      coinsReward: json['coins_reward'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class TaskWithSubtasks extends Task {
  const TaskWithSubtasks({
    required super.id,
    required super.userId,
    required super.title,
    required super.category,
    required super.priority,
    required super.status,
    required super.difficulty,
    required super.xpReward,
    required super.coinsReward,
    required super.createdAt,
    required super.updatedAt,
    required this.subtasks,
    super.description,
    super.deadline,
    super.completedAt,
  });

  final List<Subtask> subtasks;

  Task toTask() {
    return Task(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      priority: priority,
      deadline: deadline,
      status: status,
      difficulty: difficulty,
      xpReward: xpReward,
      coinsReward: coinsReward,
      createdAt: createdAt,
      completedAt: completedAt,
      updatedAt: updatedAt,
    );
  }

  @override
  TaskWithSubtasks copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? deadline,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    int? xpReward,
    int? coinsReward,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    List<Subtask>? subtasks,
  }) {
    return TaskWithSubtasks(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      coinsReward: coinsReward ?? this.coinsReward,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...super.toJson(),
      'subtasks': subtasks
          .map((Subtask item) => item.toJson())
          .toList(growable: false),
    };
  }

  factory TaskWithSubtasks.fromJson(Map<String, dynamic> json) {
    return TaskWithSubtasks(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: TaskCategory.fromApi(json['category'] as String),
      priority: TaskPriority.fromApi(json['priority'] as String),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      status: TaskStatus.fromApi(json['status'] as String),
      difficulty: TaskDifficulty.fromApi(json['difficulty'] as String),
      xpReward: json['xp_reward'] as int,
      coinsReward: json['coins_reward'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      subtasks: ((json['subtasks'] ?? <dynamic>[]) as List<dynamic>)
          .map((dynamic item) => Subtask.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class TaskCreateInput {
  const TaskCreateInput({
    required this.title,
    required this.category,
    required this.priority,
    this.description,
    this.deadline,
    this.difficulty,
  });

  final String title;
  final String? description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime? deadline;
  final TaskDifficulty? difficulty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'category': category.apiValue,
      'priority': priority.apiValue,
      'deadline': deadline?.toIso8601String(),
      'difficulty': difficulty?.apiValue,
    };
  }
}

class TaskUpdateInput {
  const TaskUpdateInput({
    this.title,
    this.description,
    this.category,
    this.priority,
    this.difficulty,
    this.status,
    this.deadline,
    this.clearDeadline = false,
  });

  final String? title;
  final String? description;
  final TaskCategory? category;
  final TaskPriority? priority;
  final TaskDifficulty? difficulty;
  final TaskStatus? status;
  final DateTime? deadline;
  final bool clearDeadline;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'category': category?.apiValue,
      'priority': priority?.apiValue,
      'difficulty': difficulty?.apiValue,
      'status': status?.apiValue,
      'deadline': deadline?.toIso8601String(),
      'clear_deadline': clearDeadline,
    };
  }
}

class TaskCompleteResult {
  const TaskCompleteResult({
    required this.task,
    required this.xpEarned,
    required this.coinsEarned,
    required this.levelUp,
    this.newLevel,
    this.streak,
  });

  final Task task;
  final int xpEarned;
  final int coinsEarned;
  final bool levelUp;
  final int? newLevel;
  final int? streak;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'task': task.toJson(),
      'xp_earned': xpEarned,
      'coins_earned': coinsEarned,
      'level_up': levelUp,
      'new_level': newLevel,
      'streak': streak,
    };
  }

  factory TaskCompleteResult.fromJson(Map<String, dynamic> json) {
    return TaskCompleteResult(
      task: Task.fromJson(json['task'] as Map<String, dynamic>),
      xpEarned: (json['xp_earned'] ?? json['xp_gained']) as int,
      coinsEarned: (json['coins_earned'] ?? json['coins_gained']) as int,
      levelUp: json['level_up'] as bool,
      newLevel: json['new_level'] as int?,
      streak: json['streak'] as int?,
    );
  }
}
