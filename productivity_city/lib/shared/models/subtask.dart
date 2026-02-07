import 'package:productivity_city/shared/models/enums.dart';

class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    this.description,
    this.estimatedTime,
    this.orderIndex = 0,
  });

  final int id;
  final int taskId;
  final String title;
  final String? description;
  final int? estimatedTime;
  final SubtaskStatus status;
  final int orderIndex;

  Subtask copyWith({
    int? id,
    int? taskId,
    String? title,
    String? description,
    int? estimatedTime,
    SubtaskStatus? status,
    int? orderIndex,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'task_id': taskId,
      'title': title,
      'description': description,
      'estimated_time': estimatedTime,
      'status': status.apiValue,
      'order_index': orderIndex,
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as int,
      taskId: json['task_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      estimatedTime: json['estimated_time'] as int?,
      status: SubtaskStatus.fromApi(json['status'] as String),
      orderIndex: (json['order_index'] ?? 0) as int,
    );
  }
}

class SubtaskCreateInput {
  const SubtaskCreateInput({
    required this.title,
    this.description,
    this.estimatedTime,
    this.orderIndex,
  });

  final String title;
  final String? description;
  final int? estimatedTime;
  final int? orderIndex;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'estimated_time': estimatedTime,
      'order_index': orderIndex,
    };
  }
}

class SubtaskUpdateInput {
  const SubtaskUpdateInput({
    this.title,
    this.description,
    this.estimatedTime,
    this.status,
    this.orderIndex,
  });

  final String? title;
  final String? description;
  final int? estimatedTime;
  final SubtaskStatus? status;
  final int? orderIndex;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'estimated_time': estimatedTime,
      'status': status?.apiValue,
      'order_index': orderIndex,
    };
  }
}
