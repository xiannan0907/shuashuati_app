import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../bloc/timetable_bloc.dart';
import '../../data/models/course_model.dart';
import '../../data/models/timetable_model.dart';
import '../widgets/course_card.dart';
import '../widgets/date_header.dart';
import '../widgets/course_edit_sheet.dart';
import 'timetable_week_view.dart';
import 'timetable_course_list.dart';
import 'timetable_settings_page.dart';
import 'share_center_page.dart';
import '../../utils/timetable_settings.dart';
import '../../data/models/time_table_model.dart';

class TimetableMainPage extends StatefulWidget {
  const TimetableMainPage({super.key});

  @override
  State<TimetableMainPage> createState() => _TimetableMainPageState();
}

class _TimetableMainPageState extends State<TimetableMainPage> {
  int _currentTab = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _semesterStart = DateTime.now();
  int _currentWeek = 1;
  final GlobalKey<TimetableWeekViewState> _weekViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSemesterStart();
  }

  Future<void> _loadSemesterStart() async {
    final start = await TimetableSettings.getSemesterStart();
    _semesterStart = start;
    _currentWeek = TimetableSettings.getWeekNumber(DateTime.now(), start);
    final weekStart = _semesterStart.add(Duration(days: (_currentWeek - 1) * 7));
    _selectedDate = weekStart.subtract(Duration(days: weekStart.weekday - 1));
    setState(() {});
  }

  void _onDateSelected(DateTime date) {
    final week = TimetableSettings.getWeekNumber(date, _semesterStart);
    setState(() {
      _selectedDate = date;
      _currentWeek = week;
    });
    _weekViewKey.currentState?.refreshView(week);
  }

  void _onWeekChanged(int week) {
    final weekStart = _semesterStart.add(Duration(days: (week - 1) * 7));
    final monday = weekStart.subtract(Duration(days: weekStart.weekday - 1));
    setState(() {
      _currentWeek = week;
      _selectedDate = monday;
    });
  }

  // ============================================================
  // ✅ 重新计算周次（只在学期开始日期变化时才更新）
  // ============================================================
  Future<void> _recalculateWeek() async {
    final start = await TimetableSettings.getSemesterStart();

    // 只有学期开始日期变化时才重新计算
    if (_semesterStart != start) {
      _semesterStart = start;
      _currentWeek = TimetableSettings.getWeekNumber(DateTime.now(), start);
      final weekStart = _semesterStart.add(Duration(days: (_currentWeek - 1) * 7));
      _selectedDate = weekStart.subtract(Duration(days: weekStart.weekday - 1));
      setState(() {});
      _weekViewKey.currentState?.refreshView(_currentWeek);
      _weekViewKey.currentState?.refreshSlotTimes();
    }
    // 否则保持当前周不变
  }

  // ============================================================
  // 状态变化监听
  // ============================================================
  void _handleStateChanges(BuildContext context, TimetableState state) {
    if (state is TimetableError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    if (state is TimetableLoaded && state.importMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.importMessage!),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (state is TimetableLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recalculateWeek();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      body: BlocConsumer<TimetableBloc, TimetableState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          if (state is TimetableLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TimetableError) {
            return _buildErrorState(context, state);
          }
          if (state is TimetableLoaded) {
            if (state.courses.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildContent(context, state);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // AppBar
  // ============================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      title: BlocBuilder<TimetableBloc, TimetableState>(
        builder: (context, state) {
          if (state is TimetableLoaded) {
            final current = state.currentTimetable;
            if (state.timetables.isEmpty) {
              return const Text('我的课表');
            }
            return GestureDetector(
              onLongPress: () {
                if (current != null) {
                  _showTimetableMenu(context, current);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 20, color: Colors.black87),
                  const SizedBox(width: 6),
                  Flexible(
                    child: DropdownButton<String>(
                      value: current?.id,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black87, size: 22),
                      isExpanded: true,
                      items: state.timetables.map((t) {
                        return DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          context.read<TimetableBloc>().add(SetCurrentTimetable(id));
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          return const Text('我的课表');
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.black87),
          onPressed: () => _showAddCourseSheet(context),
          tooltip: '添加课程',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) {
            if (value == 'settings') {
              _openSettings(context);
            } else if (value == 'share_center') {
              _openShareCenter(context);
            } else if (value == 'create_timetable') {
              _showCreateTimetableDialog(context);
            } else if (value == 'import') {
              _showImportOptions(context);
            } else if (value == 'refresh') {
              context.read<TimetableBloc>().add(LoadTimetables());
              _weekViewKey.currentState?.refreshSlotTimes();
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [Icon(Icons.settings, size: 20), SizedBox(width: 12), Text('课表设置')],
              ),
            ),
            const PopupMenuItem(
              value: 'share_center',
              child: Row(
                children: [Icon(Icons.share, size: 20), SizedBox(width: 12), Text('分享中心')],
              ),
            ),
            const PopupMenuItem(
              value: 'create_timetable',
              child: Row(
                children: [Icon(Icons.add_box, size: 20), SizedBox(width: 12), Text('新建课表')],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [Icon(Icons.upload_file, size: 20), SizedBox(width: 12), Text('导入课表')],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [Icon(Icons.refresh, size: 20), SizedBox(width: 12), Text('刷新')],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openSettings(BuildContext context) async {
    final bloc = context.read<TimetableBloc>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const TimetableSettingsPage(),
        ),
      ),
    );
    if (result == true) {
      context.read<TimetableBloc>().add(LoadTimetables());
      _weekViewKey.currentState?.refreshSlotTimes();
      final start = await TimetableSettings.getSemesterStart();
      _semesterStart = start;
      _currentWeek = TimetableSettings.getWeekNumber(DateTime.now(), start);
      _weekViewKey.currentState?.refreshView(_currentWeek);
      setState(() {});
    }
  }

  void _openShareCenter(BuildContext context) {
    final bloc = context.read<TimetableBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const ShareCenterPage(),
        ),
      ),
    );
  }

  // ============================================================
  // BottomNavBar
  // ============================================================

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (index) => setState(() => _currentTab = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey.shade500,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '日视图',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_view_week),
          label: '周视图',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: '全部课程',
        ),
      ],
    );
  }

  // ============================================================
  // 内容构建
  // ============================================================

  Widget _buildContent(BuildContext context, TimetableLoaded state) {
    TimeTable? currentTimeTable;
    if (state.currentTimetable?.timeTableId != null) {
      try {
        currentTimeTable = state.timeTables.firstWhere(
              (tt) => tt.id == state.currentTimetable!.timeTableId,
        );
      } catch (_) {
        if (state.timeTables.isNotEmpty) {
          currentTimeTable = state.timeTables.first;
        }
      }
    } else if (state.timeTables.isNotEmpty) {
      currentTimeTable = state.timeTables.first;
    }

    return IndexedStack(
      index: _currentTab,
      children: [
        _buildDayView(context, state.courses),
        TimetableWeekView(
          key: _weekViewKey,
          courses: state.courses,
          semesterStart: _semesterStart,
          initialWeek: _currentWeek,
          onWeekChanged: _onWeekChanged,
          timeTable: currentTimeTable,
          onCourseTap: (course) => _showCourseDetail(context, course),
          onCourseEdit: (course) => _showEditCourseSheet(context, course),
          onCourseDelete: (courseId) {
            context.read<TimetableBloc>().add(DeleteCourse(courseId));
          },
          onCourseMoved: (course, newWeekday, newStartSlot) {
            final updated = course.copyWith(
              weekday: newWeekday,
              startSlot: newStartSlot,
              startMinute: (newStartSlot - 1) * 45 + 480,
              endMinute: (newStartSlot) * 45 + 480,
            );
            context.read<TimetableBloc>().add(UpdateCourse(updated));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('课程已移动'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          onEmptySlotTap: (weekday, slot) {
            _showAddCourseSheet(context, weekday: weekday, startSlot: slot);
          },
        ),
        TimetableCourseList(
          courses: state.courses,
          onCourseTap: (course) => _showCourseDetail(context, course),
          onCourseEdit: (course) => _showEditCourseSheet(context, course),
          onCourseDelete: (courseId) {
            context.read<TimetableBloc>().add(DeleteCourse(courseId));
          },
        ),
      ],
    );
  }

  // ============================================================
  // 日视图
  // ============================================================

  Widget _buildDayView(BuildContext context, List<Course> allCourses) {
    final weekday = _selectedDate.weekday;
    final weekCourses = allCourses
        .where((c) => c.weekStart <= _currentWeek && c.weekEnd >= _currentWeek)
        .toList();
    final dayCourses = weekCourses
        .where((c) => c.weekday == weekday)
        .toList()
      ..sort((a, b) => (a.startMinute ?? a.startSlot * 60).compareTo(b.startMinute ?? b.startSlot * 60));

    return Column(
      children: [
        DateHeader(
          selectedDate: _selectedDate,
          semesterStart: _semesterStart,
          onDateSelected: _onDateSelected,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: dayCourses.isEmpty
              ? _buildEmptyDayState(context)
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dayCourses.length,
            itemBuilder: (context, index) {
              final course = dayCourses[index];
              return CourseCard(
                course: course,
                onTap: () => _showCourseDetail(context, course),
                onEdit: () => _showEditCourseSheet(context, course),
                onDelete: () => _showDeleteConfirm(context, course.id),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 添加/编辑课程
  // ============================================================

  void _showAddCourseSheet(BuildContext context, {int? weekday, int? startSlot}) {
    final bloc = context.read<TimetableBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Course? preset;
        if (weekday != null && startSlot != null) {
          preset = Course(
            id: 'temp',
            name: '',
            weekday: weekday,
            startSlot: startSlot,
            endSlot: startSlot + 1,
          );
        }
        return BlocProvider.value(
          value: bloc,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: preset != null
                      ? CourseEditSheet(course: preset)
                      : const CourseEditSheet(),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showEditCourseSheet(BuildContext context, Course course) {
    final bloc = context.read<TimetableBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: CourseEditSheet(course: course),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 错误和空状态
  // ============================================================

  Widget _buildErrorState(BuildContext context, TimetableError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(state.message, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<TimetableBloc>().add(LoadTimetables());
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '暂无课程',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角 + 添加课程\n或 上传 导入课表文件',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showImportOptions(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('导入课表'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddCourseSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('手动添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.free_breakfast, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            '今天没有课程',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 导入
  // ============================================================

  Future<void> _showImportOptions(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['json', 'xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) return;
    context.read<TimetableBloc>().add(ImportCourses(path));
  }

  // ============================================================
  // 课表管理
  // ============================================================

  void _showCreateTimetableDialog(BuildContext context) {
    final controller = TextEditingController();
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    final semesterController = TextEditingController(text: '1');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        title: const Row(
          children: [
            Icon(Icons.add_box, color: Colors.blue, size: 22),
            SizedBox(width: 8),
            Text('新建课表', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '课表名称',
                border: OutlineInputBorder(),
                hintText: '如：2024-2025 第一学期',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: '年份',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: semesterController,
                    decoration: const InputDecoration(
                      labelText: '学期',
                      border: OutlineInputBorder(),
                      hintText: '1-8',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入课表名称')),
                );
                return;
              }
              final year = int.tryParse(yearController.text.trim()) ?? DateTime.now().year;
              final semester = int.tryParse(semesterController.text.trim()) ?? 1;
              context.read<TimetableBloc>().add(
                CreateTimetable(
                  name: name,
                  year: year,
                  semester: semester,
                ),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showTimetableMenu(BuildContext context, Timetable timetable) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameTimetableDialog(context, timetable);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除'),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteTimetableConfirm(context, timetable);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameTimetableDialog(BuildContext context, Timetable timetable) {
    final controller = TextEditingController(text: timetable.name);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 22),
            SizedBox(width: 8),
            Text('重命名课表', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '课表名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入课表名称')),
                );
                return;
              }
              context.read<TimetableBloc>().add(RenameTimetable(timetable.id, newName));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTimetableConfirm(BuildContext context, Timetable timetable) {
    final courseCount = timetable.courseIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('删除课表', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          '确定要删除课表「${timetable.name}」吗？\n\n'
              '该课表下共有 $courseCount 门课程，删除后全部丢失。\n'
              '此操作不可恢复！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<TimetableBloc>().add(DeleteTimetable(timetable.id));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 课程详情
  // ============================================================

  void _showCourseDetail(BuildContext context, Course course) {
    final color = _getColor(course.color);
    final weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    course.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _typeLabels[course.scheduleType] ?? '课程',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('教师', course.teacher.isEmpty ? '未设置' : course.teacher),
            _buildInfoRow('教室', course.classroom.isEmpty ? '未设置' : course.classroom),
            _buildInfoRow('时间', '${weekdayLabels[course.weekday - 1]} ${course.startMinute != null && course.endMinute != null ? _formatMinute(course.startMinute!) + '-' + _formatMinute(course.endMinute!) : '第${course.startSlot}-${course.endSlot}节'}'),
            _buildInfoRow('周次', '第${course.weekStart}-${course.weekEnd}周'),
            if (course.credit > 0) _buildInfoRow('学分', '${course.credit.toStringAsFixed(1)} 学分'),
            if (course.note != null && course.note!.isNotEmpty) _buildInfoRow('备注', course.note!),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditCourseSheet(context, course);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirm(context, course.id);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        ],
      ),
    );
  }

  String _formatMinute(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 删除课程确认
  // ============================================================

  void _showDeleteConfirm(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除课程'),
        content: const Text('确定要删除这门课程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TimetableBloc>().add(DeleteCourse(courseId));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 辅助方法
  // ============================================================

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

  final Map<String, String> _typeLabels = {
    'course': '课程',
    'exam': '考试',
    'homework': '作业',
    'meeting': '会议',
    'other': '其他',
  };
}