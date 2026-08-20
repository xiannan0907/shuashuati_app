/// 装备词缀系统
///
/// 词缀（Affix）是装备前面的修饰词，如"锋利的铁剑"
/// 每个词缀会给装备增加额外的属性

/// 词缀定义
class EquipmentAffix {
  final String id;
  final String name; // 显示名称，如"锋利"
  final String emoji; // 图标
  final String description; // 描述
  final List<String> applicableTypes; // 适用装备类型: ['weapon', 'armor', 'accessory']
  final Map<String, dynamic> effects; // 属性加成
  final int rarity; // 稀有度: 1=普通, 2=稀有, 3=史诗, 4=传说
  final int tier; // 等级区间: 1=低, 2=中, 3=高
  final double spawnWeight; // 生成权重

  const EquipmentAffix({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.applicableTypes,
    required this.effects,
    this.rarity = 1,
    this.tier = 1,
    this.spawnWeight = 1.0,
  });

  /// 获取加成显示文本
  String get effectDisplay {
    final parts = <String>[];
    effects.forEach((key, value) {
      switch (key) {
        case 'atk':
          parts.add('攻击 +$value');
          break;
        case 'def':
          parts.add('防御 +$value');
          break;
        case 'str':
          parts.add('力量 +$value');
          break;
        case 'dex':
          parts.add('敏捷 +$value');
          break;
        case 'int':
          parts.add('智力 +$value');
          break;
        case 'critRate':
          parts.add('暴击率 +${(value * 100).toInt()}%');
          break;
        case 'dodgeRate':
          parts.add('闪避率 +${(value * 100).toInt()}%');
          break;
        case 'blockRate':
          parts.add('格挡率 +${(value * 100).toInt()}%');
          break;
        case 'lifeSteal':
          parts.add('吸血 +${(value * 100).toInt()}%');
          break;
        case 'hpRegen':
          parts.add('每回合 HP +$value');
          break;
        case 'magicResist':
          parts.add('魔法抗性 +${(value * 100).toInt()}%');
          break;
        case 'dropRate':
          parts.add('掉落率 +${(value * 100).toInt()}%');
          break;
        case 'expRate':
          parts.add('经验 +${(value * 100).toInt()}%');
          break;
        case 'goldRate':
          parts.add('金币 +${(value * 100).toInt()}%');
          break;
        case 'durabilityBonus':
          parts.add('耐久度 +${(value * 100).toInt()}%');
          break;
        case 'elementFire':
          parts.add('火焰伤害 +$value');
          break;
        case 'elementFrost':
          parts.add('寒冰伤害 +$value');
          break;
        case 'elementLightning':
          parts.add('闪电伤害 +$value');
          break;
        case 'holyDamage':
          parts.add('对亡灵伤害 +${(value * 100).toInt()}%');
          break;
        case 'rangedBonus':
          parts.add('远程伤害 +${(value * 100).toInt()}%');
          break;
        default:
          parts.add('$key +$value');
      }
    });
    return parts.join('、');
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 所有词缀数据（按稀有度分组）
/// ═══════════════════════════════════════════════════════════════

final List<EquipmentAffix> affixes = [
  // ─── 普通词缀 (稀有度 1) ────────────────────────────────
  EquipmentAffix(
    id: 'affix_sharp',
    name: '锋利',
    emoji: '⚔️',
    description: '剑刃经过精细打磨，更加锋利。',
    applicableTypes: ['weapon'],
    effects: {'atk': 2},
    rarity: 1,
    tier: 1,
    spawnWeight: 3.0,
  ),
  EquipmentAffix(
    id: 'affix_sturdy',
    name: '坚固',
    emoji: '🛡️',
    description: '材质紧密，更加坚固耐用。',
    applicableTypes: ['armor'],
    effects: {'def': 2},
    rarity: 1,
    tier: 1,
    spawnWeight: 3.0,
  ),
  EquipmentAffix(
    id: 'affix_light',
    name: '轻便',
    emoji: '🌬️',
    description: '重量减轻，灵活度提升。',
    applicableTypes: ['weapon', 'armor'],
    effects: {'dex': 1},
    rarity: 1,
    tier: 1,
    spawnWeight: 2.0,
  ),
  EquipmentAffix(
    id: 'affix_tough',
    name: '坚韧',
    emoji: '💪',
    description: '结构强韧，不易损坏。',
    applicableTypes: ['weapon', 'armor'],
    effects: {'durabilityBonus': 0.2},
    rarity: 1,
    tier: 1,
    spawnWeight: 2.0,
  ),
  EquipmentAffix(
    id: 'affix_balanced',
    name: '均衡',
    emoji: '⚖️',
    description: '各方面性能均衡。',
    applicableTypes: ['weapon'],
    effects: {'atk': 1, 'def': 1},
    rarity: 1,
    tier: 1,
    spawnWeight: 2.0,
  ),

  // ─── 稀有词缀 (稀有度 2) ────────────────────────────────
  EquipmentAffix(
    id: 'affix_mighty',
    name: '强力',
    emoji: '🔥',
    description: '蕴含强大的力量。',
    applicableTypes: ['weapon'],
    effects: {'atk': 4},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.5,
  ),
  EquipmentAffix(
    id: 'affix_heavy',
    name: '厚重',
    emoji: '🪨',
    description: '沉重的装甲，防御力极佳。',
    applicableTypes: ['armor'],
    effects: {'def': 4},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.5,
  ),
  EquipmentAffix(
    id: 'affix_powerful',
    name: '力量',
    emoji: '💥',
    description: '灌注了力量之力。',
    applicableTypes: ['weapon', 'accessory'],
    effects: {'str': 2},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.5,
  ),
  EquipmentAffix(
    id: 'affix_nimble',
    name: '敏捷',
    emoji: '💨',
    description: '提升使用者的灵活性。',
    applicableTypes: ['weapon', 'accessory'],
    effects: {'dex': 2},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.5,
  ),
  EquipmentAffix(
    id: 'affix_wisdom',
    name: '智慧',
    emoji: '🧠',
    description: '提升精神力和魔法能力。',
    applicableTypes: ['weapon', 'accessory'],
    effects: {'int': 2},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.5,
  ),
  EquipmentAffix(
    id: 'affix_precise',
    name: '精准',
    emoji: '🎯',
    description: '攻击更加精准，更容易命中要害。',
    applicableTypes: ['weapon'],
    effects: {'critRate': 0.05},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.2,
  ),
  EquipmentAffix(
    id: 'affix_protective',
    name: '守护',
    emoji: '🛡️',
    description: '额外提供格挡能力。',
    applicableTypes: ['armor', 'accessory'],
    effects: {'def': 2, 'blockRate': 0.05},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.2,
  ),
  EquipmentAffix(
    id: 'affix_silver',
    name: '镀银',
    emoji: '🥈',
    description: '银质镀层，对亡灵有克制效果。',
    applicableTypes: ['weapon'],
    effects: {'atk': 2, 'holyDamage': 0.3},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.0,
  ),
  EquipmentAffix(
    id: 'affix_vampiric',
    name: '吸血',
    emoji: '🩸',
    description: '攻击时吸取生命。',
    applicableTypes: ['weapon'],
    effects: {'atk': 1, 'lifeSteal': 0.08},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.0,
  ),
  EquipmentAffix(
    id: 'affix_steady',
    name: '稳固',
    emoji: '⛰️',
    description: '结构稳固，不易被击退。',
    applicableTypes: ['armor'],
    effects: {'def': 3, 'durabilityBonus': 0.3},
    rarity: 2,
    tier: 2,
    spawnWeight: 1.2,
  ),

  // ─── 史诗词缀 (稀有度 3) ────────────────────────────────
  EquipmentAffix(
    id: 'affix_flame',
    name: '火焰',
    emoji: '🔥',
    description: '缠绕着火焰之力，灼烧敌人。',
    applicableTypes: ['weapon'],
    effects: {'atk': 3, 'elementFire': 5},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.7,
  ),
  EquipmentAffix(
    id: 'affix_frost',
    name: '寒冰',
    emoji: '❄️',
    description: '散发着刺骨寒气，冻结敌人。',
    applicableTypes: ['weapon'],
    effects: {'atk': 3, 'elementFrost': 5},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.7,
  ),
  EquipmentAffix(
    id: 'affix_thunder',
    name: '闪电',
    emoji: '⚡',
    description: '蕴含闪电之力，麻痹敌人。',
    applicableTypes: ['weapon'],
    effects: {'atk': 3, 'elementLightning': 5},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.7,
  ),
  EquipmentAffix(
    id: 'affix_holy',
    name: '神圣',
    emoji: '✨',
    description: '被圣光祝福，对黑暗生物特攻。',
    applicableTypes: ['weapon', 'armor'],
    effects: {'atk': 3, 'holyDamage': 0.5, 'def': 1},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.5,
  ),
  EquipmentAffix(
    id: 'affix_shadow',
    name: '暗影',
    emoji: '🌑',
    description: '被黑暗力量缠绕，攻击时吸取生命。',
    applicableTypes: ['weapon', 'accessory'],
    effects: {'atk': 2, 'lifeSteal': 0.12, 'dex': 1},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.5,
  ),
  EquipmentAffix(
    id: 'affix_life',
    name: '生命',
    emoji: '💚',
    description: '蕴含生命之力，缓慢治愈佩戴者。',
    applicableTypes: ['accessory'],
    effects: {'hpRegen': 2, 'def': 1},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.6,
  ),
  EquipmentAffix(
    id: 'affix_critical',
    name: '致命',
    emoji: '💀',
    description: '极大提升暴击威力。',
    applicableTypes: ['weapon'],
    effects: {'atk': 2, 'critRate': 0.10},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.5,
  ),
  EquipmentAffix(
    id: 'affix_elven',
    name: '精灵',
    emoji: '🧝',
    description: '精灵工艺，轻巧且精准。',
    applicableTypes: ['weapon', 'armor', 'accessory'],
    effects: {'dex': 3, 'rangedBonus': 0.10},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.4,
  ),
  EquipmentAffix(
    id: 'affix_dwarven',
    name: '矮人',
    emoji: '⛏️',
    description: '矮人锻造，坚固无比。',
    applicableTypes: ['weapon', 'armor'],
    effects: {'def': 3, 'durabilityBonus': 0.4, 'atk': 1},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.4,
  ),
  EquipmentAffix(
    id: 'affix_ward',
    name: '结界',
    emoji: '🔮',
    description: '形成魔法结界，抵御法术攻击。',
    applicableTypes: ['armor', 'accessory'],
    effects: {'def': 2, 'magicResist': 0.20},
    rarity: 3,
    tier: 3,
    spawnWeight: 0.4,
  ),

  // ─── 传说词缀 (稀有度 4) ────────────────────────────────
  EquipmentAffix(
    id: 'affix_dragon_soul',
    name: '龙魂',
    emoji: '🐉',
    description: '封印着龙的力量，赋予无与伦比的力量。',
    applicableTypes: ['weapon', 'armor'],
    effects: {'atk': 5, 'def': 5, 'magicResist': 0.25},
    rarity: 4,
    tier: 3,
    spawnWeight: 0.1,
  ),
  EquipmentAffix(
    id: 'affix_ancient',
    name: '远古',
    emoji: '🏛️',
    description: '来自失落时代的遗物，蕴含远古魔力。',
    applicableTypes: ['weapon', 'armor', 'accessory'],
    effects: {'atk': 4, 'def': 4, 'int': 3, 'str': 2},
    rarity: 4,
    tier: 3,
    spawnWeight: 0.08,
  ),
  EquipmentAffix(
    id: 'affix_lucky',
    name: '幸运',
    emoji: '🍀',
    description: '被幸运女神眷顾，一切皆有可能。',
    applicableTypes: ['accessory'],
    effects: {'dropRate': 0.10, 'goldRate': 0.15, 'critRate': 0.05},
    rarity: 4,
    tier: 3,
    spawnWeight: 0.08,
  ),
  EquipmentAffix(
    id: 'affix_eternal',
    name: '永恒',
    emoji: '♾️',
    description: '永不磨损的传说级装备。',
    applicableTypes: ['weapon', 'armor', 'accessory'],
    effects: {'atk': 4, 'def': 4, 'durabilityBonus': 1.0},
    rarity: 4,
    tier: 3,
    spawnWeight: 0.05,
  ),
  EquipmentAffix(
    id: 'affix_doom',
    name: '末日',
    emoji: '☠️',
    description: '蕴藏着毁灭之力，攻击时概率触发灭杀效果。',
    applicableTypes: ['weapon'],
    effects: {'atk': 8, 'critRate': 0.05},
    rarity: 4,
    tier: 3,
    spawnWeight: 0.03,
  ),
  EquipmentAffix(
    id: 'affix_archmage',
    name: '大法师',
    emoji: '🧙✨',
    description: '由大法师亲手附魔，魔法威力倍增。',
    applicableTypes: ['weapon', 'accessory'],
    effects: {'int': 5, 'spellPower': 15, 'magicResist': 0.15},
    rarity: 4,
    tier: 3,
    spawnWeight: 0.05,
  ),
];

/// ─── 工具函数 ────────────────────────────────────────────────

/// 根据ID获取词缀
EquipmentAffix? getAffix(String id) {
  try {
    return affixes.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}

/// 根据稀有度获取词缀列表
List<EquipmentAffix> getAffixesByRarity(int rarity) {
  return affixes.where((a) => a.rarity == rarity).toList();
}

/// 根据适用类型获取词缀列表
List<EquipmentAffix> getAffixesByType(String equipmentType) {
  return affixes.where((a) => a.applicableTypes.contains(equipmentType)).toList();
}

/// 随机生成一个词缀（根据稀有度权重）
EquipmentAffix? getRandomAffix({
  String? equipmentType,
  int? maxRarity,
}) {
  var pool = affixes;
  if (equipmentType != null) {
    pool = pool.where((a) => a.applicableTypes.contains(equipmentType)).toList();
  }
  if (maxRarity != null) {
    pool = pool.where((a) => a.rarity <= maxRarity).toList();
  }
  if (pool.isEmpty) return null;

  // 按权重随机选择
  final totalWeight = pool.fold(0.0, (sum, a) => sum + a.spawnWeight);
  var random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;
  var cumulative = 0.0;
  for (final affix in pool) {
    cumulative += affix.spawnWeight / totalWeight;
    if (random < cumulative) return affix;
  }
  return pool.last;
}

/// 为装备生成名称（带词缀）
String generateItemNameWithAffix({
  required String baseName,
  required EquipmentAffix affix,
}) {
  return '$affix$baseName';
}

/// 生成词缀显示文本（用于装备详情）
String formatAffixEffects(EquipmentAffix affix) {
  final buffer = StringBuffer();
  buffer.writeln('✨ ${affix.emoji} ${affix.name}');
  buffer.writeln('   ${affix.description}');
  buffer.writeln('   【${affix.effectDisplay}】');
  if (affix.rarity == 4) {
    buffer.writeln('   ⭐ 传说品质');
  } else if (affix.rarity == 3) {
    buffer.writeln('   ⭐ 史诗品质');
  } else if (affix.rarity == 2) {
    buffer.writeln('   ⭐ 稀有品质');
  }
  return buffer.toString();
}