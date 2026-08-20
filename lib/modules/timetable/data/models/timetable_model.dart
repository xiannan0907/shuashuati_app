// ignore_for_file: must_be_immutable
import 'package:hive_ce/hive.dart';
import 'package:equatable/equatable.dart';

part 'timetable_model.g.dart';

@HiveType(typeId: 31)
class Timetable extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final int semester;

  @HiveField(3)
  final int year;

  @HiveField(4)
  List<String> courseIds;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool isCurrent;

  @HiveField(7)
  String? timeTableId;

  Timetable({
    required this.id,
    required this.name,
    this.semester = 1,
    required this.year,
    this.courseIds = const [],
    DateTime? createdAt,
    this.isCurrent = false,
    this.timeTableId,
  }) : createdAt = createdAt ?? DateTime.now();

  Timetable copyWith({
    String? id,
    String? name,
    int? semester,
    int? year,
    List<String>? courseIds,
    DateTime? createdAt,
    bool? isCurrent,
    String? timeTableId,
  }) {
    return Timetable(
      id: id ?? this.id,
      name: name ?? this.name,
      semester: semester ?? this.semester,
      year: year ?? this.year,
      courseIds: courseIds ?? this.courseIds,
      createdAt: createdAt ?? this.createdAt,
      isCurrent: isCurrent ?? this.isCurrent,
      timeTableId: timeTableId ?? this.timeTableId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    semester,
    year,
    courseIds,
    createdAt,
    isCurrent,
    timeTableId,
  ];
}