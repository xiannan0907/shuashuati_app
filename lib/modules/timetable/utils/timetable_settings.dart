import 'package:shared_preferences/shared_preferences.dart';

class TimetableSettings {
  static const String _semesterStartKey = 'semester_start';
  static const String _showTeacherKey = 'show_teacher';
  static const String _showClassroomKey = 'show_classroom';
  static const String _showWeekKey = 'show_week';
  static const String _showAllWeeksKey = 'show_all_weeks'; // ✅ 新增

  // ============================================================
  // 学期开始日期
  // ============================================================

  static Future<DateTime> getSemesterStart() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_semesterStartKey);
    if (value != null) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    // 默认：当前学期开始（9月1日）
    final now = DateTime.now();
    int year = now.year;
    if (now.month < 9) year--;
    return DateTime(year, 9, 1);
  }

  static Future<void> setSemesterStart(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_semesterStartKey, date.toIso8601String());
  }

  // ============================================================
  // 显示设置
  // ============================================================

  static Future<bool> getShowTeacher() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showTeacherKey) ?? true;
  }

  static Future<void> setShowTeacher(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTeacherKey, value);
  }

  static Future<bool> getShowClassroom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showClassroomKey) ?? true;
  }

  static Future<void> setShowClassroom(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showClassroomKey, value);
  }

  static Future<bool> getShowWeek() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showWeekKey) ?? true;
  }

  static Future<void> setShowWeek(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showWeekKey, value);
  }

  // ============================================================
  // ✅ 显示全部周次课程（新增）
  // ============================================================

  static Future<bool> getShowAllWeeks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showAllWeeksKey) ?? false; // 默认 false（仅本周）
  }

  static Future<void> setShowAllWeeks(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAllWeeksKey, value);
  }

  // ============================================================
  // 周次计算工具
  // ============================================================

  static int getWeekNumber(DateTime date, DateTime semesterStart) {
    if (date.isBefore(semesterStart)) return 1;
    final difference = date.difference(semesterStart);
    // 与 WeekUtils / SemesterSettings 统一：ceil 语义（第 0-6 天=第 1 周）
    return (difference.inDays / 7).ceil().clamp(1, 20);
  }
}