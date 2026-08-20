import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/course_model.dart';
import '../../presentation/bloc/timetable_bloc.dart';

class CourseEditDialog extends StatefulWidget {
  final Course? course;

  const CourseEditDialog({super.key, this.course});

  @override
  State<CourseEditDialog> createState() => _CourseEditDialogState();
}

class _CourseEditDialogState extends State<CourseEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _classroomController;
  late final TextEditingController _noteController;
  late int _weekday;
  late int _startSlot;
  late int _endSlot;
  late int _weekStart;
  late int _weekEnd;
  late String _color;
  late double _credit;
  late String _scheduleType;
  late bool _useCustomTime;
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;

  final List<Map<String, dynamic>> _colorOptions = [
    {'key': 'blue', 'color': Colors.blue},
    {'key': 'red', 'color': Colors.red},
    {'key': 'orange', 'color': Colors.orange},
    {'key': 'green', 'color': Colors.green},
    {'key': 'purple', 'color': Colors.purple},
    {'key': 'pink', 'color': Colors.pink},
    {'key': 'teal', 'color': Colors.teal},
    {'key': 'indigo', 'color': Colors.indigo},
    {'key': 'amber', 'color': Colors.amber},
    {'key': 'deepOrange', 'color': Colors.deepOrange},
    {'key': 'brown', 'color': Colors.brown},
    {'key': 'grey', 'color': Colors.grey},
  ];

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
    _color = c?.color ?? 'blue';
    _credit = c?.credit ?? 0.0;
    _scheduleType = c?.scheduleType ?? 'course';

    _useCustomTime = c?.startMinute != null && c?.endMinute != null;
    if (_useCustomTime && c != null) {
      _startHour = c.startMinute! ~/ 60;
      _startMinute = c.startMinute! % 60;
      _endHour = c.endMinute! ~/ 60;
      _endMinute = c.endMinute! % 60;
    } else {
      _startHour = 8;
      _startMinute = 0;
      _endHour = 9;
      _endMinute = 35;
    }
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
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      title: Row(
        children: [
          Icon(
            widget.course == null ? Icons.add_circle : Icons.edit,
            color: Theme.of(context).primaryColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            widget.course == null ? '添加课程' : '编辑课程',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('基本信息'),
                  const SizedBox(height: 6),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: '课程名称',
                          icon: Icons.book,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _teacherController,
                                label: '教师',
                                icon: Icons.person,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _classroomController,
                                label: '教室',
                                icon: Icons.location_on,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildSectionHeader('时间模式'),
                  const SizedBox(height: 6),
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('固定节次', style: TextStyle(fontSize: 14)),
                            Switch(
                              value: !_useCustomTime,
                              onChanged: (v) => setDialogState(() {
                                _useCustomTime = !v;
                              }),
                            ),
                            const Text('自定义时间', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        if (_useCustomTime) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimePicker(
                                  label: '开始',
                                  hour: _startHour,
                                  minute: _startMinute,
                                  onChanged: (h, m) => setDialogState(() {
                                    _startHour = h;
                                    _startMinute = m;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimePicker(
                                  label: '结束',
                                  hour: _endHour,
                                  minute: _endMinute,
                                  onChanged: (h, m) => setDialogState(() {
                                    _endHour = h;
                                    _endMinute = m;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildSectionHeader('时间安排'),
                  const SizedBox(height: 6),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildDropdown(
                          value: _weekday,
                          label: '星期',
                          items: [1, 2, 3, 4, 5, 6, 7],
                          itemLabels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
                          onChanged: (v) => setDialogState(() => _weekday = v ?? 1),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                value: _startSlot,
                                label: '开始节',
                                items: List.generate(12, (i) => i + 1),
                                itemLabels: List.generate(12, (i) => '第${i + 1}节'),
                                onChanged: (v) => setDialogState(() {
                                  _startSlot = v ?? 1;
                                  if (_startSlot >= _endSlot) {
                                    _endSlot = _startSlot + 1;
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDropdown(
                                value: _endSlot,
                                label: '结束节',
                                items: List.generate(12, (i) => i + 1),
                                itemLabels: List.generate(12, (i) => '第${i + 1}节'),
                                onChanged: (v) => setDialogState(() {
                                  _endSlot = v ?? _startSlot + 1;
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                value: _weekStart,
                                label: '开始周',
                                items: List.generate(20, (i) => i + 1),
                                itemLabels: List.generate(20, (i) => '第${i + 1}周'),
                                onChanged: (v) => setDialogState(() => _weekStart = v ?? 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDropdown(
                                value: _weekEnd,
                                label: '结束周',
                                items: List.generate(20, (i) => i + 1),
                                itemLabels: List.generate(20, (i) => '第${i + 1}周'),
                                onChanged: (v) => setDialogState(() => _weekEnd = v ?? 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildSectionHeader('课程属性'),
                  const SizedBox(height: 6),
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('学分', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            _buildCreditSelector(),
                            const Spacer(),
                            _buildDropdown(
                              value: _scheduleType,
                              label: '类型',
                              items: ['course', 'exam', 'homework', 'meeting', 'other'],
                              itemLabels: ['课程', '考试', '作业', '会议', '其他'],
                              onChanged: (v) => setDialogState(() => _scheduleType = v ?? 'course'),
                              width: 100,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildSectionHeader('颜色'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _colorOptions.map((c) {
                      final isSelected = _color == c['key'];
                      return GestureDetector(
                        onTap: () => setDialogState(() => _color = c['key']!),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c['color'],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  _buildSectionHeader('备注'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _noteController,
                    label: '备注',
                    icon: Icons.note,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入课程名称')),
      );
      return;
    }

    final course = Course(
      id: widget.course?.id ?? 'course_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      classroom: _classroomController.text.trim(),
      weekday: _weekday,
      startSlot: _startSlot,
      endSlot: _endSlot,
      weekStart: _weekStart,
      weekEnd: _weekEnd,
      color: _color,
      credit: _credit,
      scheduleType: _scheduleType,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      startMinute: _useCustomTime ? _startHour * 60 + _startMinute : null,
      endMinute: _useCustomTime ? _endHour * 60 + _endMinute : null,
    );

    final bloc = context.read<TimetableBloc>();
    if (widget.course == null) {
      bloc.add(AddCourse(course));
    } else {
      bloc.add(UpdateCourse(course));
    }
    Navigator.pop(context);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 12),
      maxLines: maxLines,
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required List<T> items,
    required List<String> itemLabels,
    required Function(T?) onChanged,
    double width = double.infinity,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isDense: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 12),
        items: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return DropdownMenuItem(
            value: item,
            child: Text(itemLabels[index]),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required int hour,
    required int minute,
    required Function(int, int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildTimeUnitPicker(
              value: hour,
              min: 0,
              max: 23,
              onChanged: (v) => onChanged(v, minute),
            ),
            const Text(' : ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildTimeUnitPicker(
              value: minute,
              min: 0,
              max: 59,
              step: 5,
              onChanged: (v) => onChanged(hour, v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeUnitPicker({
    required int value,
    required int min,
    required int max,
    int step = 1,
    required Function(int) onChanged,
  }) {
    return SizedBox(
      width: 55,
      child: DropdownButtonFormField<int>(
        initialValue: value,
        isDense: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
        items: List.generate((max - min) ~/ step + 1, (i) {
          final v = min + i * step;
          return DropdownMenuItem(
            value: v,
            child: Text(v.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 16)),
          );
        }),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }

  Widget _buildCreditSelector() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 24),
          onPressed: _credit > 0 ? () => setState(() => _credit -= 0.5) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            _credit.toStringAsFixed(1),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 24),
          onPressed: _credit < 10 ? () => setState(() => _credit += 0.5) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}