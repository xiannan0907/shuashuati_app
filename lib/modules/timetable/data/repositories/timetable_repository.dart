import 'package:hive_ce/hive.dart';
import '../models/course_model.dart';
import '../models/timetable_model.dart';
import '../models/time_table_model.dart';

class TimetableRepository {
  static const String courseBoxName = 'timetable_courses';
  static const String timetableBoxName = 'timetable_list';
  static const String timeTableBoxName = 'time_table_list';

  // ============================================================
  // Course CRUD
  // ============================================================

  Future<Box<Course>> _getCourseBox() async {
    return await Hive.openBox<Course>(courseBoxName);
  }

  Future<Box<Timetable>> _getTimetableBox() async {
    return await Hive.openBox<Timetable>(timetableBoxName);
  }

  Future<Box<TimeTable>> _getTimeTableBox() async {
    return await Hive.openBox<TimeTable>(timeTableBoxName);
  }

  // ============================================================
  // 课程方法
  // ============================================================

  Future<List<Course>> getCurrentTimetableCourses() async {
    final timetable = await getCurrentTimetable();
    if (timetable == null) return [];
    final box = await _getCourseBox();
    return timetable.courseIds
        .map((id) => box.get(id))
        .whereType<Course>()
        .toList();
  }

  Future<void> addCourseToCurrentTimetable(Course course) async {
    final box = await _getCourseBox();
    await box.put(course.id, course);

    final timetable = await getCurrentTimetable();
    if (timetable != null) {
      timetable.courseIds.add(course.id);
      await saveTimetable(timetable);
    }
  }

  Future<void> removeCourseFromTimetable(String courseId) async {
    final timetable = await getCurrentTimetable();
    if (timetable != null) {
      timetable.courseIds.remove(courseId);
      await saveTimetable(timetable);
    }
  }

  Future<void> deleteCourse(String id) async {
    final box = await _getCourseBox();
    await box.delete(id);

    final allTimetables = await getAllTimetables();
    for (var t in allTimetables) {
      if (t.courseIds.contains(id)) {
        t.courseIds.remove(id);
        await saveTimetable(t);
      }
    }
  }

  Future<void> saveCourse(Course course) async {
    final box = await _getCourseBox();
    await box.put(course.id, course);
  }

  Future<void> deleteAllCourses() async {
    final box = await _getCourseBox();
    await box.clear();
  }

  // ============================================================
  // 课表方法
  // ============================================================

  Future<List<Timetable>> getAllTimetables() async {
    final box = await _getTimetableBox();
    return box.values.whereType<Timetable>().toList();
  }

  Future<Timetable?> getCurrentTimetable() async {
    final box = await _getTimetableBox();
    try {
      return box.values.firstWhere((t) => t.isCurrent);
    } catch (_) {
      return box.values.isNotEmpty ? box.values.first : null;
    }
  }

  Future<Timetable?> getTimetable(String id) async {
    final box = await _getTimetableBox();
    return box.get(id);
  }

  Future<void> saveTimetable(Timetable timetable) async {
    final box = await _getTimetableBox();
    await box.put(timetable.id, timetable);
  }

  Future<void> setCurrentTimetable(String id) async {
    final box = await _getTimetableBox();
    for (var t in box.values) {
      t.isCurrent = (t.id == id);
      await box.put(t.id, t);
    }
  }

  Future<void> renameTimetable(String id, String newName) async {
    final box = await _getTimetableBox();
    final timetable = box.get(id);
    if (timetable != null) {
      timetable.name = newName;
      await box.put(id, timetable);
    }
  }

  Future<void> deleteTimetableWithCourses(String id) async {
    final box = await _getTimetableBox();
    final timetable = box.get(id);
    if (timetable != null) {
      final courseBox = await _getCourseBox();
      for (var courseId in timetable.courseIds) {
        await courseBox.delete(courseId);
      }
      await box.delete(id);
    }
  }

  Future<void> updateTimetableTimeTable(String timetableId, String? timeTableId) async {
    final box = await _getTimetableBox();
    final timetable = box.get(timetableId);
    if (timetable != null) {
      timetable.timeTableId = timeTableId;
      await box.put(timetableId, timetable);
    }
  }

  // ============================================================
  // ✅ 时间表 CRUD
  // ============================================================

  Future<List<TimeTable>> getAllTimeTables() async {
    final box = await _getTimeTableBox();
    return box.values.whereType<TimeTable>().toList();
  }

  Future<TimeTable?> getTimeTable(String id) async {
    final box = await _getTimeTableBox();
    return box.get(id);
  }

  Future<TimeTable?> getDefaultTimeTable() async {
    final box = await _getTimeTableBox();
    final list = box.values.whereType<TimeTable>().toList();
    if (list.isNotEmpty) return list.first;
    // 创建默认时间表
    final defaultTable = TimeTable(
      id: 'default_tt_${DateTime.now().millisecondsSinceEpoch}',
      name: '默认时间表',
      morningStart: 8 * 60,
      afternoonStart: 14 * 60,
      classDuration: 45,
      breakDuration: 5,
    );
    await box.put(defaultTable.id, defaultTable);
    return defaultTable;
  }

  Future<void> saveTimeTable(TimeTable timeTable) async {
    final box = await _getTimeTableBox();
    await box.put(timeTable.id, timeTable);
  }

  Future<void> deleteTimeTable(String id) async {
    final box = await _getTimeTableBox();
    await box.delete(id);
  }

  /// 获取当前课表关联的时间表
  Future<TimeTable?> getCurrentTimetableTimeTable() async {
    final timetable = await getCurrentTimetable();
    if (timetable == null) return await getDefaultTimeTable();
    if (timetable.timeTableId != null) {
      final tt = await getTimeTable(timetable.timeTableId!);
      if (tt != null) return tt;
    }
    return await getDefaultTimeTable();
  }

  /// 获取指定课表关联的时间表
  Future<TimeTable?> getTimetableTimeTable(String timetableId) async {
    final timetable = await getTimetable(timetableId);
    if (timetable == null) return null;
    if (timetable.timeTableId != null) {
      return await getTimeTable(timetable.timeTableId!);
    }
    return await getDefaultTimeTable();
  }
}