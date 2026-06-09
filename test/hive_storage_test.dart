import 'dart:io';

import 'package:class_buddy_lite/models/hive_adapters.dart';
import 'package:class_buddy_lite/models/task.dart';
import 'package:class_buddy_lite/models/task_enums.dart';
import 'package:class_buddy_lite/models/task_step.dart';
import 'package:class_buddy_lite/models/tree_growth_stage.dart';
import 'package:class_buddy_lite/models/user_record.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('class_buddy_hive_');
    Hive.init(tempDirectory.path);
    registerHiveAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('persists task with nested AI subtasks', () async {
    final box = await Hive.openBox<Task>('task_adapter_test');
    addTearDown(box.deleteFromDisk);

    final task = Task(
      id: 'task-1',
      title: 'Write database report',
      deadline: DateTime(2026, 6, 10, 18),
      type: TaskType.assignment,
      priority: TaskPriority.high,
      notes: 'Focus on ER diagram first.',
      useAiAutoSplit: true,
      isHighPriority: true,
      aiSubtasks: const [
        TaskStep(
          id: 'step-1',
          title: 'Open the doc and write the title',
          order: 1,
          encouragement: 'Start tiny.',
        ),
        TaskStep(
          id: 'step-2',
          title: 'Sketch the ER diagram',
          isCompleted: true,
          order: 2,
        ),
      ],
    );

    await box.put(task.id, task);
    final storedTask = box.get(task.id);

    expect(storedTask, isNotNull);
    expect(storedTask!.title, task.title);
    expect(storedTask.priority, TaskPriority.high);
    expect(storedTask.useAiAutoSplit, isTrue);
    expect(storedTask.isHighPriority, isTrue);
    expect(storedTask.subTasks, hasLength(2));
    expect(storedTask.aiSubtasks, hasLength(2));
    expect(storedTask.subTasks.last.isCompleted, isTrue);
  });

  test('persists user record progress', () async {
    final box = await Hive.openBox<UserRecord>('user_record_adapter_test');
    addTearDown(box.deleteFromDisk);

    final record = UserRecord.initial()
        .checkIn(DateTime(2026, 6, 1), rewardEnergy: 10)
        .addTaskCompletionReward(5)
        .addFocusSession(const Duration(minutes: 25))
        .claimAllClearReward(DateTime(2026, 6, 1), rewardEnergy: 20);

    await box.put('current_user_record', record);
    final storedRecord = box.get('current_user_record');

    expect(storedRecord, isNotNull);
    expect(storedRecord!.energy, 85);
    expect(storedRecord.consecutiveCheckInDays, 1);
    expect(storedRecord.totalCompletedTasks, 2);
    expect(storedRecord.totalAllClearDays, 1);
    expect(storedRecord.totalFocusSeconds, 1500);
  });

  test('calculates tree growth stage with dynamic progress copy', () {
    final record = UserRecord(energy: 40, createdAt: DateTime(2026, 6, 1));
    final stage = record.treeGrowthStage;

    expect(stage, TreeGrowthStage.sprout);
    expect(stage.displayName, '小芽');
    expect(stage.progressForEnergy(record.energy), 0.5);
    expect(stage.encouragementForEnergy(record.energy), contains('40 点能量'));
  });

  test('upgrades tree stage as soon as energy reaches the threshold', () {
    expect(treeGrowthStageFromEnergy(29), TreeGrowthStage.seed);
    expect(treeGrowthStageFromEnergy(30), TreeGrowthStage.sprout);
    expect(treeGrowthStageFromEnergy(80), TreeGrowthStage.sapling);
  });
}
