import 'package:hive/hive.dart';

import 'tree_growth_stage.dart';

@HiveType(typeId: 4)
class UserRecord {
  UserRecord({
    this.energy = 0,
    this.consecutiveCheckInDays = 0,
    this.lastCheckInDate,
    this.totalCheckInDays = 0,
    this.totalCompletedTasks = 0,
    this.totalAllClearDays = 0,
    this.lastAllClearRewardDate,
    this.totalFocusSeconds = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  final int energy;

  @HiveField(1)
  final int consecutiveCheckInDays;

  @HiveField(2)
  final DateTime? lastCheckInDate;

  @HiveField(3)
  final int totalCheckInDays;

  @HiveField(4)
  final int totalCompletedTasks;

  @HiveField(5)
  final int totalAllClearDays;

  @HiveField(6)
  final DateTime? lastAllClearRewardDate;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final int totalFocusSeconds;

  factory UserRecord.initial() {
    return UserRecord();
  }

  TreeGrowthStage get treeGrowthStage => treeGrowthStageFromEnergy(energy);

  String get avatarEmoji {
    final avatarIndex =
        createdAt.millisecondsSinceEpoch.abs() % _animalAvatarEmojis.length;
    return _animalAvatarEmojis[avatarIndex];
  }

  int registeredDaysOn(DateTime date) {
    final startDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final currentDate = DateTime(date.year, date.month, date.day);
    final days = currentDate.difference(startDate).inDays + 1;
    return days < 1 ? 1 : days;
  }

  String profileTitleOn(DateTime date) {
    return '拖延症抗体 · 第 ${registeredDaysOn(date)} 天';
  }

  bool hasCheckedInOn(DateTime date) {
    final lastDate = lastCheckInDate;
    return lastDate != null && _isSameDate(lastDate, date);
  }

  bool hasClaimedAllClearRewardOn(DateTime date) {
    final lastDate = lastAllClearRewardDate;
    return lastDate != null && _isSameDate(lastDate, date);
  }

  UserRecord checkIn(DateTime date, {int rewardEnergy = 10}) {
    if (hasCheckedInOn(date)) {
      return this;
    }

    final previousCheckIn = lastCheckInDate;
    final nextStreak =
        previousCheckIn != null && _isYesterday(previousCheckIn, date)
        ? consecutiveCheckInDays + 1
        : 1;

    return copyWith(
      energy: energy + rewardEnergy,
      consecutiveCheckInDays: nextStreak,
      lastCheckInDate: date,
      totalCheckInDays: totalCheckInDays + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserRecord addTaskCompletionReward(int rewardEnergy) {
    return copyWith(
      energy: energy + rewardEnergy,
      totalCompletedTasks: totalCompletedTasks + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserRecord addFocusSession(Duration duration, {int rewardEnergy = 50}) {
    return copyWith(
      energy: energy + rewardEnergy,
      totalCompletedTasks: totalCompletedTasks + 1,
      totalFocusSeconds: totalFocusSeconds + duration.inSeconds,
      updatedAt: DateTime.now(),
    );
  }

  UserRecord claimAllClearReward(DateTime date, {int rewardEnergy = 20}) {
    if (hasClaimedAllClearRewardOn(date)) {
      return this;
    }

    return copyWith(
      energy: energy + rewardEnergy,
      totalAllClearDays: totalAllClearDays + 1,
      lastAllClearRewardDate: date,
      updatedAt: DateTime.now(),
    );
  }

  UserRecord copyWith({
    int? energy,
    int? consecutiveCheckInDays,
    DateTime? lastCheckInDate,
    bool clearLastCheckInDate = false,
    int? totalCheckInDays,
    int? totalCompletedTasks,
    int? totalAllClearDays,
    DateTime? lastAllClearRewardDate,
    bool clearLastAllClearRewardDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalFocusSeconds,
  }) {
    return UserRecord(
      energy: energy ?? this.energy,
      consecutiveCheckInDays:
          consecutiveCheckInDays ?? this.consecutiveCheckInDays,
      lastCheckInDate: clearLastCheckInDate
          ? null
          : lastCheckInDate ?? this.lastCheckInDate,
      totalCheckInDays: totalCheckInDays ?? this.totalCheckInDays,
      totalCompletedTasks: totalCompletedTasks ?? this.totalCompletedTasks,
      totalAllClearDays: totalAllClearDays ?? this.totalAllClearDays,
      lastAllClearRewardDate: clearLastAllClearRewardDate
          ? null
          : lastAllClearRewardDate ?? this.lastAllClearRewardDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'energy': energy,
      'consecutiveCheckInDays': consecutiveCheckInDays,
      'lastCheckInDate': lastCheckInDate?.toIso8601String(),
      'totalCheckInDays': totalCheckInDays,
      'totalCompletedTasks': totalCompletedTasks,
      'totalAllClearDays': totalAllClearDays,
      'lastAllClearRewardDate': lastAllClearRewardDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalFocusSeconds': totalFocusSeconds,
    };
  }

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    return UserRecord(
      energy: _readInt(json['energy']),
      consecutiveCheckInDays: _readInt(json['consecutiveCheckInDays']),
      lastCheckInDate: _readDateTime(json['lastCheckInDate']),
      totalCheckInDays: _readInt(json['totalCheckInDays']),
      totalCompletedTasks: _readInt(json['totalCompletedTasks']),
      totalAllClearDays: _readInt(json['totalAllClearDays']),
      lastAllClearRewardDate: _readDateTime(json['lastAllClearRewardDate']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      totalFocusSeconds: _readInt(json['totalFocusSeconds']),
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

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isYesterday(DateTime previous, DateTime current) {
  final previousDate = DateTime(previous.year, previous.month, previous.day);
  final currentDate = DateTime(current.year, current.month, current.day);
  return currentDate.difference(previousDate).inDays == 1;
}

const _animalAvatarEmojis = <String>[
  '🐼',
  '🐻',
  '🦊',
  '🐰',
  '🐨',
  '🐯',
  '🐱',
  '🐶',
];
