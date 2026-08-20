import 'dart:math';

import '../data/models/character_model.dart';
import '../data/models/monster_model.dart';
import '../data/models/item_model.dart';
import '../data/models/realm_model.dart';

/// Portalborn 游戏核心引擎
///
/// 负责所有游戏计算：伤害、战斗、升级、掉落等
/// 所有计算都是纯函数，不涉及状态管理
class GameEngine {
  static final Random _random = Random();

  // ═══════════════════════════════════════════════════════════════
  // 📊 属性计算
  // ═══════════════════════════════════════════════════════════════

  /// 计算总攻击力（基础 + 武器加成）
  static int calculateTotalAttack(GameCharacter character, GameItem? weapon) {
    var total = character.baseAttack;
    if (weapon != null) {
      total += weapon.atkBonus;
    }
    // 力量加成: (STR - 5) × 0.5
    final strBonus = ((character.strength - 5) * 0.5).round();
    total += max(0, strBonus);
    return max(1, total);
  }

  /// 计算总防御力（基础 + 护甲加成）
  static int calculateTotalDefense(GameCharacter character, GameItem? armor) {
    var total = character.baseDefense;
    if (armor != null) {
      total += armor.defBonus;
    }
    // 体质加成: (CON - 5) × 0.3
    final conBonus = ((character.constitution - 5) * 0.3).round();
    total += max(0, conBonus);
    return max(0, total);
  }

  /// 计算最大 HP
  static int calculateMaxHp(GameCharacter character) {
    // 基础 20 + CON × 2 + 等级 × (3 + CON × 0.2)
    final base = 20 + character.constitution * 2;
    final levelBonus = (character.level * (3 + character.constitution * 0.2)).round();
    return base + levelBonus;
  }

  /// 获取装备物品
  static GameItem? getWeapon(GameCharacter character, List<GameItem> inventory) {
    if (character.weaponId == null) return null;
    try {
      return inventory.firstWhere((i) => i.id == character.weaponId);
    } catch (_) {
      return null;
    }
  }

  static GameItem? getArmor(GameCharacter character, List<GameItem> inventory) {
    if (character.armorId == null) return null;
    try {
      return inventory.firstWhere((i) => i.id == character.armorId);
    } catch (_) {
      return null;
    }
  }

  static GameItem? getAccessory(GameCharacter character, List<GameItem> inventory) {
    if (character.accessoryId == null) return null;
    try {
      return inventory.firstWhere((i) => i.id == character.accessoryId);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 💥 伤害计算
  // ═══════════════════════════════════════════════════════════════

  /// 物理伤害计算
  static DamageResult calculatePhysicalDamage({
    required int attackerAtk,
    required int defenderDef,
    int attackerDex = 0,
    int defenderDex = 0,
    int attackerCon = 0,
    bool isGuaranteedHit = false,
    bool isGuaranteedCrit = false,
  }) {
    // 1. 闪避判定
    if (!isGuaranteedHit) {
      final dodgeChance = defenderDex * 0.005; // DEX × 0.5%
      if (_random.nextDouble() < dodgeChance) {
        return DamageResult.miss('攻击被闪避了！');
      }
    }

    // 2. 基础伤害: max(1, ATK - DEF/2)
    var damage = max(1, attackerAtk - (defenderDef ~/ 2));

    // 3. 随机波动: -1 ~ +2
    damage += _random.nextInt(4) - 1;

    // 4. 暴击判定
    bool isCrit = isGuaranteedCrit || _checkCrit(attackerDex);
    if (isCrit) {
      damage = (damage * 1.8).round();
    }

    // 5. 格挡判定（防御者）
    final blockChance = 0.05 + attackerCon * 0.002; // 5% + CON × 0.2%
    if (!isGuaranteedHit && _random.nextDouble() < blockChance) {
      damage = (damage * 0.5).round();
      return DamageResult.blocked(damage, '你格挡了攻击！受到 $damage 点伤害。');
    }

    damage = max(1, damage);

    if (isCrit) {
      return DamageResult.crit(damage, '💥 暴击！造成 $damage 点伤害！');
    }
    return DamageResult.normal(damage, '造成 $damage 点伤害。');
  }

  /// 法术伤害计算
  static DamageResult calculateSpellDamage({
    required int casterInt,
    required int spellPower,
    required int targetInt,
    int targetDef = 0,
    int casterLevel = 1,
    bool isGuaranteedHit = false,
  }) {
    // 1. 基础伤害: INT × 0.6 + 法术威力
    var damage = (casterInt * 0.6).round() + spellPower;

    // 2. 魔法抗性: 目标INT × 0.1
    final resistance = (targetInt * 0.1).round();
    damage -= resistance;

    // 3. 等级加成
    damage += (casterLevel * 0.5).round();

    // 4. 随机波动: -2 ~ +2
    damage += _random.nextInt(5) - 2;

    // 5. 最小伤害
    damage = max(2, damage);

    // 6. 法术不可闪避（但可以被抵抗）
    if (!isGuaranteedHit && _random.nextDouble() < 0.05) {
      return DamageResult.miss('目标抵抗了法术！');
    }

    return DamageResult.normal(damage, '✨ 法术造成 $damage 点伤害！');
  }

  /// 检查是否暴击
  static bool _checkCrit(int dex) {
    // 基础 5% + DEX × 0.3%
    final critChance = 0.05 + dex * 0.003;
    return _random.nextDouble() < critChance;
  }

  // ═══════════════════════════════════════════════════════════════
  // ⚔️ 战斗系统
  // ═══════════════════════════════════════════════════════════════

  /// 执行一个战斗回合
  static BattleResult executeBattleTurn({
    required GameCharacter player,
    required MonsterInstance monster,
    required List<GameItem> inventory,
    required String action,
    int? spellPower,
    String? spellName,
  }) {
    // 获取装备
    final weapon = getWeapon(player, inventory);
    final armor = getArmor(player, inventory);

    // 计算属性
    final playerAtk = calculateTotalAttack(player, weapon);
    final playerDef = calculateTotalDefense(player, armor);
    final playerDex = player.dexterity;
    final playerCon = player.constitution;
    final playerInt = player.intelligence;

    // 玩家行动
    DamageResult playerDamage;

    switch (action) {
      case 'attack':
        playerDamage = calculatePhysicalDamage(
          attackerAtk: playerAtk,
          defenderDef: monster.currentDefense,
          attackerDex: playerDex,
          defenderDex: 0, // 怪物没有闪避
          attackerCon: playerCon,
        );
        monster.currentHp -= playerDamage.damage;
        break;

      case 'spell':
        final power = spellPower ?? 10;
        playerDamage = calculateSpellDamage(
          casterInt: playerInt,
          spellPower: power,
          targetInt: 0, // 怪物没有魔法抗性
          casterLevel: player.level,
        );
        monster.currentHp -= playerDamage.damage;
        break;

      case 'defend':
        playerDamage = DamageResult.zero('🛡️ 你进入防御姿态。');
        break;

      case 'flee':
        final success = tryFlee(playerDex);
        if (success) {
          return BattleResult.fleeSuccess('你成功逃离了战斗！');
        } else {
          // 逃跑失败，怪物攻击
          final monsterDmg = calculatePhysicalDamage(
            attackerAtk: monster.currentAttack,
            defenderDef: playerDef,
            attackerDex: 0,
            defenderDex: playerDex,
            attackerCon: 0,
          );
          player.currentHp -= monsterDmg.damage;
          return BattleResult.fleeFailed(
            '逃跑失败！你被攻击了！',
            monsterDamage: monsterDmg,
          );
        }

      default:
        return BattleResult.invalid('无效的行动。');
    }

    // 判断怪物是否死亡
    if (monster.currentHp <= 0) {
      monster.isDead = true;
      monster.currentHp = 0;
      return BattleResult.playerWins(
        '🎉 你击败了 ${monster.name}！',
        playerDamage: playerDamage,
        expGained: monster.expReward,
        goldGained: monster.goldReward,
      );
    }

    // 怪物反击（防御姿态减伤50%）
    DamageResult monsterDamage;
    if (action == 'defend') {
      final reducedDef = (playerDef * 1.5).round();
      monsterDamage = calculatePhysicalDamage(
        attackerAtk: monster.currentAttack,
        defenderDef: reducedDef,
        attackerDex: 0,
        defenderDex: playerDex,
        attackerCon: 0,
      );
      // 防御姿态额外减伤
      monsterDamage = DamageResult.normal(
        (monsterDamage.damage * 0.5).round(),
        '你抵挡了攻击！受到 ${(monsterDamage.damage * 0.5).round()} 点伤害。',
      );
    } else {
      monsterDamage = calculatePhysicalDamage(
        attackerAtk: monster.currentAttack,
        defenderDef: playerDef,
        attackerDex: 0,
        defenderDex: playerDex,
        attackerCon: 0,
      );
    }
    player.currentHp -= monsterDamage.damage;

    // 判断玩家是否死亡
    if (player.currentHp <= 0) {
      player.currentHp = 0;
      return BattleResult.monsterWins(
        '💀 你被 ${monster.name} 击败了...',
        monsterDamage: monsterDamage,
      );
    }

    // 战斗继续
    return BattleResult.ongoing(
      '战斗继续...',
      playerDamage: playerDamage,
      monsterDamage: monsterDamage,
      playerHp: player.currentHp,
      monsterHp: monster.currentHp,
    );
  }

  /// 尝试逃跑
  static bool tryFlee(int dex) {
    // 基础 30% + DEX × 2%，最高 90%
    var chance = 0.3 + dex * 0.02;
    chance = min(chance, 0.9);
    return _random.nextDouble() < chance;
  }

  // ═══════════════════════════════════════════════════════════════
  // 📈 升级系统
  // ═══════════════════════════════════════════════════════════════

  /// 计算升级所需经验
  static int expForLevel(int level) {
    return level * 15 + 10;
  }

  /// 检查是否升级，返回升级结果
  /// 检查是否升级，返回升级结果
  static LevelUpResult checkLevelUp(GameCharacter player) {
    final expNeeded = expForLevel(player.level);
    if (player.exp >= expNeeded) {
      final newLevel = player.level + 1;
      final remainingExp = player.exp - expNeeded;

      // 属性增长（全部取整为 int）
      final hpGain = 5 + (player.constitution * 0.5).round();
      final atkGain = (0.5 + player.strength * 0.1).round();
      final defGain = (0.3 + player.constitution * 0.05).round();

      return LevelUpResult.success(
        newLevel: newLevel,
        remainingExp: remainingExp,
        hpGain: hpGain,
        atkGain: atkGain,
        defGain: defGain,
        pointsGained: 3,
      );
    }
    return LevelUpResult.none();
  }
  /// 应用升级
  static GameCharacter applyLevelUp(GameCharacter player, LevelUpResult result) {
    if (!result.isSuccess) return player;
    return player.copyWith(
      level: result.newLevel,
      exp: result.remainingExp,
      maxHp: player.maxHp + result.hpGain,
      currentHp: player.currentHp + result.hpGain,
      baseAttack: player.baseAttack + result.atkGain,
      baseDefense: player.baseDefense + result.defGain,
      availablePoints: player.availablePoints + result.pointsGained,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 💀 死亡处理
  // ═══════════════════════════════════════════════════════════════

  /// 处理死亡惩罚
  static DeathResult applyDeathPenalty(GameCharacter player) {
    // 失去 50% 材料
    final materials = Map<String, int>.from(player.materials);
    materials.forEach((key, value) {
      materials[key] = (value * 0.5).floor();
      if (materials[key] == 0) materials.remove(key);
    });

    // 失去 30% 金币
    final goldLost = (player.gold * 0.3).floor();

    return DeathResult(
      materialsLost: materials,
      goldLost: goldLost,
      hpRecovery: (player.maxHp * 0.5).ceil(),
    );
  }

  /// 应用死亡惩罚
  static GameCharacter applyDeath(GameCharacter player, DeathResult result) {
    return player.copyWith(
      materials: result.materialsLost,
      gold: player.gold - result.goldLost,
      currentHp: result.hpRecovery,
      totalDeaths: player.totalDeaths + 1,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎁 战利品系统
  // ═══════════════════════════════════════════════════════════════

  /// 生成掉落物品
  static List<DropResult> generateDrops(
      List<DropTable> dropTable,
      double luckMultiplier,
      ) {
    final results = <DropResult>[];

    for (final drop in dropTable) {
      final adjustedProb = min(1.0, drop.probability * luckMultiplier);
      if (_random.nextDouble() < adjustedProb) {
        final count = drop.minCount +
            _random.nextInt(drop.maxCount - drop.minCount + 1);
        results.add(DropResult(
          itemId: drop.itemId,
          count: count,
        ));
      }
    }

    return results;
  }

  /// 生成 Boss 奖励（核心奖励）
  static BossReward generateBossReward(int difficulty, int playerLevel) {
    final baseGold = 10 + difficulty * 5 + _random.nextInt(10);
    final baseExp = 20 + difficulty * 10 + _random.nextInt(15);

    // 根据难度决定奖励品质
    final bonusMultiplier = 1 + (playerLevel - 1) * 0.1;
    final gold = (baseGold * bonusMultiplier).round();
    final exp = (baseExp * bonusMultiplier).round();

    // 可能有稀有掉落
    final hasRareDrop = _random.nextDouble() < (0.1 + difficulty * 0.05);

    return BossReward(
      gold: gold,
      exp: exp,
      hasRareDrop: hasRareDrop,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🌟 其他辅助计算
  // ═══════════════════════════════════════════════════════════════

  /// 计算领域奖励
  static RealmReward calculateRealmReward(Realm realm, int playerLevel) {
    final baseExp = 20 + realm.difficulty * 10;
    final baseGold = 10 + realm.difficulty * 5;
    final bonusMultiplier = 1 + (playerLevel - 1) * 0.1;

    return RealmReward(
      expGained: (baseExp * bonusMultiplier).round(),
      goldGained: (baseGold * bonusMultiplier).round(),
      itemDrops: [],
    );
  }

  /// 计算每日运势加成
  static FortuneBonus calculateFortuneBonus(String fortuneId) {
    switch (fortuneId) {
      case 'lucky':
        return FortuneBonus(dropRate: 1.2, critRate: 0.05);
      case 'unlucky':
        return FortuneBonus(dropRate: 0.8, enemyAtkBonus: 2);
      case 'wise':
        return FortuneBonus(expRate: 1.3);
      case 'rich':
        return FortuneBonus(goldRate: 1.5);
      case 'brave':
        return FortuneBonus(atkBonus: 3);
      default:
        return FortuneBonus.empty();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 📦 结果数据类
// ═══════════════════════════════════════════════════════════════

/// 伤害结果
class DamageResult {
  final int damage;
  final String message;
  final bool isCrit;
  final bool isMiss;
  final bool isBlocked;

  DamageResult._({
    required this.damage,
    required this.message,
    this.isCrit = false,
    this.isMiss = false,
    this.isBlocked = false,
  });

  factory DamageResult.normal(int damage, String message) {
    return DamageResult._(
      damage: max(0, damage),
      message: message,
    );
  }

  factory DamageResult.crit(int damage, String message) {
    return DamageResult._(
      damage: max(0, damage),
      message: message,
      isCrit: true,
    );
  }

  factory DamageResult.miss(String message) {
    return DamageResult._(
      damage: 0,
      message: message,
      isMiss: true,
    );
  }

  factory DamageResult.blocked(int damage, String message) {
    return DamageResult._(
      damage: max(0, damage),
      message: message,
      isBlocked: true,
    );
  }

  factory DamageResult.zero(String message) {
    return DamageResult._(
      damage: 0,
      message: message,
    );
  }
}

/// 战斗结果
class BattleResult {
  final BattleOutcome outcome;
  final String message;
  final DamageResult? playerDamage;
  final DamageResult? monsterDamage;
  final int? expGained;
  final int? goldGained;
  final int? playerHp;
  final int? monsterHp;

  BattleResult._({
    required this.outcome,
    required this.message,
    this.playerDamage,
    this.monsterDamage,
    this.expGained,
    this.goldGained,
    this.playerHp,
    this.monsterHp,
  });

  // 战斗继续
  factory BattleResult.ongoing(
      String message, {
        DamageResult? playerDamage,
        DamageResult? monsterDamage,
        int? playerHp,
        int? monsterHp,
      }) {
    return BattleResult._(
      outcome: BattleOutcome.ongoing,
      message: message,
      playerDamage: playerDamage,
      monsterDamage: monsterDamage,
      playerHp: playerHp,
      monsterHp: monsterHp,
    );
  }

  // 玩家胜利
  factory BattleResult.playerWins(
      String message, {
        DamageResult? playerDamage,
        int? expGained,
        int? goldGained,
      }) {
    return BattleResult._(
      outcome: BattleOutcome.playerWins,
      message: message,
      playerDamage: playerDamage,
      expGained: expGained ?? 0,
      goldGained: goldGained ?? 0,
    );
  }

  // 怪物胜利（玩家死亡）
  factory BattleResult.monsterWins(
      String message, {
        DamageResult? monsterDamage,
      }) {
    return BattleResult._(
      outcome: BattleOutcome.monsterWins,
      message: message,
      monsterDamage: monsterDamage,
    );
  }

  // 逃跑成功
  factory BattleResult.fleeSuccess(String message) {
    return BattleResult._(
      outcome: BattleOutcome.fled,
      message: message,
    );
  }

  // 逃跑失败
  factory BattleResult.fleeFailed(
      String message, {
        DamageResult? monsterDamage,
      }) {
    return BattleResult._(
      outcome: BattleOutcome.fleeFailed,
      message: message,
      monsterDamage: monsterDamage,
    );
  }

  // 无效行动
  factory BattleResult.invalid(String message) {
    return BattleResult._(
      outcome: BattleOutcome.invalid,
      message: message,
    );
  }

  bool get isOngoing => outcome == BattleOutcome.ongoing;
  bool get isPlayerWin => outcome == BattleOutcome.playerWins;
  bool get isMonsterWin => outcome == BattleOutcome.monsterWins;
  bool get isFled => outcome == BattleOutcome.fled;
  bool get isFleeFailed => outcome == BattleOutcome.fleeFailed;
  bool get isInvalid => outcome == BattleOutcome.invalid;
}

enum BattleOutcome {
  ongoing,
  playerWins,
  monsterWins,
  fled,
  fleeFailed,
  invalid,
}

/// 升级结果
class LevelUpResult {
  final bool isSuccess;
  final int newLevel;
  final int remainingExp;
  final int hpGain;
  final int atkGain;
  final int defGain;
  final int pointsGained;

  LevelUpResult._({
    required this.isSuccess,
    this.newLevel = 0,
    this.remainingExp = 0,
    this.hpGain = 0,
    this.atkGain = 0,
    this.defGain = 0,
    this.pointsGained = 0,
  });

  factory LevelUpResult.success({
    required int newLevel,
    required int remainingExp,
    required int hpGain,
    required int atkGain,
    required int defGain,
    required int pointsGained,
  }) {
    return LevelUpResult._(
      isSuccess: true,
      newLevel: newLevel,
      remainingExp: remainingExp,
      hpGain: hpGain,
      atkGain: atkGain,
      defGain: defGain,
      pointsGained: pointsGained,
    );
  }

  factory LevelUpResult.none() {
    return LevelUpResult._(isSuccess: false);
  }

  String get message => '🎉 升级！达到 Lv.$newLevel！\n'
      'HP +$hpGain | ATK +$atkGain | DEF +$defGain\n'
      '获得 $pointsGained 点属性分配！';
}

/// 死亡惩罚结果
class DeathResult {
  final Map<String, int> materialsLost;
  final int goldLost;
  final int hpRecovery;

  DeathResult({
    required this.materialsLost,
    required this.goldLost,
    required this.hpRecovery,
  });
}

/// 掉落结果
class DropResult {
  final String itemId;
  final int count;

  DropResult({required this.itemId, required this.count});
}

/// Boss 奖励
class BossReward {
  final int gold;
  final int exp;
  final bool hasRareDrop;

  BossReward({
    required this.gold,
    required this.exp,
    required this.hasRareDrop,
  });
}

/// 领域奖励
class RealmReward {
  final int expGained;
  final int goldGained;
  final List<DropResult> itemDrops;

  RealmReward({
    required this.expGained,
    required this.goldGained,
    this.itemDrops = const [],
  });
}

/// 运势加成
class FortuneBonus {
  final double dropRate;
  final double expRate;
  final double goldRate;
  final double critRate;
  final int enemyAtkBonus;
  final int atkBonus;

  FortuneBonus({
    this.dropRate = 1.0,
    this.expRate = 1.0,
    this.goldRate = 1.0,
    this.critRate = 0.0,
    this.enemyAtkBonus = 0,
    this.atkBonus = 0,
  });

  factory FortuneBonus.empty() {
    return FortuneBonus();
  }
}