import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/course_model.dart';
import '../bloc/timetable_bloc.dart';

class CourseEditSheet extends StatefulWidget {
  final Course? course;

  const CourseEditSheet({super.key, this.course});

  @override
  State<CourseEditSheet> createState() => _CourseEditSheetState();
}

class _CourseEditSheetState extends State<CourseEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _teacherController;
  late TextEditingController _classroomController;
  late TextEditingController _noteController;

  late int _weekday;
  late int _startSlot;
  late int _endSlot;
  late int _weekStart;
  late int _weekEnd;
  late String _selectedColor;
  late String _scheduleType;

  final List<String> _colorOptions = [
    'blue', 'red', 'orange', 'green', 'purple',
    'pink', 'teal', 'indigo', 'amber', 'deepOrange',
    'brown', 'grey'
  ];

  final List<String> _typeOptions = ['course', 'exam', 'homework', 'meeting', 'other'];
  final Map<String, String> _typeLabels = {
    'course': '课程',
    'exam': '考试',
    'homework': '作业',
    'meeting': '会议',
    'other': '其他',
  };
  final Map<String, Color> _typeColors = {
    'course': Colors.blue,
    'exam': Colors.red,
    'homework': Colors.orange,
    'meeting': Colors.purple,
    'other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameController = TextEditingController(text: c?.name ?? '');
    _teacherController = TextEditingController(text: c?.teacher ?? '');
    _classroomController = TextEditingController(text: c?.classroom ?? '');
    _noteController = TextEditingController(text: c?.note ?? '');
    _weekday = c?.weekday ?? 1;
    _startSlot = c?.startSlot ?? 1;
    _endSlot = c?.endSlot ?? 2;
    _weekStart = c?.weekStart ?? 1;
    _weekEnd = c?.weekEnd ?? 20;
    _selectedColor = c?.color ?? 'blue';
    _scheduleType = c?.scheduleType ?? 'course';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.course != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isEdit ? '编辑课程' : '添加课程',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 表单
          _buildTextField(
            label: '课程名称',
            controller: _nameController,
            hintText: '请输入课程名称',
          ),
          const SizedBox(height: 8),

          _buildTextField(
            label: '教师',
            controller: _teacherController,
            hintText: '请输入教师姓名',
          ),
          const SizedBox(height: 8),

          _buildTextField(
            label: '教室',
            controller: _classroomController,
            hintText: '请输入教室',
          ),
          const SizedBox(height: 8),

          // 星期
          _buildPickerRow(
            label: '星期',
            value: '周${_weekdayName(_weekday)}',
            onTap: () => _showWeekdayPicker(context),
          ),
          const SizedBox(height: 8),

          // 节次
          Row(
            children: [
              Expanded(
                child: _buildPickerRow(
                  label: '开始节',
                  value: '第$_startSlot节',
                  onTap: () => _showSlotPicker(context, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPickerRow(
                  label: '结束节',
                  value: '第$_endSlot节',
                  onTap: () => _showSlotPicker(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 周次范围
          Row(
            children: [
              Expanded(
                child: _buildPickerRow(
                  label: '开始周',
                  value: '第$_weekStart周',
                  onTap: () => _showWeekPicker(context, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPickerRow(
                  label: '结束周',
                  value: '第$_weekEnd周',
                  onTap: () => _showWeekPicker(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 颜色
          _buildColorPicker(),
          const SizedBox(height: 8),

          // 课程类型
          _buildTypePicker(),
          const SizedBox(height: 8),

          // 备注
          _buildTextField(
            label: '备注',
            controller: _noteController,
            hintText: '可选',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEdit ? '保存' : '添加'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================================
  // 表单组件
  // ============================================================

  /// ✅ 输入框（无溢出）
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ 选择器行（无溢出）
  Widget _buildPickerRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        ),
        const Icon(Icons.arrow_drop_down, color: Colors.grey),
      ],
    );
  }

  /// ✅ 颜色选择器
  Widget _buildColorPicker() {
    return Row(
      children: [
        const SizedBox(
          width: 50,
          child: Text('颜色', style: TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _colorOptions.map((colorName) {
              final color = _getColor(colorName);
              final isSelected = _selectedColor == colorName;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorName),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// ✅ 类型选择器
  Widget _buildTypePicker() {
    return Row(
      children: [
        const SizedBox(
          width: 50,
          child: Text('类型', style: TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _typeOptions.map((type) {
              final isSelected = _scheduleType == type;
              final color = _typeColors[type] ?? Colors.grey;
              return GestureDetector(
                onTap: () => setState(() => _scheduleType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _typeLabels[type] ?? type,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 选择器弹窗
  // ============================================================

  void _showWeekdayPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择星期'),
        content: SizedBox(
          width: 200,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _weekday = day);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _weekday == day ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '周${_weekdayName(day)}',
                    style: TextStyle(
                      color: _weekday == day ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showSlotPicker(BuildContext context, bool isStart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isStart ? '选择开始节' : '选择结束节'),
        content: SizedBox(
          width: 200,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              final slot = index + 1;
              final current = isStart ? _startSlot : _endSlot;
              final isSelected = current == slot;
              final isDisabled = isStart ? slot > _endSlot : slot < _startSlot;
              return GestureDetector(
                onTap: isDisabled ? null : () {
                  setState(() {
                    if (isStart) {
                      _startSlot = slot;
                    } else {
                      _endSlot = slot;
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : (isDisabled ? Colors.grey.shade100 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '第$slot节',
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDisabled ? Colors.grey.shade400 : Colors.black87),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showWeekPicker(BuildContext context, bool isStart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isStart ? '选择开始周' : '选择结束周'),
        content: SizedBox(
          width: 200,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(20, (index) {
              final week = index + 1;
              final current = isStart ? _weekStart : _weekEnd;
              final isSelected = current == week;
              final isDisabled = isStart ? week > _weekEnd : week < _weekStart;
              return GestureDetector(
                onTap: isDisabled ? null : () {
                  setState(() {
                    if (isStart) {
                      _weekStart = week;
                    } else {
                      _weekEnd = week;
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : (isDisabled ? Colors.grey.shade100 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '第$week周',
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDisabled ? Colors.grey.shade400 : Colors.black87),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 保存逻辑
  // ============================================================

  void _saveCourse() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入课程名称')),
      );
      return;
    }

    final course = Course(
      id: widget.course?.id ?? 'course_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      teacher: _teacherController.text.trim(),
      classroom: _classroomController.text.trim(),
      weekday: _weekday,
      startSlot: _startSlot,
      endSlot: _endSlot,
      weekStart: _weekStart,
      weekEnd: _weekEnd,
      color: _selectedColor,
      scheduleType: _scheduleType,
      note: _noteController.text.trim(),
    );

    if (widget.course != null) {
      context.read<TimetableBloc>().add(UpdateCourse(course));
    } else {
      context.read<TimetableBloc>().add(AddCourse(course));
    }

    Navigator.pop(context);
  }

  // ============================================================
  // 辅助方法
  // ============================================================

  String _weekdayName(int day) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[day - 1];
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
}