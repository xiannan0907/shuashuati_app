import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/timetable_bloc.dart';
import '../../data/models/time_table_model.dart';
import '../widgets/clock_time_picker.dart';

class TimeTableManagePage extends StatefulWidget {
  const TimeTableManagePage({super.key});

  @override
  State<TimeTableManagePage> createState() => _TimeTableManagePageState();
}

class _TimeTableManagePageState extends State<TimeTableManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('时间表管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTimeTableDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<TimetableBloc, TimetableState>(
        builder: (context, state) {
          if (state is TimetableLoaded) {
            if (state.timeTables.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.timeTables.length,
              itemBuilder: (context, index) {
                final tt = state.timeTables[index];
                return _buildTimeTableCard(context, tt);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            '暂无时间表',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            '点击右上角 + 创建',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTableCard(BuildContext context, TimeTable tt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tt.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTag('上午 ${_formatMinute(tt.morningStart)}'),
                    _buildTag('下午 ${_formatMinute(tt.afternoonStart)}'),
                    _buildTag('${tt.classDuration}分钟'),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditTimeTableDialog(context, tt);
              } else if (value == 'delete') {
                _showDeleteConfirm(context, tt.id);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  String _formatMinute(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void _showCreateTimeTableDialog(BuildContext context) {
    _showTimeTableDialog(context, null);
  }

  void _showEditTimeTableDialog(BuildContext context, TimeTable tt) {
    _showTimeTableDialog(context, tt);
  }

  void _showTimeTableDialog(BuildContext context, TimeTable? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    int morningStart = existing?.morningStart ?? 8 * 60;
    int afternoonStart = existing?.afternoonStart ?? 14 * 60;
    int classDuration = existing?.classDuration ?? 45;
    int breakDuration = existing?.breakDuration ?? 5;
    bool isEditingMorning = true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final currentValue = isEditingMorning ? morningStart : afternoonStart;

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  existing == null ? Icons.add : Icons.edit,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  existing == null ? '创建时间表' : '编辑时间表',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 名称
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        isDense: true,
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? '请输入名称' : null,
                    ),
                    const SizedBox(height: 8),

                    // 切换目标
                    Row(
                      children: [
                        _buildToggleButton(
                          label: '上午',
                          isActive: isEditingMorning,
                          color: Colors.blue,
                          onTap: () => setDialogState(() => isEditingMorning = true),
                        ),
                        const SizedBox(width: 6),
                        _buildToggleButton(
                          label: '下午',
                          isActive: !isEditingMorning,
                          color: Colors.orange,
                          onTap: () => setDialogState(() => isEditingMorning = false),
                        ),
                        const Spacer(),
                        Text(
                          _formatMinute(currentValue),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ✅ 使用新的钟表选择器（带模式切换）
                    ClockTimePicker(
                      initialMinute: currentValue,
                      onChanged: (value) {
                        setDialogState(() {
                          if (isEditingMorning) {
                            morningStart = value;
                          } else {
                            afternoonStart = value;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // 时长设置
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberPicker(
                            label: '每节课时长',
                            value: classDuration,
                            unit: '分钟',
                            min: 30,
                            max: 90,
                            step: 5,
                            onChanged: (v) => setDialogState(() => classDuration = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumberPicker(
                            label: '课间休息',
                            value: breakDuration,
                            unit: '分钟',
                            min: 0,
                            max: 20,
                            step: 5,
                            onChanged: (v) => setDialogState(() => breakDuration = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final bloc = context.read<TimetableBloc>();
                    if (existing == null) {
                      bloc.add(CreateTimeTable(
                        name: nameController.text.trim(),
                        morningStart: morningStart,
                        afternoonStart: afternoonStart,
                        classDuration: classDuration,
                        breakDuration: breakDuration,
                      ));
                    } else {
                      bloc.add(UpdateTimeTable(existing.copyWith(
                        name: nameController.text.trim(),
                        morningStart: morningStart,
                        afternoonStart: afternoonStart,
                        classDuration: classDuration,
                        breakDuration: breakDuration,
                      )));
                    }
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                ),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPicker({
    required String label,
    required int value,
    required String unit,
    required int min,
    required int max,
    required int step,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (value > min) onChanged(value - step);
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(Icons.remove, size: 14, color: Colors.grey),
              ),
            ),
            Container(
              width: 28,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (value < max) onChanged(value + step);
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(Icons.add, size: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除时间表'),
        content: const Text('确定要删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<TimetableBloc>().add(DeleteTimeTable(id));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}