import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/task.dart';
import '../services/storage_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(StorageService storageService)
    : _storageService = storageService,
      _tasksListenable = storageService.tasksListenable {
    _tasks = storageService.getAllTasks();
    _tasksListenable?.addListener(_refreshTasksFromStorage);
  }

  TaskProvider.memory([List<Task> initialTasks = const <Task>[]])
    : _storageService = null,
      _tasksListenable = null,
      _tasks = List<Task>.from(initialTasks);

  final StorageService? _storageService;
  final ValueListenable<Box<Task>>? _tasksListenable;
  late List<Task> _tasks;

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get todayTasks {
    return _tasks.where((task) => task.isDueToday).toList(growable: false);
  }

  List<Task> get pendingTasks {
    return _tasks.where((task) => !task.isCompleted).toList(growable: false);
  }

  List<Task> get completedTasks {
    return _tasks.where((task) => task.isCompleted).toList(growable: false);
  }

  Future<void> addTask(Task task) async {
    _tasks = [
      for (final item in _tasks)
        if (item.id != task.id) item,
      task,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();

    final storageService = _storageService;
    if (storageService != null) {
      await storageService.saveTask(task);
    }
  }

  Future<void> updateTask(Task task) async {
    _tasks = [
      for (final item in _tasks)
        if (item.id == task.id) task else item,
    ];
    notifyListeners();

    final storageService = _storageService;
    if (storageService != null) {
      await storageService.saveTask(task);
    }
  }

  Future<void> toggleTaskCompletion(Task task) {
    return updateTask(task.isCompleted ? task.reopen() : task.markCompleted());
  }

  Future<void> deleteTask(String taskId) async {
    _tasks = _tasks.where((task) => task.id != taskId).toList(growable: false);
    notifyListeners();

    final storageService = _storageService;
    if (storageService != null) {
      await storageService.deleteTask(taskId);
    }
  }

  Future<void> clearTasks() async {
    _tasks = const <Task>[];
    notifyListeners();

    final storageService = _storageService;
    if (storageService != null) {
      await storageService.clearTasks();
    }
  }

  void _refreshTasksFromStorage() {
    final storageService = _storageService;
    if (storageService == null) {
      return;
    }

    _tasks = storageService.getAllTasks();
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksListenable?.removeListener(_refreshTasksFromStorage);
    super.dispose();
  }
}
