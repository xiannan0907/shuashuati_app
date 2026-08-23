// 课表周次工具单元测试
import 'package:flutter_test/flutter_test.dart';

import 'package:shuashuati_app/modules/timetable/data/models/course_model.dart';
import 'package:shuashuati_app/modules/timetable/utils/week_utils.dart';

void main() {
  group('WeekUtils.getWeekForDate', () {
    setUp(() {
      // 固定学期开始日期，保证确定性
      WeekUtils.updateSemesterStart(DateTime(2026, 9, 1));
    });

    test('开学当天为第 1 周', () {
      expect(WeekUtils.getWeekForDate(DateTime(2026, 9, 1)), 1);
    });

    test('第 7 天为第 1 周最后一天（第 2 周边界，仍未进入）', () {
      // 距开学 7 天：(7/7).ceil() = 1
      expect(WeekUtils.getWeekForDate(DateTime(2026, 9, 8)), 1);
    });

    test('第 8 天进入第 2 周', () {
      // 距开学 8 天：(8/7).ceil() = 2
      expect(WeekUtils.getWeekForDate(DateTime(2026, 9, 9)), 2);
    });

    test('开学前日期 clamp 到第 1 周', () {
      expect(WeekUtils.getWeekForDate(DateTime(2026, 8, 1)), 1);
    });

    test('超过第 20 周的日期 clamp 到 20', () {
      // 2027-02-01 距开学 153 天：(153/7).ceil() = 22 → clamp 20
      expect(WeekUtils.getWeekForDate(DateTime(2027, 2, 1)), 20);
    });

    test('恰好第 20 周边界返回 20', () {
      // 距开学 140 天：(140/7).ceil() = 20
      expect(WeekUtils.getWeekForDate(DateTime(2027, 1, 19)), 20);
    });
  });

  group('WeekUtils 课程状态判断', () {
    Course course({int weekStart = 3, int weekEnd = 8}) => Course(
          id: 'c1',
          name: '高等数学',
          weekday: 1,
          startSlot: 1,
          endSlot: 2,
          weekStart: weekStart,
          weekEnd: weekEnd,
        );

    test('isCourseActive 区间内为 true（含边界周）', () {
      expect(WeekUtils.isCourseActive(course(), currentWeek: 5), isTrue);
      expect(WeekUtils.isCourseActive(course(), currentWeek: 3), isTrue);
      expect(WeekUtils.isCourseActive(course(), currentWeek: 8), isTrue);
    });

    test('isCourseActive 区间外为 false', () {
      expect(WeekUtils.isCourseActive(course(), currentWeek: 2), isFalse);
      expect(WeekUtils.isCourseActive(course(), currentWeek: 9), isFalse);
    });

    test('isCourseFinished 仅在 weekEnd < week 时成立', () {
      expect(WeekUtils.isCourseFinished(course(), currentWeek: 9), isTrue);
      expect(WeekUtils.isCourseFinished(course(), currentWeek: 8), isFalse);
    });

    test('isCourseNotStarted 仅在 weekStart > week 时成立', () {
      expect(WeekUtils.isCourseNotStarted(course(), currentWeek: 2), isTrue);
      expect(WeekUtils.isCourseNotStarted(course(), currentWeek: 3), isFalse);
    });

    test('getCourseStatus 三态判断', () {
      expect(
        WeekUtils.getCourseStatus(course(), currentWeek: 2),
        CourseStatus.notStarted,
      );
      expect(
        WeekUtils.getCourseStatus(course(), currentWeek: 5),
        CourseStatus.active,
      );
      expect(
        WeekUtils.getCourseStatus(course(), currentWeek: 9),
        CourseStatus.finished,
      );
    });

    test('默认课程（1-20 周）全学期有效，第 21 周结课', () {
      final full = course(weekStart: 1, weekEnd: 20);
      expect(WeekUtils.getCourseStatus(full, currentWeek: 1), CourseStatus.active);
      expect(WeekUtils.getCourseStatus(full, currentWeek: 20), CourseStatus.active);
      expect(WeekUtils.getCourseStatus(full, currentWeek: 21), CourseStatus.finished);
    });
  });
}
