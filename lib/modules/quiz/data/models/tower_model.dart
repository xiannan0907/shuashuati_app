import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'tower_model.g.dart';

enum TowerNodeType {
  normal,   // 普通战斗
  elite,    // 精英战斗
  boss,     // Boss（每5层）
  rest,     // 休息点
  event,    // 随机事件
  treasure, // 宝箱
  trap,     // 陷阱
  shop,     // 商店
}

@HiveType(typeId: 3)
class TowerProgress {
  @HiveField(0)
  int currentFloor;

  @HiveField(1)
  int correctCount;

  @HiveField(2)
  int wrongCount;

  @HiveField(3)
  int totalCorrect;

  @HiveField(4)
  int totalWrong;

  @HiveField(5)
  int maxFloor;

  @HiveField(6)
  List<String> usedQuestionIds;

  @HiveField(7)
  int currentQuestionIndex;

  @HiveField(8)
  int hp;

  @HiveField(9)
  int maxHp;

  @HiveField(10)
  int appleCount;

  @HiveField(11)
  int shieldCount;

  @HiveField(12)
  int doubleExpCount;

  @HiveField(13)
  int lastRestFloor;

  @HiveField(14)
  int currentNodeIndex;

  @HiveField(15)
  List<int> completedNodeIndices;

  @HiveField(16)
  int floorNodeCount;

  @HiveField(17)
  bool isBossDefeated;

  TowerProgress({
    this.currentFloor = 1,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.totalCorrect = 0,
    this.totalWrong = 0,
    this.maxFloor = 1,
    List<String>? usedQuestionIds,
    this.currentQuestionIndex = 0,
    this.hp = 5,
    this.maxHp = 5,
    this.appleCount = 0,
    this.shieldCount = 0,
    this.doubleExpCount = 0,
    this.lastRestFloor = 0,
    this.currentNodeIndex = 0,
    List<int>? completedNodeIndices,
    this.floorNodeCount = 4,
    this.isBossDefeated = false,
  }) : usedQuestionIds = usedQuestionIds ?? [],
        completedNodeIndices = completedNodeIndices ?? [];

  int get requiredCorrect {
    return isBossFloor ? 5 : 3;
  }

  int get maxWrong => 3;

  bool get isFloorComplete => correctCount >= requiredCorrect;

  bool get isFloorFailed => hp <= 0;

  double get floorProgress => correctCount / requiredCorrect;

  bool get isBossFloor => currentFloor % 5 == 0;

  bool get isRestFloor => currentFloor % 3 == 0 && currentFloor != 0;

  bool get isAllNodesCompleted {
    return completedNodeIndices.length >= floorNodeCount;
  }

  String get title {
    if (maxFloor >= 100) return '👑 传说勇者';
    if (maxFloor >= 80) return '🏅 殿堂英雄';
    if (maxFloor >= 60) return '🧙 博学法师';
    if (maxFloor >= 40) return '🔥 烈焰领主';
    if (maxFloor >= 20) return '💎 钻石骑士';
    if (maxFloor >= 10) return '⚔️ 翡翠剑士';
    if (maxFloor >= 5) return '🛡️ 基石护卫';
    return '🗡️ 初心勇者';
  }

  TowerProgress copyWith({
    int? currentFloor,
    int? correctCount,
    int? wrongCount,
    int? totalCorrect,
    int? totalWrong,
    int? maxFloor,
    List<String>? usedQuestionIds,
    int? currentQuestionIndex,
    int? hp,
    int? maxHp,
    int? appleCount,
    int? shieldCount,
    int? doubleExpCount,
    int? lastRestFloor,
    int? currentNodeIndex,
    List<int>? completedNodeIndices,
    int? floorNodeCount,
    bool? isBossDefeated,
  }) {
    return TowerProgress(
      currentFloor: currentFloor ?? this.currentFloor,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalWrong: totalWrong ?? this.totalWrong,
      maxFloor: maxFloor ?? this.maxFloor,
      usedQuestionIds: usedQuestionIds ?? List.from(this.usedQuestionIds),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      appleCount: appleCount ?? this.appleCount,
      shieldCount: shieldCount ?? this.shieldCount,
      doubleExpCount: doubleExpCount ?? this.doubleExpCount,
      lastRestFloor: lastRestFloor ?? this.lastRestFloor,
      currentNodeIndex: currentNodeIndex ?? this.currentNodeIndex,
      completedNodeIndices: completedNodeIndices ?? List.from(this.completedNodeIndices),
      floorNodeCount: floorNodeCount ?? this.floorNodeCount,
      isBossDefeated: isBossDefeated ?? this.isBossDefeated,
    );
  }

  void resetFloor() {
    correctCount = 0;
    wrongCount = 0;
    currentQuestionIndex = 0;
    currentNodeIndex = 0;
    completedNodeIndices.clear();
    isBossDefeated = false;
    hp = maxHp;
  }

  bool useApple() {
    if (appleCount > 0 && hp < maxHp) {
      appleCount--;
      hp = (hp + 1).clamp(0, maxHp);
      return true;
    }
    return false;
  }

  bool useShield() {
    if (shieldCount > 0) {
      shieldCount--;
      return true;
    }
    return false;
  }

  bool useDoubleExp() {
    if (doubleExpCount > 0) {
      doubleExpCount--;
      return true;
    }
    return false;
  }

  bool rest() {
    if (hp < maxHp) {
      hp = (hp + 1).clamp(0, maxHp);
      lastRestFloor = currentFloor;
      return true;
    }
    return false;
  }

  // ============================================================
  // ✅ 节点生成（修复：Boss只在最后节点，且仅Boss层）
  // ============================================================
  TowerNodeType getNodeType(int index) {
    // 如果是Boss层，最后一个节点一定是Boss
    if (isBossFloor && index == floorNodeCount - 1) {
      return TowerNodeType.boss;
    }

    // 非Boss层，普通节点
    if (index == floorNodeCount - 1) {
      // 最后一层不是Boss时，用精英怪
      return TowerNodeType.elite;
    }

    // 基于层数和索引生成不同节点
    final seed = currentFloor * 7 + index * 13 + currentFloor ~/ 5;
    final rand = seed % 100;

    // 第一层固定：战斗→事件→精英
    if (currentFloor == 1) {
      if (index == 0) return TowerNodeType.normal;
      if (index == 1) return TowerNodeType.event;
      if (index == 2) return TowerNodeType.elite;
      return TowerNodeType.normal;
    }

    // 其他层随机
    if (rand < 10 && index > 0 && index < floorNodeCount - 1) {
      return TowerNodeType.treasure;
    } else if (rand < 18 && index > 0 && index < floorNodeCount - 1) {
      return TowerNodeType.trap;
    } else if (rand < 30 && index > 0 && index < floorNodeCount - 1) {
      return TowerNodeType.shop;
    } else if (rand < 45 && index > 0 && index < floorNodeCount - 1) {
      return TowerNodeType.event;
    } else if (rand < 55 && index > 0 && index < floorNodeCount - 1) {
      return TowerNodeType.rest;
    } else if (rand < 70 && index > 0 && index < floorNodeCount - 1 && !isBossFloor) {
      return TowerNodeType.elite;
    } else {
      return TowerNodeType.normal;
    }
  }

  bool isNodeAccessible(int index) {
    if (index == 0) return true;
    return completedNodeIndices.contains(index - 1);
  }

  bool isNodeCompleted(int index) {
    return completedNodeIndices.contains(index);
  }

  bool isCurrentNode(int index) {
    return currentNodeIndex == index;
  }

  String getNodeIcon(TowerNodeType type) {
    switch (type) {
      case TowerNodeType.normal: return '⚔️';
      case TowerNodeType.elite: return '💀';
      case TowerNodeType.boss: return '👑';
      case TowerNodeType.rest: return '⛺';
      case TowerNodeType.event: return '❓';
      case TowerNodeType.treasure: return '🎁';
      case TowerNodeType.trap: return '⚠️';
      case TowerNodeType.shop: return '🏪';
    }
  }

  String getNodeName(TowerNodeType type) {
    switch (type) {
      case TowerNodeType.normal: return '战斗';
      case TowerNodeType.elite: return '精英';
      case TowerNodeType.boss: return '魔王';
      case TowerNodeType.rest: return '休息';
      case TowerNodeType.event: return '事件';
      case TowerNodeType.treasure: return '宝箱';
      case TowerNodeType.trap: return '陷阱';
      case TowerNodeType.shop: return '商店';
    }
  }

  Color getNodeColor(TowerNodeType type) {
    switch (type) {
      case TowerNodeType.normal: return Colors.blue;
      case TowerNodeType.elite: return Colors.deepPurple;
      case TowerNodeType.boss: return Colors.red;
      case TowerNodeType.rest: return Colors.green;
      case TowerNodeType.event: return Colors.orange;
      case TowerNodeType.treasure: return Colors.amber;
      case TowerNodeType.trap: return Colors.redAccent;
      case TowerNodeType.shop: return Colors.cyan;
    }
  }

  String getBossName() {
    final bosses = [
      '🔥 炎之魔王', '❄️ 冰之魔王', '⚡ 雷之魔王',
      '🌪️ 风之魔王', '🌑 暗之魔王', '💀 死灵魔王',
      '🐉 龙之魔王', '👹 鬼之魔王', '🧙 魔导师',
      '⚔️ 剑之魔王'
    ];
    return bosses[currentFloor ~/ 5 % bosses.length];
  }

  int getBossHp() {
    return 3 + (currentFloor ~/ 5);
  }
}