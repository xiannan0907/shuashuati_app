import 'package:flutter/material.dart';

/// Portalborn 模块尺寸/间距/布局常量
class PortalbornSizes {
  // ─── 最大宽度（桌面/平板自适应） ───
  static const double maxContentWidth = 800.0;

  // ─── 间距 ───
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // ─── 圆角 ───
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;

  // ─── 边框宽度 ───
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;

  // ─── 字体大小 ───
  static const double fontSizeSmall = 13.0;
  static const double fontSizeBody = 15.0;
  static const double fontSizeDescription = 16.0;
  static const double fontSizeBattleLog = 15.0;
  static const double fontSizeCommand = 16.0;
  static const double fontSizeHeading = 22.0;
  static const double fontSizeTitle = 28.0;

  // ─── 行高 ───
  static const double lineHeightDescription = 1.6;
  static const double lineHeightBody = 1.5;
  static const double lineHeightBattleLog = 1.4;

  // ─── 终端 ───
  static const double terminalHeight = 120.0;
  static const double terminalMaxLines = 8;

  // ─── 按钮 ───
  static const double buttonHeight = 44.0;
  static const double buttonMinWidth = 60.0;

  // ─── 状态栏 ───
  static const double statusBarHeight = 56.0;
}

/// Portalborn 模块字体常量（使用等宽字体）
class PortalbornFonts {
  static const String monospace = 'RobotoMono';
  static const String fallback = 'monospace';

  /// 获取等宽字体族
  static const List<String> monospaceFamily = [
    'RobotoMono',
    'monospace',
  ];
}

/// Portalborn 模块动画时长常量
class PortalbornDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration typewriter = Duration(milliseconds: 25); // 打字机效果每个字符
  static const Duration autoSaveDebounce = Duration(seconds: 5);
}

/// Portalborn 模块游戏数值常量
class PortalbornGameConstants {
  // ─── 背包 ───
  static const int maxInventorySize = 20;

  // ─── 角色 ───
  static const int initialLevel = 1;
  static const int initialStatPoints = 10;
  static const int statPointsPerLevel = 3;

  // ─── 升级经验公式: level × 15 + 10 ───
  static int expForLevel(int level) => level * 15 + 10;

  // ─── 属性影响 ───
  static const double strengthAtkModifier = 0.5; // (STR - 5) × 0.5
  static const double dexDodgeModifier = 0.005; // DEX × 0.5%
  static const double dexCritModifier = 0.003; // 5% + DEX × 0.3%
  static const double intSpellModifier = 0.6; // (INT - 5) × 0.6
  static const double conHpModifier = 2.0; // CON × 2
  static const double conRecoveryModifier = 0.3; // 1 + CON × 0.3

  // ─── 战斗 ───
  static const double baseCritChance = 0.05; // 5%
  static const double baseDodgeChance = 0.0;
  static const double baseBlockChance = 0.05; // 5%
  static const double blockDamageReduction = 0.5; // 格挡减半
  static const double defendDamageReduction = 0.5; // 防御姿态减半
  static const double fleeBaseChance = 0.3; // 30%
  static const double fleeDexBonus = 0.02; // 每点 DEX +2%
  static const double fleeMaxChance = 0.9; // 最高 90%
  static const double fleeFailureBonus = 0.1; // 逃跑失败后 +10%

  // ─── 死亡惩罚 ───
  static const double deathMaterialLoss = 0.5; // 失去 50% 材料
  static const double deathGoldLoss = 0.3; // 失去 30% 金币
  static const double deathHpRecovery = 0.5; // HP 恢复至 50%

  // ─── 领域生成 ───
  static const int minRoomsPerRealm = 2;
  static const int maxRoomsPerRealm = 7;
  static const int defaultRoomsPerRealm = 4;

  // ─── 搜索发现 ───
  static const double baseSearchDiscoverChance = 0.3; // 30%
  static const double intSearchBonus = 0.1; // INT 角色 +10%
}

/// Portalborn 模块路由名称常量
class PortalbornRoutes {
  static const String main = '/portalborn';
  static const String hub = '/portalborn/hub';
  static const String explore = '/portalborn/explore';
  static const String battle = '/portalborn/battle';
  static const String inventory = '/portalborn/inventory';
  static const String crafting = '/portalborn/crafting';
  static const String workshop = '/portalborn/workshop';
  static const String lore = '/portalborn/lore';
  static const String ugcEditor = '/portalborn/ugc-editor';
}