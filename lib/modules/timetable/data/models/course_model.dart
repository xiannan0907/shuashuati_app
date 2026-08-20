import 'package:hive_ce/hive.dart';
import 'package:equatable/equatable.dart';

part 'course_model.g.dart';

@HiveType(typeId: 30)
class Course extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String teacher;

  @HiveField(3)
  final String classroom;

  @HiveField(4)
  final int weekday;

  @HiveField(5)
  final int startSlot;

  @HiveField(6)
  final int endSlot;

  @HiveField(7)
  final int weekStart;

  @HiveField(8)
  final int weekEnd;

  @HiveField(9)
  final String color;

  @HiveField(10)
  final String? note;

  // ✅ 新增：学分
  @HiveField(11)
  final double credit;

  // ✅ 新增：日程类型（course | exam | homework | meeting | other）
  @HiveField(12)
  final String scheduleType;

  // ✅ 新增：自定义具体时间（分钟，如 8:00 = 480）
  @HiveField(13)
  final int? startMinute;
  @HiveField(14)
  final int? endMinute;

  const Course({
    required this.id,
    required this.name,
    this.teacher = '',
    this.classroom = '',
    required this.weekday,
    required this.startSlot,
    required this.endSlot,
    this.weekStart = 1,
    this.weekEnd = 20,
    this.color = 'blue',
    this.note,
    this.credit = 0.0,
    this.scheduleType = 'course',
    this.startMinute,
    this.endMinute,
  });

  Course copyWith({
    String? id,
    String? name,
    String? teacher,
    String? classroom,
    int? weekday,
    int? startSlot,
    int? endSlot,
    int? weekStart,
    int? weekEnd,
    String? color,
    String? note,
    double? credit,
    String? scheduleType,
    int? startMinute,
    int? endMinute,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      weekday: weekday ?? this.weekday,
      startSlot: startSlot ?? this.startSlot,
      endSlot: endSlot ?? this.endSlot,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      color: color ?? this.color,
      note: note ?? this.note,
      credit: credit ?? this.credit,
      scheduleType: scheduleType ?? this.scheduleType,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'weekday': weekday,
      'startSlot': startSlot,
      'endSlot': endSlot,
      'weekStart': weekStart,
      'weekEnd': weekEnd,
      'color': color,
      'note': note,
      'credit': credit,
      'scheduleType': scheduleType,
      'startMinute': startMinute,
      'endMinute': endMinute,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 'course_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? '',
      teacher: json['teacher'] ?? '',
      classroom: json['classroom'] ?? '',
      weekday: json['weekday'] ?? 1,
      startSlot: json['startSlot'] ?? 1,
      endSlot: json['endSlot'] ?? 1,
      weekStart: json['weekStart'] ?? 1,
      weekEnd: json['weekEnd'] ?? 20,
      color: json['color'] ?? 'blue',
      note: json['note'],
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      scheduleType: json['scheduleType'] ?? 'course',
      startMinute: json['startMinute'] as int?,
      endMinute: json['endMinute'] as int?,
    );
  }

  // 获取日程类型图标
  String get scheduleTypeIcon {
    switch (scheduleType) {
      case 'exam':
        return '📝';
      case 'homework':
        return '📚';
      case 'meeting':
        return '💬';
      case 'other':
        return '📌';
      default:
        return '📖';
    }
  }

  // 获取日程类型中文名
  String get scheduleTypeName {
    switch (scheduleType) {
      case 'exam':
        return '考试';
      case 'homework':
        return '作业';
      case 'meeting':
        return '会议';
      case 'other':
        return '其他';
      default:
        return '课程';
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    teacher,
    classroom,
    weekday,
    startSlot,
    endSlot,
    weekStart,
    weekEnd,
    color,
    note,
    credit,
    scheduleType,
    startMinute,
    endMinute,
  ];
}