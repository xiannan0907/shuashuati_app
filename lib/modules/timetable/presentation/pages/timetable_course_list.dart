import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';
import '../widgets/course_card.dart';

class TimetableCourseList extends StatelessWidget {
  final List<Course> courses;
  final Function(Course) onCourseTap;
  final Function(Course) onCourseEdit;    // ✅ 新增
  final Function(String) onCourseDelete;

  const TimetableCourseList({
    super.key,
    required this.courses,
    required this.onCourseTap,
    required this.onCourseEdit,           // ✅ 新增
    required this.onCourseDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 按周次、星期、节次排序
    final sorted = List<Course>.from(courses)
      ..removeWhere((c) => c.weekday < 1 || c.weekday > 7)
      ..sort((a, b) {
        if (a.weekStart != b.weekStart) return a.weekStart.compareTo(b.weekStart);
        if (a.weekday != b.weekday) return a.weekday.compareTo(b.weekday);
        return (a.startMinute ?? a.startSlot * 60).compareTo(b.startMinute ?? b.startSlot * 60);
      });

    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('暂无课程数据', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final course = sorted[index];
        return CourseCard(
          course: course,
          onTap: () => onCourseTap(course),
          onEdit: () => onCourseEdit(course),   // ✅ 新增编辑回调
          onDelete: () => onCourseDelete(course.id),
          showMenu: true,
        );
      },
    );
  }
}