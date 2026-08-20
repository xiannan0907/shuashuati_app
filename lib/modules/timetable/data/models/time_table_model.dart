import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'time_table_model.g.dart';

@HiveType(typeId: 32)
class TimeTable extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int morningStart; // 上午第一节开始（分钟）

  @HiveField(3)
  int afternoonStart; // 下午第一节开始（分钟）

  @HiveField(4)
  int classDuration; // 每节课时长（分钟）

  @HiveField(5)
  int breakDuration; // 课间休息（分钟）

  @HiveField(6)
  final DateTime createdAt;

  TimeTable({
    required this.id,
    required this.name,
    this.morningStart = 8 * 60,
    this.afternoonStart = 14 * 60,
    this.classDuration = 45,
    this.breakDuration = 5,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TimeTable copyWith({
    String? id,
    String? name,
    int? morningStart,
    int? afternoonStart,
    int? classDuration,
    int? breakDuration,
    DateTime? createdAt,
  }) {
    return TimeTable(
      id: id ?? this.id,
      name: name ?? this.name,
      morningStart: morningStart ?? this.morningStart,
      afternoonStart: afternoonStart ?? this.afternoonStart,
      classDuration: classDuration ?? this.classDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 获取节次时间映射
  Map<int, String> getSlotTimes() {
    final slots = <int, String>{};
    int currentTime = morningStart;
    for (int i = 1; i <= 12; i++) {
      final start = _formatMinute(currentTime);
      currentTime += classDuration;
      final end = _formatMinute(currentTime);
      slots[i] = '$start-$end';
      if (i == 4) {
        currentTime = afternoonStart;
      } else {
        currentTime += breakDuration;
      }
    }
    return slots;
  }

  String _formatMinute(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    morningStart,
    afternoonStart,
    classDuration,
    breakDuration,
    createdAt,
  ];
}