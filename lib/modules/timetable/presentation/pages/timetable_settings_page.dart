import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

import '../bloc/timetable_bloc.dart';
import '../../utils/timetable_settings.dart';
import 'time_table_manage_page.dart';
import '../../data/models/timetable_model.dart';

class TimetableSettingsPage extends StatefulWidget {
  const TimetableSettingsPage({super.key});

  @override
  State<TimetableSettingsPage> createState() => _TimetableSettingsPageState();
}

class _TimetableSettingsPageState extends State<TimetableSettingsPage> {
  DateTime _semesterStart = DateTime.now();
  bool _showTeacher = true;
  bool _showClassroom = true;
  bool _showWeek = true;
  bool _showAllWeeks = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _semesterStart = await TimetableSettings.getSemesterStart();
    _showTeacher = await TimetableSettings.getShowTeacher();
    _showClassroom = await TimetableSettings.getShowClassroom();
    _showWeek = await TimetableSettings.getShowWeek();
    _showAllWeeks = await TimetableSettings.getShowAllWeeks();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('课表设置'),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: BlocConsumer<TimetableBloc, TimetableState>(
        listener: (context, state) {
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
            final msg = state.importMessage!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            if (msg.contains('导出') && state.lastExportedFilePath != null) {
              _showShareDialog(context, state.lastExportedFilePath!);
            }
          }
        },
        builder: (context, state) {
          if (state is! TimetableLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final current = state.currentTimetable;
          // ✅ 确保 currentTimeTableId 是有效的，如果当前课表已被删除则设为 null
          String? currentTimeTableId = current?.timeTableId;

          // ============================================================
          // ✅ 去重 + 检查当前 ID 是否有效
          // ============================================================
          final uniqueTimetables = state.timetables.fold<List<Timetable>>([], (list, tt) {
            if (!list.any((t) => t.id == tt.id)) {
              list.add(tt);
            }
            return list;
          });

          // ✅ 检查 currentTimeTableId 是否在 uniqueTimetables 中存在
          final bool isValidId = currentTimeTableId == null ||
              uniqueTimetables.any((t) => t.id == currentTimeTableId);

          // ✅ 如果 ID 无效，设为 null（DropdownButton 会显示"选择时间表"）
          if (!isValidId) {
            currentTimeTableId = null;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: '学期设置',
                    children: [
                      _buildDatePickerRow(
                        label: '学期开始日期',
                        value: _semesterStart,
                        onChanged: (date) async {
                          await TimetableSettings.setSemesterStart(date);
                          setState(() => _semesterStart = date);
                          if (!context.mounted) return;
                          Navigator.pop(context, true);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '当前是第 ${TimetableSettings.getWeekNumber(DateTime.now(), _semesterStart)} 周',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildCard(
                    title: '时间表设置',
                    children: [
                      Row(
                        children: [
                          const Text(
                            '当前课表使用',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: currentTimeTableId,
                            hint: const Text('选择时间表'),
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('默认时间表'),
                              ),
                              ...uniqueTimetables.map((tt) {
                                return DropdownMenuItem(
                                  value: tt.id,
                                  child: Text(tt.name),
                                );
                              }),
                            ],
                            onChanged: (id) {
                              if (current != null) {
                                context.read<TimetableBloc>().add(
                                  SetTimetableTimeTable(current.id, id),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final bloc = context.read<TimetableBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: bloc,
                                  child: const TimeTableManagePage(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.schedule, size: 18),
                          label: const Text('管理时间表'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildCard(
                    title: '显示设置',
                    children: [
                      _buildSwitchRow(
                        label: '显示教师',
                        value: _showTeacher,
                        onChanged: (v) async {
                          await TimetableSettings.setShowTeacher(v);
                          setState(() => _showTeacher = v);
                        },
                      ),
                      _buildSwitchRow(
                        label: '显示教室',
                        value: _showClassroom,
                        onChanged: (v) async {
                          await TimetableSettings.setShowClassroom(v);
                          setState(() => _showClassroom = v);
                        },
                      ),
                      _buildSwitchRow(
                        label: '显示周次',
                        value: _showWeek,
                        onChanged: (v) async {
                          await TimetableSettings.setShowWeek(v);
                          setState(() => _showWeek = v);
                        },
                      ),
                      _buildSwitchRow(
                        label: '显示全部周次课程',
                        value: _showAllWeeks,
                        onChanged: (v) async {
                          await TimetableSettings.setShowAllWeeks(v);
                          setState(() => _showAllWeeks = v);
                          if (!context.mounted) return;
                          context.read<TimetableBloc>().add(LoadTimetables());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildCard(
                    title: '数据管理',
                    children: [
                      _buildActionRow(
                        icon: Icons.delete_outline,
                        label: '清空当前课表',
                        onTap: () => _showClearConfirm(context),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 分享对话框
  // ============================================================

  void _showShareDialog(BuildContext context, String filePath) {
    final fileName = filePath.split('/').last;
    final isExcel = fileName.endsWith('.xlsx');

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
              leading: Icon(
                isExcel ? Icons.table_chart : Icons.code,
                color: Colors.blue,
              ),
              title: Text('已导出: $fileName'),
              subtitle: const Text('选择下方操作'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final result = await OpenFile.open(filePath);
                          if (!context.mounted) return;
                          if (result.type != ResultType.done) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('无法打开文件，请到文件管理器查看'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('打开失败: $e'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('打开文件'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(filePath)],
                              text: '📚 分享课表文件',
                            ),
                          );
                        } catch (e) {
                          // 分享失败
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI 辅助组件
  // ============================================================

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(value.year - 1, 1, 1),
              lastDate: DateTime(value.year + 1, 12, 31),
            );
            if (date != null) {
              await TimetableSettings.setSemesterStart(date);
              setState(() => _semesterStart = date);
              if (!mounted) return;
              Navigator.pop(context, true);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              DateFormat('yyyy-MM-dd').format(value),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: color))),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空当前课表'),
        content: const Text('确定要清空当前课表的所有课程吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TimetableBloc>().add(ClearAllCourses());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空当前课表')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }
}