import 'package:equatable/equatable.dart';
import 'course_model.dart';

class TimetableItem extends Equatable {
  final Course course;
  final int weekday;
  final int startSlot;
  final int endSlot;

  const TimetableItem({
    required this.course,
    required this.weekday,
    required this.startSlot,
    required this.endSlot,
  });

  bool get isSingleSlot => startSlot == endSlot;

  String get slotDisplay {
    if (isSingleSlot) {
      return '第${startSlot}节';
    }
    return '第$startSlot-${endSlot}节';
  }

  @override
  List<Object?> get props => [
    course.id,
    weekday,
    startSlot,
    endSlot,
  ];
}