import 'package:flutter/material.dart';

/// Portalborn 模块专属颜色方案
///
/// 不污染全局 AppTheme，通过 Theme.of(context).brightness 适配亮/暗模式
class PortalbornColors {
  // ─── 主色调 ───
  static const Color primary = Color(0xFF00ff88); // 翠绿 - 成功/正向/品牌色
  static const Color danger = Color(0xFFff3355); // 红 - 错误/危险/死亡
  static const Color warning = Color(0xFFffaa33); // 橙黄 - 警告/重要
  static const Color info = Color(0xFF44aaff); // 蓝 - 信息/链接
  static const Color magic = Color(0xFFaa55ff); // 紫 - 魔法/稀有

  // ─── 背景色（暗色主题默认） ───
  static const Color backgroundDark = Color(0xFF0a0a0f); // 极深黑
  static const Color cardDark = Color(0xFF141425); // 深紫黑
  static const Color borderDark = Color(0xFF2a2a4a); // 暗紫灰边框

  // ─── 背景色（亮色主题） ───
  static const Color backgroundLight = Color(0xFFf5f3f0); // 暖白
  static const Color cardLight = Color(0xFFffffff); // 纯白
  static const Color borderLight = Color(0xFFd0ccc8); // 暖灰边框

  // ─── 文本色 ───
  static const Color textDark = Color(0xFFc8d0d8); // 柔和灰白
  static const Color textLight = Color(0xFF1a1a2e); // 深紫黑

  // ─── 终端风格 ───
  static const Color terminalBg = Color(0xFF0a0a0f);
  static const Color terminalText = Color(0xFFc8d0d8);
  static const Color terminalPrompt = Color(0xFF00ff88);
  static const Color terminalError = Color(0xFFff3355);

  /// 根据 Brightness 获取背景色
  static Color background(Brightness brightness) {
    return brightness == Brightness.dark ? backgroundDark : backgroundLight;
  }

  /// 根据 Brightness 获取卡片色
  static Color card(Brightness brightness) {
    return brightness == Brightness.dark ? cardDark : cardLight;
  }

  /// 根据 Brightness 获取边框色
  static Color border(Brightness brightness) {
    return brightness == Brightness.dark ? borderDark : borderLight;
  }

  /// 根据 Brightness 获取主文本色
  static Color text(Brightness brightness) {
    return brightness == Brightness.dark ? textDark : textLight;
  }

  /// 根据 Brightness 获取次级文本色（用于描述/提示）
  static Color textSecondary(Brightness brightness) {
    return brightness == Brightness.dark
        ? textDark.withValues(alpha: 0.7)
        : textLight.withValues(alpha: 0.7);
  }

  /// 根据 Brightness 获取 HP 条渐变色
  static List<Color> hpGradient(Brightness brightness) {
    return const [
      Color(0xFF00ff88),
      Color(0xFF44ffaa),
      Color(0xFF88ffcc),
    ];
  }

  /// 根据 Brightness 获取战斗日志背景色
  static Color battleLogBg(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF0d0d1a)
        : const Color(0xFFf0eee8);
  }
}