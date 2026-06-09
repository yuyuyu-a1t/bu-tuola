import 'package:hive/hive.dart';

@HiveType(typeId: 0)
enum TaskType {
  @HiveField(0)
  assignment,

  @HiveField(1)
  review,

  @HiveField(2)
  exam,

  @HiveField(3)
  project,

  @HiveField(4)
  life,

  @HiveField(5)
  other,
}

@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low,

  @HiveField(1)
  medium,

  @HiveField(2)
  high,
}

TaskType taskTypeFromName(Object? value) {
  final name = value?.toString();
  return TaskType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => TaskType.other,
  );
}

TaskPriority taskPriorityFromName(Object? value) {
  final name = value?.toString();
  return TaskPriority.values.firstWhere(
    (priority) => priority.name == name,
    orElse: () => TaskPriority.medium,
  );
}

extension TaskTypeInfo on TaskType {
  String get displayName {
    return switch (this) {
      TaskType.assignment => 'Assignment',
      TaskType.review => 'Review',
      TaskType.exam => 'Exam',
      TaskType.project => 'Project',
      TaskType.life => 'Life',
      TaskType.other => 'Other',
    };
  }
}

extension TaskPriorityInfo on TaskPriority {
  int get energyReward {
    return switch (this) {
      TaskPriority.low => 3,
      TaskPriority.medium => 5,
      TaskPriority.high => 10,
    };
  }

  String get displayName {
    return switch (this) {
      TaskPriority.low => 'Low',
      TaskPriority.medium => 'Medium',
      TaskPriority.high => 'High',
    };
  }
}
