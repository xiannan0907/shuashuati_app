import 'dart:math';
import 'package:flutter/material.dart';

/// 精简版 24小时制时间选择器
class ClockTimePicker extends StatefulWidget {
  final int initialMinute;
  final ValueChanged<int> onChanged;
  final String label;

  const ClockTimePicker({
    super.key,
    required this.initialMinute,
    required this.onChanged,
    this.label = '',
  });

  @override
  State<ClockTimePicker> createState() => _ClockTimePickerState();
}

class _ClockTimePickerState extends State<ClockTimePicker> {
  late int _hour;
  late int _minute;
  bool _isClockMode = true;
  bool _isLowerHalf = false;

  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minuteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hour = widget.initialMinute ~/ 60;
    _minute = widget.initialMinute % 60;
    _isLowerHalf = _hour >= 12;
    _updateControllers();
  }

  @override
  void didUpdateWidget(ClockTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMinute != widget.initialMinute) {
      _hour = widget.initialMinute ~/ 60;
      _minute = widget.initialMinute % 60;
      _isLowerHalf = _hour >= 12;
      _updateControllers();
    }
  }

  void _updateControllers() {
    _hourController.text = _hour.toString().padLeft(2, '0');
    _minuteController.text = _minute.toString().padLeft(2, '0');
  }

  void _updateTime() {
    widget.onChanged(_hour * 60 + _minute);
    _updateControllers();
  }

  void _toggleRange() {
    setState(() {
      _isLowerHalf = !_isLowerHalf;
      if (_isLowerHalf) {
        if (_hour < 12) _hour += 12;
      } else {
        if (_hour >= 12) _hour -= 12;
      }
      _updateTime();
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          if (_isClockMode)
            _buildClockMode(isDark)
          else
            _buildInputMode(isDark),
          const SizedBox(height: 6.0),
          _buildBottomControls(isDark),
        ],
      ),
    );
  }

  // ============================================================
  // 时钟模式
  // ============================================================

  Widget _buildClockMode(bool isDark) {
    return SizedBox(
      width: 180.0,
      height: 180.0,
      child: CustomPaint(
        painter: _ClockPainterSimple(
          hour: _hour,
          minute: _minute,
          isLowerHalf: _isLowerHalf,
          isDark: isDark,
        ),
        child: GestureDetector(
          onTapDown: (details) => _handleClockTap(details.localPosition, 90.0),
          behavior: HitTestBehavior.opaque,
        ),
      ),
    );
  }

  void _handleClockTap(Offset position, double radius) {
    final center = Offset(radius, radius);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < radius * 0.08 || distance > radius * 0.92) return;

    double angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    if (distance > radius * 0.55) {
      int hour12 = ((angle / (2 * pi)) * 12).round() % 12;
      if (hour12 == 0) hour12 = 12;

      int newHour;
      if (_isLowerHalf) {
        newHour = hour12 % 12 + 12;
        if (newHour == 24) newHour = 12;
      } else {
        newHour = hour12 % 12;
      }

      if (newHour != _hour) {
        setState(() {
          _hour = newHour;
          _updateTime();
        });
      }
    } else if (distance > radius * 0.15) {
      int newMinute = ((angle / (2 * pi)) * 12).round() % 12;
      newMinute *= 5;
      if (newMinute != _minute) {
        setState(() {
          _minute = newMinute;
          _updateTime();
        });
      }
    }
  }

  // ============================================================
  // 输入模式
  // ============================================================

  Widget _buildInputMode(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNumberInput(
            controller: _hourController,
            focusNode: _hourFocus,
            value: _hour,
            min: 0,
            max: 23,
            label: '小时',
            isDark: isDark,
            onChanged: (v) {
              if (v >= 0 && v <= 23) {
                setState(() {
                  _hour = v;
                  _isLowerHalf = _hour >= 12;
                  _updateTime();
                });
              }
            },
          ),
          const SizedBox(width: 8.0),
          Text(
            ':',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 8.0),
          _buildNumberInput(
            controller: _minuteController,
            focusNode: _minuteFocus,
            value: _minute,
            min: 0,
            max: 59,
            step: 5,
            label: '分钟',
            isDark: isDark,
            onChanged: (v) {
              if (v >= 0 && v <= 59) {
                setState(() {
                  _minute = v;
                  _updateTime();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required int value,
    required int min,
    required int max,
    required String label,
    required bool isDark,
    required Function(int) onChanged,
    int step = 1,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _buildStepButton(
              icon: Icons.remove,
              onTap: () {
                if (value > min) {
                  final newVal = ((value - step) ~/ step) * step;
                  onChanged(newVal.clamp(min, max));
                }
              },
              isDark: isDark,
            ),
            const SizedBox(width: 4.0),
            SizedBox(
              width: 40.0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6.0),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                  isDense: true,
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed >= min && parsed <= max) {
                    onChanged(parsed);
                  }
                },
                onSubmitted: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null) {
                    final clamped = parsed.clamp(min, max);
                    onChanged(clamped);
                    controller.text = clamped.toString().padLeft(2, '0');
                  } else {
                    controller.text = value.toString().padLeft(2, '0');
                  }
                  focusNode.unfocus();
                },
              ),
            ),
            const SizedBox(width: 4.0),
            _buildStepButton(
              icon: Icons.add,
              onTap: () {
                if (value < max) {
                  final newVal = ((value + step) ~/ step) * step;
                  onChanged(newVal.clamp(min, max));
                }
              },
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.0,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26.0,
        height: 26.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Icon(icon, size: 14.0, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
      ),
    );
  }

  // ============================================================
  // 底部控制栏
  // ============================================================

  Widget _buildBottomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildModeTab('时钟', _isClockMode, isDark),
              const SizedBox(width: 2.0),
              _buildModeTab('输入', !_isClockMode, isDark),
            ],
          ),
          if (_isClockMode)
            Row(
              children: [
                _buildRangeTab('0-11', !_isLowerHalf, isDark),
                const SizedBox(width: 2.0),
                _buildRangeTab('12-23', _isLowerHalf, isDark),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: (_hour >= 12 ? Colors.orange : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: _hour >= 12 ? Colors.orange : Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, bool isActive, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (_isClockMode == (label == '时钟')) return;
        setState(() {
          _isClockMode = label == '时钟';
          if (_hour < 0) _hour = 0;
          if (_hour > 23) _hour = 23;
          _updateControllers();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.blue.shade700 : Colors.blue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeTab(String label, bool isActive, bool isDark) {
    final color = label == '0-11' ? Colors.blue : Colors.orange;
    return GestureDetector(
      onTap: () {
        final targetIsLower = label == '12-23';
        if (_isLowerHalf != targetIsLower) {
          _toggleRange();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isActive ? color : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 钟表绘制器（修复类型错误）
// ============================================================

class _ClockPainterSimple extends CustomPainter {
  final int hour;
  final int minute;
  final bool isLowerHalf;
  final bool isDark;

  const _ClockPainterSimple({
    required this.hour,
    required this.minute,
    required this.isLowerHalf,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final rangeColor = isLowerHalf ? Colors.orange : Colors.blue;

    // 背景
    final bgPaint = Paint()
      ..color = isDark ? Colors.grey.shade800 : const Color(0xFFF0F4FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 外圈
    final borderPaint = Paint()
      ..color = isDark ? Colors.grey.shade600 : const Color(0xFFD0D9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);

    // 范围指示环（极淡）
    final rangePaint = Paint()
      ..color = rangeColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.92, rangePaint);

    // ---- 小时数字 1-12 ----
    for (int i = 0; i < 12; i++) {
      final angle = -pi / 2 + (i / 12) * 2 * pi;
      final value = i == 0 ? 12 : i;
      final isSelected = (hour12 == value);

      final textRadius = radius * 0.70;
      final tx = center.dx + textRadius * cos(angle);
      final ty = center.dy + textRadius * sin(angle);

      final isCardinal = i == 0 || i == 3 || i == 6 || i == 9;
      // 显式转为 double
      final double fontSize = isSelected ? 17.0 : (isCardinal ? 13.0 : 10.0);

      textPainter.text = TextSpan(
        text: value.toString(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
          color: isSelected
              ? rangeColor
              : (isCardinal
              ? (isDark ? Colors.grey.shade300 : Colors.grey.shade700)
              : (isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(tx - textPainter.width / 2, ty - textPainter.height / 2),
      );
    }

    // ---- 分钟数字 0-55 ----
    for (int i = 0; i < 12; i++) {
      final angle = -pi / 2 + (i / 12) * 2 * pi;
      final value = i * 5;
      final isSelected = value == minute;

      final textRadius = radius * 0.33;
      final tx = center.dx + textRadius * cos(angle);
      final ty = center.dy + textRadius * sin(angle);

      final double fontSize = isSelected ? 13.0 : 9.0;

      textPainter.text = TextSpan(
        text: value.toString(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (isDark ? Colors.green.shade300 : Colors.green)
              : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(tx - textPainter.width / 2, ty - textPainter.height / 2),
      );
    }

    // ---- 小时指针 ----
    final hourAngle = -pi / 2 + (hour12 / 12) * 2 * pi;
    final hx = center.dx + radius * 0.55 * cos(hourAngle);
    final hy = center.dy + radius * 0.55 * sin(hourAngle);

    final hourPaint = Paint()
      ..color = rangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(hx, hy), hourPaint);

    // ---- 分钟指针 ----
    final minuteAngle = -pi / 2 + (minute / 60) * 2 * pi;
    final mx = center.dx + radius * 0.35 * cos(minuteAngle);
    final my = center.dy + radius * 0.35 * sin(minuteAngle);

    final minutePaint = Paint()
      ..color = isDark ? Colors.green.shade300 : Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(mx, my), minutePaint);

    // ---- 中心点 ----
    final centerPaint = Paint()
      ..color = isDark ? Colors.white : Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, centerPaint);

    // ---- 内圈装饰 ----
    final innerPaint = Paint()
      ..color = isDark ? Colors.grey.shade700 : const Color(0xFFE0E8F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, radius * 0.20, innerPaint);

    // ---- 分割虚线 ----
    final dashPaint = Paint()
      ..color = isDark ? Colors.grey.shade700 : const Color(0xFFD5DDE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 0; i < 12; i++) {
      final angle = -pi / 2 + (i / 12) * 2 * pi;
      final innerR = radius * 0.44;
      final outerR = radius * 0.51;
      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}