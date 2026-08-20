import 'package:flutter/material.dart';
import '../data/models/course_model.dart';  // ✅ 修正路径

class WeekUtils {
  static DateTime semesterStart = DateTime(2025, 9, 1);

  static int getCurrentWeek() {
    final now = DateTime.now();
    final diff = now.difference(semesterStart);
    final week = (diff.inDays / 7).ceil().clamp(1, 20);
    return week;
  }

  static int getWeekForDate(DateTime date) {
    final diff = date.difference(semesterStart);
    return (diff.inDays / 7).ceil().clamp(1, 20);
  }

  static bool isCourseActive(Course course, {int? currentWeek}) {
    final week = currentWeek ?? getCurrentWeek();
    return course.weekStart <= week && course.weekEnd >= week;
  }

  static bool isCourseFinished(Course course, {int? currentWeek}) {
    final week = currentWeek ?? getCurrentWeek();
    return course.weekEnd < week;
  }

  static bool isCourseNotStarted(Course course, {int? currentWeek}) {
    final week = currentWeek ?? getCurrentWeek();
    return course.weekStart > week;
  }

  static CourseStatus getCourseStatus(Course course, {int? currentWeek}) {
    final week = currentWeek ?? getCurrentWeek();
    if (course.weekStart > week) return CourseStatus.notStarted;
    if (course.weekEnd < week) return CourseStatus.finished;
    return CourseStatus.active;
  }

  static String getStatusLabel(CourseStatus status) {
    switch (status) {
      case CourseStatus.active:
        return '📌 本周上课';
      case CourseStatus.finished:
        return '✅ 已结课';
      case CourseStatus.notStarted:
        return '⏳ 未开始';
    }
  }

  static Color getStatusColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.active:
        return Colors.green;
      case CourseStatus.finished:
        return Colors.grey;
      case CourseStatus.notStarted:
        return Colors.orange;
    }
  }
}

enum CourseStatus {
  active,
  finished,
  notStarted,
}