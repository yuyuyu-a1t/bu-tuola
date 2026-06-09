import 'package:flutter/foundation.dart';

import '../models/tree_growth_stage.dart';
import '../models/user_record.dart';
import '../services/storage_service.dart';

class UserRecordProvider extends ChangeNotifier {
  UserRecordProvider(StorageService storageService)
    : _storageService = storageService {
    _record = storageService.getUserRecord();
  }

  UserRecordProvider.memory([UserRecord? initialRecord])
    : _storageService = null,
      _record = initialRecord ?? UserRecord.initial();

  final StorageService? _storageService;
  late UserRecord _record;

  UserRecord get record => _record;

  bool get hasCheckedInToday => _record.hasCheckedInOn(DateTime.now());

  String get avatarEmoji => _record.avatarEmoji;

  String get profileTitle => _record.profileTitleOn(DateTime.now());

  TreeGrowthStage get currentStage => _record.treeGrowthStage;

  double get treeProgress => currentStage.progressForEnergy(_record.energy);

  String get treeEncouragement {
    return currentStage.encouragementForEnergy(_record.energy);
  }

  String get treeProgressText {
    return currentStage.progressTextForEnergy(_record.energy);
  }

  String get checkInButtonText {
    return hasCheckedInToday ? '今日已签到 ✅' : '点击签到';
  }

  String get headerNudge {
    return hasCheckedInToday ? '今日能量已送达，小树在吸收中。' : '今天也给小树一点能量。';
  }

  String get dailyAntiProcrastinationQuote {
    final today = DateTime.now();
    final quoteIndex =
        (_record.energy +
            _record.consecutiveCheckInDays +
            _record.registeredDaysOn(today) +
            today.day) %
        _antiProcrastinationQuotes.length;
    return _antiProcrastinationQuotes[quoteIndex];
  }

  Future<void> checkIn({DateTime? date}) async {
    final nextRecord = _record.checkIn(date ?? DateTime.now());
    await _save(nextRecord);
  }

  Future<void> addTaskCompletionReward(int rewardEnergy) async {
    final nextRecord = _record.addTaskCompletionReward(rewardEnergy);
    await _save(nextRecord);
  }

  Future<void> addFocusSession(
    Duration duration, {
    int rewardEnergy = 50,
  }) async {
    final nextRecord = _record.addFocusSession(
      duration,
      rewardEnergy: rewardEnergy,
    );
    await _save(nextRecord);
  }

  Future<void> claimAllClearReward({DateTime? date}) async {
    final nextRecord = _record.claimAllClearReward(date ?? DateTime.now());
    await _save(nextRecord);
  }

  Future<void> reset() async {
    await _save(UserRecord.initial());
  }

  Future<void> _save(UserRecord record) async {
    _record = record;
    notifyListeners();
    await _storageService?.saveUserRecord(record);
  }
}

const _antiProcrastinationQuotes = <String>[
  '💡 承认吧，你就是想糊弄，那就先糊弄个开头吧！',
  '🌼 先打开任务，假装努力，大脑很快就会信。',
  '🧃 今天不用很猛，先完成一小口就行。',
  '📎 拖延症最怕你动手 3 分钟。',
  '✨ 先写一个标题，也算把任务拽进现实。',
];
