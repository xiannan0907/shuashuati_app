import 'package:hive/hive.dart';

class SemesterSettings {
  static const String boxName = 'timetable_settings';
  static const String keySemesterStart = 'semester_start';

  /// 获取学期开始日期，默认当年9月1日
  static Future<DateTime> getSemesterStart() async {
    try {
      final box = await Hive.openBox<String>(boxName);
      final data = box.get(keySemesterStart);
      if (data != null && data.isNotEmpty) {
        return DateTime.parse(data);
      }
    } catch (_) {}
    // 默认9月1日
    final now = DateTime.now();
    return DateTime(now.year, 9, 1);
  }

  /// 设置学期开始日期
  static Future<void> setSemesterStart(DateTime date) async {
    try {
      final box = await Hive.openBox<String>(boxName);
      await box.put(keySemesterStart, date.toIso8601String().split('T')[0]);
    } catch (_) {}
  }

  /// 计算给定日期是第几周（1-20）
  static int getWeekNumber(DateTime date, DateTime semesterStart) {
    final diff = date.difference(semesterStart);
    final week = (diff.inDays / 7).ceil().clamp(1, 20);
    return week;
  }

  /// 获取当前周次
  static Future<int> getCurrentWeek() async {
    final start = await getSemesterStart();
    final diff = DateTime.now().difference(start);
    return (diff.inDays / 7).ceil().clamp(1, 20);
  }
}