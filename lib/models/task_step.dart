import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class TaskStep {
  const TaskStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.order = 0,
    this.encouragement = '',
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final bool isCompleted;

  @HiveField(3)
  final int order;

  @HiveField(4)
  final String encouragement;

  TaskStep copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? order,
    String? encouragement,
  }) {
    return TaskStep(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      encouragement: encouragement ?? this.encouragement,
    );
  }

  TaskStep markCompleted([bool value = true]) {
    return copyWith(isCompleted: value);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'order': order,
      'encouragement': encouragement,
    };
  }

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isCompleted: _readBool(json['isCompleted']),
      order: _readInt(json['order']),
      encouragement: json['encouragement']?.toString() ?? '',
    );
  }

  static List<TaskStep> listFromJson(Object? value) {
    if (value is! Iterable) {
      return const <TaskStep>[];
    }

    return value
        .whereType<Map>()
        .map((item) => TaskStep.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
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

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
