import 'package:class_buddy_lite/models/task.dart';
import 'package:class_buddy_lite/providers/task_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggles task completion in provider state', () async {
    final task = Task(id: 'task-1', title: '写完实验报告');
    final provider = TaskProvider.memory([task]);

    await provider.toggleTaskCompletion(task);

    expect(provider.tasks.single.isCompleted, isTrue);
  });
}
