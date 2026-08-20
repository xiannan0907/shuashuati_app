import 'package:flutter/material.dart';

import '../../data/models/course_model.dart';
import '../../data/models/time_table_model.dart';
import '../../utils/timetable_settings.dart';

class TimetableWeekView extends StatefulWidget {
  final List<Course> courses;
  final DateTime semesterStart;
  final int initialWeek;
  final Function(int) onWeekChanged;
  final Function(Course) onCourseTap;
  final Function(Course)? onCourseEdit;
  final Function(String)? onCourseDelete;
  final Function(Course, int, int)? onCourseMoved;
  final Function(int, int)? onEmptySlotTap;
  final TimeTable? timeTable;

  const TimetableWeekView({
    super.key,
    required this.courses,
    required this.semesterStart,
    required this.initialWeek,
    required this.onWeekChanged,
    required this.onCourseTap,
    this.onCourseEdit,
    this.onCourseDelete,
    this.onCourseMoved,
    this.onEmptySlotTap,
    this.timeTable,
  });

  @override
  State<TimetableWeekView> createState() => TimetableWeekViewState();
}

class TimetableWeekViewState extends State<TimetableWeekView> {
  late int _viewWeek;
  late Map<int, String> _slotTimes;
  final Set<String> _emptySlotKeys = {};
  String? _dragTargetKey;
  bool _isDragging = false;

  // ✅ 从设置读取
  bool _showAllWeeks = false;

  static const double rowHeight = 64.0;
  static const double leftColumnWidth = 44.0;
  static const int totalSlots = 12;

  @override
  void initState() {
    super.initState();
    _viewWeek = widget.initialWeek;
    _loadSettings();
    _updateSlotTimes();
  }

  // ✅ 加载设置
  Future<void> _loadSettings() async {
    final showAll = await TimetableSettings.getShowAllWeeks();
    if (mounted) {
      setState(() {
        _showAllWeeks = showAll;
      });
    }
  }

  // ✅ 刷新设置（供外部调用）
  void refreshSettings() {
    _loadSettings();
  }

  @override
  void didUpdateWidget(TimetableWeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeTable != widget.timeTable) {
      _updateSlotTimes();
    }
  }

  void _updateSlotTimes() {
    if (widget.timeTable != null) {
      _slotTimes = widget.timeTable!.getSlotTimes();
    } else {
      _slotTimes = _getDefaultSlotTimes();
    }
    if (mounted) setState(() {});
  }

  Map<int, String> _getDefaultSlotTimes() {
    final slots = <int, String>{};
    int currentTime = 8 * 60;
    for (int i = 1; i <= 12; i++) {
      final start = _formatMinute(currentTime);
      currentTime += 45;
      final end = _formatMinute(currentTime);
      slots[i] = '$start-$end';
      if (i == 4) {
        currentTime = 14 * 60;
      } else {
        currentTime += 5;
      }
    }
    return slots;
  }

  void refreshView(int week) {
    setState(() {
      _viewWeek = week;
    });
  }

  void refreshSlotTimes() {
    _updateSlotTimes();
  }

  Color _getColor(String name) {
    switch (name) {
      case 'blue': return Colors.blue;
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'teal': return Colors.teal;
      case 'indigo': return Colors.indigo;
      case 'amber': return Colors.amber;
      case 'deepOrange': return Colors.deepOrange;
      case 'brown': return Colors.brown;
      case 'grey': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _formatMinute(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _getTimeDisplay(Course course) {
    if (course.startMinute != null && course.endMinute != null) {
      return '${_formatMinute(course.startMinute!)}-${_formatMinute(course.endMinute!)}';
    }
    final start = _slotTimes[course.startSlot]?.split('-')[0] ?? '第${course.startSlot}节';
    final end = _slotTimes[course.endSlot]?.split('-')[1] ?? '第${course.endSlot}节';
    return '$start-$end';
  }

  Course? _findCourseAt(int weekday, int slot) {
    for (var c in widget.courses) {
      if (c.weekday != weekday) continue;
      // ✅ 根据设置决定是否过滤周次
      if (!_showAllWeeks) {
        if (c.weekStart > _viewWeek || c.weekEnd < _viewWeek) continue;
      }
      final start = c.startMinute ?? (c.startSlot - 1) * 45 + 480;
      final end = c.endMinute ?? (c.endSlot - 1) * 45 + 480;
      final targetStart = (slot - 1) * 45 + 480;
      final targetEnd = targetStart + 45;
      if (start < targetEnd && end > targetStart) {
        return c;
      }
    }
    return null;
  }

  void _handleDrop(Course draggedCourse, int targetWeekday, int targetSlot) {
    final existing = _findCourseAt(targetWeekday, targetSlot);
    setState(() {
      _isDragging = false;
      _dragTargetKey = null;
    });

    if (existing == null) {
      if (draggedCourse.weekday == targetWeekday &&
          (draggedCourse.startMinute ?? (draggedCourse.startSlot - 1) * 45 + 480) == (targetSlot - 1) * 45 + 480) {
        return;
      }
      widget.onCourseMoved?.call(draggedCourse, targetWeekday, targetSlot);
      return;
    }

    if (existing.id == draggedCourse.id) return;

    final originalWeekday = draggedCourse.weekday;
    final originalSlot = draggedCourse.startMinute != null
        ? ((draggedCourse.startMinute! - 480) / 45).round() + 1
        : draggedCourse.startSlot;

    widget.onCourseMoved?.call(draggedCourse, targetWeekday, targetSlot);
    widget.onCourseMoved?.call(existing, originalWeekday, originalSlot);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final weekStartDate = widget.semesterStart.add(Duration(days: (_viewWeek - 1) * 7));
    final monday = weekStartDate.subtract(Duration(days: weekStartDate.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));

    final month = monday.month;
    final year = monday.year;

    // ✅ 分组并过滤课程（根据设置）
    final Map<int, List<Course>> grouped = {};
    for (int i = 1; i <= 7; i++) {
      grouped[i] = widget.courses
          .where((c) => c.weekday == i)
          .where((c) {
        // 显示全部周次，不过滤
        if (_showAllWeeks) return true;
        // 否则只显示当前周的课程
        return c.weekStart <= _viewWeek && c.weekEnd >= _viewWeek;
      })
          .toList();
      grouped[i]!.sort((a, b) => (a.startMinute ?? a.startSlot * 60).compareTo(b.startMinute ?? b.startSlot * 60));
    }

    final weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    final double availableWidth = screenWidth - 16 - 8;
    final double columnWidth = (availableWidth - leftColumnWidth - 8) / 7;
    final double effectiveColumnWidth = columnWidth > 30 ? columnWidth : 30;
    final double totalWidth = leftColumnWidth + 7 * effectiveColumnWidth + 8;
    final double totalHeight = totalSlots * rowHeight;

    // 构建背景网格（与之前相同，省略重复代码，但确保 _findCourseAt 使用 _showAllWeeks）
    List<Widget> gridRows = [];
    for (int slot = 1; slot <= totalSlots; slot++) {
      final slotTime = _slotTimes[slot] ?? '';
      List<Widget> cells = [];
      for (int weekday = 1; weekday <= 7; weekday++) {
        final String slotKey = '${weekday}_$slot';
        final bool isActive = _emptySlotKeys.contains(slotKey);
        cells.add(
          DragTarget<Course>(
            onAcceptWithDetails: (details) => _handleDrop(details.data, weekday, slot),
            onWillAcceptWithDetails: (details) {
              final existing = _findCourseAt(weekday, slot);
              if (existing?.id == details.data.id) return false;
              return true;
            },
            builder: (context, candidateData, rejectedData) {
              final bool isDragTarget = _dragTargetKey == slotKey && _isDragging;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_emptySlotKeys.contains(slotKey)) {
                      _emptySlotKeys.remove(slotKey);
                    } else {
                      _emptySlotKeys.clear();
                      _emptySlotKeys.add(slotKey);
                    }
                  });
                },
                child: Container(
                  width: effectiveColumnWidth,
                  height: rowHeight,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.shade100
                        : (isDragTarget ? Colors.orange.shade100 : Colors.transparent),
                    border: Border.all(
                      color: isDragTarget
                          ? Colors.orange
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      width: isDragTarget ? 2.0 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: isActive
                        ? GestureDetector(
                      onTap: () {
                        widget.onEmptySlotTap?.call(weekday, slot);
                        setState(() => _emptySlotKeys.clear());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16.0),
                      ),
                    )
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      }
      gridRows.add(
        Row(
          children: [
            SizedBox(
              width: leftColumnWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('第$slot节',
                      style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
                  if (slotTime.isNotEmpty)
                    Text(slotTime,
                        style: TextStyle(fontSize: 7, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
                ],
              ),
            ),
            ...cells,
          ],
        ),
      );
    }

    // 构建课程卡片
    List<Widget> courseWidgets = [];
    for (int weekday = 1; weekday <= 7; weekday++) {
      final dayCourses = grouped[weekday] ?? [];
      for (var course in dayCourses) {
        final startSlot = course.startMinute != null
            ? ((course.startMinute! - 480) / 45).round() + 1
            : course.startSlot;
        final endSlot = course.endMinute != null
            ? ((course.endMinute! - 480) / 45).round() + 1
            : course.endSlot;
        final double top = ((startSlot - 1) * rowHeight).toDouble();
        final double height = ((endSlot - startSlot + 1) * rowHeight).toDouble();

        final color = _getColor(course.color);
        final bgColor = color.withValues(alpha: isDark ? 0.35 : 0.2);
        final borderColor = color;

        final double left = (leftColumnWidth + (weekday - 1) * effectiveColumnWidth + 2).toDouble();
        final double width = (effectiveColumnWidth - 4).toDouble();

        courseWidgets.add(
          Positioned(
            key: ValueKey('course_${course.id}_$_viewWeek'),
            left: left,
            top: top,
            width: width,
            height: height,
            child: RepaintBoundary(
              child: LongPressDraggable<Course>(
                data: course,
                feedback: Material(
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8.0),
                      ],
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(course.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(_getTimeDisplay(course),
                            style: const TextStyle(color: Colors.white70, fontSize: 8.0)),
                      ],
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: Container()),
                delay: const Duration(milliseconds: 500),
                onDragStarted: () {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onDragEnd: (details) {
                  setState(() {
                    _isDragging = false;
                    _dragTargetKey = null;
                  });
                },
                child: GestureDetector(
                  onTap: () => widget.onCourseTap(course),
                  child: Container(
                    margin: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          course.name,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 2,
                        ),
                        if (course.teacher.isNotEmpty)
                          Text(
                            course.teacher,
                            style: TextStyle(
                              fontSize: 7.0,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        if (course.classroom.isNotEmpty)
                          Text(
                            course.classroom,
                            style: TextStyle(
                              fontSize: 7.0,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: Text(
                            '${course.weekStart}-${course.weekEnd}周',
                            style: TextStyle(
                              fontSize: 6.0,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        _buildWeekSelector(isDark),
        const SizedBox(height: 6.0),
        Row(
          children: [
            SizedBox(
              width: leftColumnWidth,
              child: Text(
                '$year年$month月',
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ...List.generate(7, (index) {
              final date = weekDates[index];
              final day = date.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.blue.shade100
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekdayLabels[index],
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Colors.blue.shade700
                              : (isDark ? Colors.white : Colors.grey.shade700),
                        ),
                      ),
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w400,
                          color: isToday
                              ? Colors.blue.shade700
                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4.0),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Column(children: gridRows),
                      ...courseWidgets,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSelector(bool isDark) {
    final currentWeek = TimetableSettings.getWeekNumber(DateTime.now(), widget.semesterStart);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (_viewWeek > 1) {
                setState(() {
                  _viewWeek--;
                });
                widget.onWeekChanged(_viewWeek);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.chevron_left, size: 18.0),
                  SizedBox(width: 2.0),
                  Text('上一周', style: TextStyle(fontSize: 12.0)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          GestureDetector(
            onTap: () {
              setState(() {
                _viewWeek = currentWeek;
              });
              widget.onWeekChanged(_viewWeek);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: _viewWeek == currentWeek ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _viewWeek == currentWeek ? Colors.green : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_viewWeek == currentWeek) const Icon(Icons.circle, color: Colors.green, size: 8.0),
                  if (_viewWeek == currentWeek) const SizedBox(width: 4.0),
                  Text(
                    '第 $_viewWeek 周',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: _viewWeek == currentWeek ? Colors.green : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          GestureDetector(
            onTap: () {
              if (_viewWeek < 20) {
                setState(() {
                  _viewWeek++;
                });
                widget.onWeekChanged(_viewWeek);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: const [
                  Text('下一周', style: TextStyle(fontSize: 12.0)),
                  SizedBox(width: 2.0),
                  Icon(Icons.chevron_right, size: 18.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}