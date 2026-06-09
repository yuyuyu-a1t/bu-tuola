import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hive_adapters.dart';
import '../models/task.dart';
import '../models/user_record.dart';
import 'storage_keys.dart';

class StorageService {
  StorageService._({
    required Box<Task> tasksBox,
    required Box<UserRecord> userRecordBox,
    required Box<dynamic> settingsBox,
  }) : _tasksBox = tasksBox,
       _userRecordBox = userRecordBox,
       _settingsBox = settingsBox;

  final Box<Task> _tasksBox;
  final Box<UserRecord> _userRecordBox;
  final Box<dynamic> _settingsBox;

  static Future<StorageService> initialize() async {
    await Hive.initFlutter();
    registerHiveAdapters();

    final tasksBox = await Hive.openBox<Task>(StorageKeys.tasksBox);
    final userRecordBox = await Hive.openBox<UserRecord>(
      StorageKeys.userRecordBox,
    );
    final settingsBox = await Hive.openBox<dynamic>(StorageKeys.settingsBox);

    return StorageService._(
      tasksBox: tasksBox,
      userRecordBox: userRecordBox,
      settingsBox: settingsBox,
    );
  }

  List<Task> getAllTasks() {
    final tasks = _tasksBox.values.toList(growable: false);
    return tasks..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  ValueListenable<Box<Task>> get tasksListenable {
    return _tasksBox.listenable();
  }

  Task? getTaskById(String id) {
    return _tasksBox.get(id);
  }

  Future<void> saveTask(Task task) {
    return _tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) {
    return _tasksBox.delete(id);
  }

  Future<void> clearTasks() {
    return _tasksBox.clear();
  }

  UserRecord getUserRecord() {
    return _userRecordBox.get(StorageKeys.currentUserRecord) ??
        UserRecord.initial();
  }

  Future<void> saveUserRecord(UserRecord record) {
    return _userRecordBox.put(StorageKeys.currentUserRecord, record);
  }

  String? getThemeModeName() {
    return _settingsBox.get(StorageKeys.themeMode) as String?;
  }

  Future<void> saveThemeModeName(String themeModeName) {
    return _settingsBox.put(StorageKeys.themeMode, themeModeName);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _tasksBox.clear(),
      _userRecordBox.clear(),
      _settingsBox.clear(),
    ]);
  }
}
