import 'package:hive/hive.dart';

import 'task.dart';
import 'task_enums.dart';
import 'task_step.dart';
import 'tree_growth_stage.dart';
import 'user_record.dart';

void registerHiveAdapters() {
  _registerAdapter(TaskTypeAdapter());
  _registerAdapter(TaskPriorityAdapter());
  _registerAdapter(TaskStepAdapter());
  _registerAdapter(TaskAdapter());
  _registerAdapter(UserRecordAdapter());
  _registerAdapter(TreeGrowthStageAdapter());
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 0;

  @override
  TaskType read(BinaryReader reader) {
    return switch (reader.readByte()) {
      0 => TaskType.assignment,
      1 => TaskType.review,
      2 => TaskType.exam,
      3 => TaskType.project,
      4 => TaskType.life,
      _ => TaskType.other,
    };
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    writer.writeByte(obj.index);
  }
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 1;

  @override
  TaskPriority read(BinaryReader reader) {
    return switch (reader.readByte()) {
      0 => TaskPriority.low,
      1 => TaskPriority.medium,
      _ => TaskPriority.high,
    };
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    writer.writeByte(obj.index);
  }
}

class TaskStepAdapter extends TypeAdapter<TaskStep> {
  @override
  final int typeId = 2;

  @override
  TaskStep read(BinaryReader reader) {
    final fields = _readFields(reader);
    return TaskStep(
      id: fields[0] as String? ?? '',
      title: fields[1] as String? ?? '',
      isCompleted: fields[2] as bool? ?? false,
      order: fields[3] as int? ?? 0,
      encouragement: fields[4] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, TaskStep obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.order)
      ..writeByte(4)
      ..write(obj.encouragement);
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 3;

  @override
  Task read(BinaryReader reader) {
    final fields = _readFields(reader);
    final rawSubtasks = fields[13] ?? fields[7];

    return Task(
      id: fields[0] as String? ?? '',
      title: fields[1] as String? ?? '',
      deadline: fields[2] as DateTime?,
      type: fields[3] as TaskType? ?? TaskType.other,
      priority: fields[4] as TaskPriority? ?? TaskPriority.medium,
      isCompleted: fields[5] as bool? ?? false,
      notes: fields[6] as String? ?? '',
      subTasks: rawSubtasks is Iterable
          ? rawSubtasks.whereType<TaskStep>().toList(growable: false)
          : const <TaskStep>[],
      useAiAutoSplit: fields[11] as bool? ?? false,
      isHighPriority: fields[12] as bool? ?? false,
      createdAt: fields[8] as DateTime?,
      completedAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.deadline)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.subTasks)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.useAiAutoSplit)
      ..writeByte(12)
      ..write(obj.isHighPriority)
      ..writeByte(13)
      ..write(obj.subTasks);
  }
}

class UserRecordAdapter extends TypeAdapter<UserRecord> {
  @override
  final int typeId = 4;

  @override
  UserRecord read(BinaryReader reader) {
    final fields = _readFields(reader);
    return UserRecord(
      energy: fields[0] as int? ?? 0,
      consecutiveCheckInDays: fields[1] as int? ?? 0,
      lastCheckInDate: fields[2] as DateTime?,
      totalCheckInDays: fields[3] as int? ?? 0,
      totalCompletedTasks: fields[4] as int? ?? 0,
      totalAllClearDays: fields[5] as int? ?? 0,
      lastAllClearRewardDate: fields[6] as DateTime?,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
      totalFocusSeconds: fields[9] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, UserRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.energy)
      ..writeByte(1)
      ..write(obj.consecutiveCheckInDays)
      ..writeByte(2)
      ..write(obj.lastCheckInDate)
      ..writeByte(3)
      ..write(obj.totalCheckInDays)
      ..writeByte(4)
      ..write(obj.totalCompletedTasks)
      ..writeByte(5)
      ..write(obj.totalAllClearDays)
      ..writeByte(6)
      ..write(obj.lastAllClearRewardDate)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.totalFocusSeconds);
  }
}

class TreeGrowthStageAdapter extends TypeAdapter<TreeGrowthStage> {
  @override
  final int typeId = 5;

  @override
  TreeGrowthStage read(BinaryReader reader) {
    return switch (reader.readByte()) {
      0 => TreeGrowthStage.seed,
      1 => TreeGrowthStage.sprout,
      2 => TreeGrowthStage.sapling,
      3 => TreeGrowthStage.growingTree,
      _ => TreeGrowthStage.flourishingTree,
    };
  }

  @override
  void write(BinaryWriter writer, TreeGrowthStage obj) {
    writer.writeByte(obj.index);
  }
}

Map<int, dynamic> _readFields(BinaryReader reader) {
  final fieldCount = reader.readByte();
  return <int, dynamic>{
    for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
  };
}
