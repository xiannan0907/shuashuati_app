import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/timetable_settings.dart';

class DateHeader extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime semesterStart;
  final Function(DateTime) onDateSelected;

  const DateHeader({
    super.key,
    required this.selectedDate,
    required this.semesterStart,
    required this.onDateSelected,
  });

  @override
  State<DateHeader> createState() => _DateHeaderState();
}

class _DateHeaderState extends State<DateHeader> {
  // 当前显示的周起始日期（用于计算7天的范围）
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _updateWeekStart();
  }

  @override
  void didUpdateWidget(DateHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _updateWeekStart();
    }
  }

  void _updateWeekStart() {
    // 计算选中日期所在周的周一
    final weekday = widget.selectedDate.weekday;
    _weekStart = widget.selectedDate.subtract(Duration(days: weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final weekNumber = TimetableSettings.getWeekNumber(
      widget.selectedDate,
      widget.semesterStart,
    );
    final isCurrentWeek = TimetableSettings.getWeekNumber(
      DateTime.now(),
      widget.semesterStart,
    ) ==
        weekNumber;

    // 获取当前周7天的日期
    final days = List.generate(7, (index) => _weekStart.add(Duration(days: index)));

    // 获取当前月的年份和月份（用于显示）
    final currentMonth = widget.selectedDate.month;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：年月 + 周次
          Row(
            children: [
              Text(
                DateFormat('yyyy年M月').format(widget.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCurrentWeek ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '第$weekNumber周 ${isCurrentWeek ? "本周" : "非本周"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrentWeek ? Colors.green.shade700 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 第二行：星期 + 日期（显示完整日期）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final date = days[index];
                final day = date.day;
                final isSelected = date.year == widget.selectedDate.year &&
                    date.month == widget.selectedDate.month &&
                    date.day == widget.selectedDate.day;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final isDifferentMonth = date.month != currentMonth;

                return GestureDetector(
                  onTap: () {
                    widget.onDateSelected(date);
                  },
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday && !isSelected
                            ? Colors.blue.shade300
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ['一', '二', '三', '四', '五', '六', '日'][index],
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : (isToday
                                ? Colors.blue.shade700
                                : Colors.grey.shade500),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected
                                ? Colors.white
                                : (isDifferentMonth
                                ? Colors.grey.shade400
                                : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : (isToday
                                ? FontWeight.w600
                                : FontWeight.normal),
                          ),
                        ),
                        // 显示月份标记（如果是不同月份）
                        if (isDifferentMonth)
                          Text(
                            '${date.month}月',
                            style: TextStyle(
                              fontSize: 8,
                              color: isSelected
                                  ? Colors.white70
                                  : Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}