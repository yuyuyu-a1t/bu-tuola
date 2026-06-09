import 'package:hive/hive.dart';

import 'task_enums.dart';
import 'task_step.dart';

@HiveType(typeId: 3)
class Task {
  Task({
    required this.id,
    required this.title,
    this.deadline,
    this.type = TaskType.other,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.notes = '',
    List<TaskStep> aiSubtasks = const <TaskStep>[],
    List<TaskStep>? subTasks,
    this.useAiAutoSplit = false,
    this.isHighPriority = false,
    DateTime? createdAt,
    this.completedAt,
    DateTime? updatedAt,
  }) : aiSubtasks = List.unmodifiable(subTasks ?? aiSubtasks),
       subTasks = List.unmodifiable(subTasks ?? aiSubtasks),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime? deadline;

  @HiveField(3)
  final TaskType type;

  @HiveField(4)
  final TaskPriority priority;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final String notes;

  @HiveField(7)
  final List<TaskStep> aiSubtasks;

  @HiveField(13)
  final List<TaskStep> subTasks;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final bool useAiAutoSplit;

  @HiveField(12)
  final bool isHighPriority;

  bool get hasAiSubtasks => subTasks.isNotEmpty;

  bool get hasDeadline => deadline != null;

  bool get isOverdue {
    final deadline = this.deadline;
    if (deadline == null || isCompleted) {
      return false;
    }

    return deadline.isBefore(DateTime.now());
  }

  bool get isDueToday => isDueOn(DateTime.now());

  int get energyReward => priority.energyReward;

  double get subtaskProgress {
    if (subTasks.isEmpty) {
      return isCompleted ? 1 : 0;
    }

    final completedCount = subTasks.where((step) => step.isCompleted).length;
    return completedCount / subTasks.length;
  }

  bool isDueOn(DateTime date) {
    final deadline = this.deadline;
    return deadline != null && _isSameDate(deadline, date);
  }

  Task markCompleted({DateTime? completedAt}) {
    final now = DateTime.now();
    return copyWith(
      isCompleted: true,
      completedAt: completedAt ?? now,
      updatedAt: now,
    );
  }

  Task reopen() {
    return copyWith(
      isCompleted: false,
      clearCompletedAt: true,
      updatedAt: DateTime.now(),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    bool clearDeadline = false,
    TaskType? type,
    TaskPriority? priority,
    bool? isCompleted,
    String? notes,
    List<TaskStep>? aiSubtasks,
    List<TaskStep>? subTasks,
    bool? useAiAutoSplit,
    bool? isHighPriority,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) {
    final nextSubTasks = subTasks ?? aiSubtasks ?? this.subTasks;

    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      aiSubtasks: nextSubTasks,
      subTasks: nextSubTasks,
      useAiAutoSplit: useAiAutoSplit ?? this.useAiAutoSplit,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline?.toIso8601String(),
      'type': type.name,
      'priority': priority.name,
      'isCompleted': isCompleted,
      'notes': notes,
      'aiSubtasks': subTasks.map((step) => step.toJson()).toList(),
      'subTasks': subTasks.map((step) => step.toJson()).toList(),
      'useAiAutoSplit': useAiAutoSplit,
      'isHighPriority': isHighPriority,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      deadline: _readDateTime(json['deadline']),
      type: taskTypeFromName(json['type']),
      priority: taskPriorityFromName(json['priority']),
      isCompleted: _readBool(json['isCompleted']),
      notes: json['notes']?.toString() ?? '',
      subTasks: TaskStep.listFromJson(json['subTasks'] ?? json['aiSubtasks']),
      useAiAutoSplit: _readBool(json['useAiAutoSplit']),
      isHighPriority: _readBool(json['isHighPriority']),
      createdAt: _readDateTime(json['createdAt']),
      completedAt: _readDateTime(json['completedAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

DateTime? _readDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return DateTime.tryParse(value.toString());
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }

  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
