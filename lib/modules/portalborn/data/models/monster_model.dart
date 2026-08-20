/// 怪物模板（种子数据）
class MonsterTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int baseHp;
  final int attack;
  final int defense;
  final int expReward;
  final int goldReward;
  final List<DropTable> drops;
  final List<String> tags;
  final double scaleFactor;
  final String? specialAbility;
  final int abilityCooldown;
  final int abilityDamage;

  MonsterTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.baseHp = 10,
    this.attack = 3,
    this.defense = 1,
    this.expReward = 5,
    this.goldReward = 2,
    this.drops = const [],
    this.tags = const [],
    this.scaleFactor = 1.0,
    this.specialAbility,
    this.abilityCooldown = 0,
    this.abilityDamage = 0,
  });

  MonsterInstance createInstance(int playerLevel) {
    final scale = 1.0 + (playerLevel - 1) * 0.08 * scaleFactor;
    return MonsterInstance(
      template: this,
      currentHp: (baseHp * scale).round(),
      currentAttack: (attack * scale).round(),
      currentDefense: (defense * scale).round(),
      abilityTimer: abilityCooldown,
    );
  }
}

/// 掉落表
class DropTable {
  final String itemId;
  final double probability;
  final int minCount;
  final int maxCount;

  DropTable({
    required this.itemId,
    required this.probability,
    this.minCount = 1,
    this.maxCount = 1,
  });
}

/// 怪物实例（运行时）
class MonsterInstance {
  final MonsterTemplate template;
  int currentHp;
  int currentAttack;
  int currentDefense;
  int abilityTimer;
  bool isDead;

  MonsterInstance({
    required this.template,
    required this.currentHp,
    required this.currentAttack,
    required this.currentDefense,
    this.abilityTimer = 0,
    this.isDead = false,
  });

  factory MonsterInstance.fromTemplate(MonsterTemplate template, int playerLevel) {
    return template.createInstance(playerLevel);
  }

  MonsterInstance copyWith({
    MonsterTemplate? template,
    int? currentHp,
    int? currentAttack,
    int? currentDefense,
    int? abilityTimer,
    bool? isDead,
  }) {
    return MonsterInstance(
      template: template ?? this.template,
      currentHp: currentHp ?? this.currentHp,
      currentAttack: currentAttack ?? this.currentAttack,
      currentDefense: currentDefense ?? this.currentDefense,
      abilityTimer: abilityTimer ?? this.abilityTimer,
      isDead: isDead ?? this.isDead,
    );
  }

  // ─── 便捷 getter ───
  String get name => template.name;
  String get emoji => template.emoji;
  String get description => template.description;
  int get expReward => template.expReward;
  int get goldReward => template.goldReward;
  List<DropTable> get drops => template.drops;
  List<String> get tags => template.tags;
  String? get specialAbility => template.specialAbility;

  /// HP 百分比 (0.0 - 1.0)
  double get hpPercent {
    if (template.baseHp <= 0) return 0.0;
    return currentHp.clamp(0, template.baseHp) / template.baseHp;
  }

  /// 是否为 Boss
  bool get isBoss => tags.contains('boss');

// ⚠️ 注意：isDead 已作为字段存在，不再重复定义 getter
}