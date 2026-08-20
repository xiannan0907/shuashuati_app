import 'package:flutter/material.dart';

class ColorManager {
  // 预设课程颜色（12种）
  static const List<Color> presetColors = [
    Color(0xFF4CAF50), // 绿色 - 专业课
    Color(0xFF2196F3), // 蓝色 - 公共课
    Color(0xFFFF9800), // 橙色 - 选修课
    Color(0xFF9C27B0), // 紫色 - 实验课
    Color(0xFFF44336), // 红色 - 考试/重要
    Color(0xFF00BCD4), // 青色 - 体育课
    Color(0xFFFF5722), // 深橙色 - 实践课
    Color(0xFF8BC34A), // 亮绿 - 自习
    Color(0xFFE91E63), // 粉色 - 语言类
    Color(0xFF3F51B5), // 靛蓝 - 数学类
    Color(0xFF795548), // 棕色 - 文史类
    Color(0xFF607D8B), // 蓝灰 - 其他
  ];

  // ✅ 修复：去掉 const，Color 不能作为 const map 的键
  static final Map<Color, String> colorNames = {
    Color(0xFF4CAF50): '绿色',
    Color(0xFF2196F3): '蓝色',
    Color(0xFFFF9800): '橙色',
    Color(0xFF9C27B0): '紫色',
    Color(0xFFF44336): '红色',
    Color(0xFF00BCD4): '青色',
    Color(0xFFFF5722): '深橙',
    Color(0xFF8BC34A): '亮绿',
    Color(0xFFE91E63): '粉色',
    Color(0xFF3F51B5): '靛蓝',
    Color(0xFF795548): '棕色',
    Color(0xFF607D8B): '蓝灰',
  };

  static int _index = 0;

  static Color getNextColor() {
    final color = presetColors[_index % presetColors.length];
    _index++;
    return color;
  }

  static void resetIndex() {
    _index = 0;
  }

  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
  }

  static Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) {
      buffer.write(hex.replaceFirst('#', ''));
    }
    return Color(int.parse('FF${buffer.toString()}', radix: 16));
  }
}