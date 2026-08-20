/// 职业数据

/// 职业定义
class ClassData {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Map<String, int> baseStats; // {'strength': 8, 'dexterity': 4, ...}
  final Map<String, int> bonus; // {'hp': 10, 'atk': 2}
  final List<Skill> skills; // 初始技能

  const ClassData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.baseStats,
    required this.bonus,
    this.skills = const [],
  });
}

/// 技能定义
class Skill {
  final String id;
  final String name;
  final int levelRequired;
  final String type; // 'active' | 'passive'
  final String description;
  final double? damageMultiplier; // 主动技能伤害倍率
  final int? spellPower; // 法术伤害
  final int? atkBonus; // 被动攻击加成
  final int? defBonus; // 被动防御加成
  final bool? aoe; // 是否范围攻击
  final int? chain; // 连锁数量（闪电链）
  final int? healAmount; // 治疗量

  const Skill({
    required this.id,
    required this.name,
    required this.levelRequired,
    required this.type,
    required this.description,
    this.damageMultiplier,
    this.spellPower,
    this.atkBonus,
    this.defBonus,
    this.aoe,
    this.chain,
    this.healAmount,
  });
}

/// 5种职业数据
final List<ClassData> classData = [
  // ─── 战士 ───
  ClassData(
    id: 'warrior',
    name: '战士',
    emoji: '⚔️',
    description: '近战专家，拥有强大的物理攻击力和生存能力。',
    baseStats: {'strength': 8, 'dexterity': 4, 'intelligence': 3, 'constitution': 7},
    bonus: {'hp': 10, 'atk': 2},
    skills: [
      Skill(
        id: 'warrior_1',
        name: '猛击',
        levelRequired: 1,
        type: 'active',
        description: '造成 150% 伤害',
        damageMultiplier: 1.5,
      ),
      Skill(
        id: 'warrior_2',
        name: '战吼',
        levelRequired: 3,
        type: 'passive',
        description: '攻击力 +2',
        atkBonus: 2,
      ),
      Skill(
        id: 'warrior_3',
        name: '旋风斩',
        levelRequired: 5,
        type: 'active',
        description: '攻击所有敌人',
        damageMultiplier: 1.2,
        aoe: true,
      ),
      Skill(
        id: 'warrior_4',
        name: '铁壁防御',
        levelRequired: 7,
        type: 'passive',
        description: '防御力 +3',
        defBonus: 3,
      ),
      Skill(
        id: 'warrior_5',
        name: '致命打击',
        levelRequired: 10,
        type: 'active',
        description: '造成 200% 伤害，50% 暴击率',
        damageMultiplier: 2.0,
      ),
    ],
  ),

  // ─── 法师 ───
  ClassData(
    id: 'mage',
    name: '法师',
    emoji: '🧙',
    description: '远程法术专家，能释放强大的元素魔法。',
    baseStats: {'strength': 3, 'dexterity': 4, 'intelligence': 9, 'constitution': 4},
    bonus: {'hp': 0, 'atk': 0},
    skills: [
      Skill(
        id: 'mage_1',
        name: '火球术',
        levelRequired: 1,
        type: 'active',
        description: '造成 15 点火焰伤害',
        spellPower: 15,
      ),
      Skill(
        id: 'mage_2',
        name: '魔力护盾',
        levelRequired: 3,
        type: 'passive',
        description: '防御力 +3',
        defBonus: 3,
      ),
      Skill(
        id: 'mage_3',
        name: '闪电链',
        levelRequired: 5,
        type: 'active',
        description: '造成 20 点闪电伤害，溅射 1 个敌人',
        spellPower: 20,
        chain: 1,
      ),
      Skill(
        id: 'mage_4',
        name: '奥术智慧',
        levelRequired: 7,
        type: 'passive',
        description: '智力 +2',
      ),
      Skill(
        id: 'mage_5',
        name: '陨石术',
        levelRequired: 10,
        type: 'active',
        description: '造成 35 点火焰伤害，范围爆炸',
        spellPower: 35,
        aoe: true,
      ),
    ],
  ),

  // ─── 盗贼 ───
  ClassData(
    id: 'rogue',
    name: '盗贼',
    emoji: '🗡️🌙',
    description: '敏捷的刺客，擅长快速击杀和潜行。',
    baseStats: {'strength': 4, 'dexterity': 9, 'intelligence': 4, 'constitution': 5},
    bonus: {'hp': 0, 'atk': 0},
    skills: [
      Skill(
        id: 'rogue_1',
        name: '暗杀',
        levelRequired: 1,
        type: 'active',
        description: '背刺伤害 ×2（需从背后攻击）',
        damageMultiplier: 2.0,
      ),
      Skill(
        id: 'rogue_2',
        name: '疾风步',
        levelRequired: 3,
        type: 'passive',
        description: '闪避率 +10%',
      ),
      Skill(
        id: 'rogue_3',
        name: '毒刃',
        levelRequired: 5,
        type: 'active',
        description: '造成 120% 伤害，附加 3 回合毒伤',
        damageMultiplier: 1.2,
      ),
      Skill(
        id: 'rogue_4',
        name: '暗影大师',
        levelRequired: 7,
        type: 'passive',
        description: '暴击率 +10%',
      ),
      Skill(
        id: 'rogue_5',
        name: '死亡标记',
        levelRequired: 10,
        type: 'active',
        description: '造成 250% 伤害，必中',
        damageMultiplier: 2.5,
      ),
    ],
  ),

  // ─── 牧师 ───
  ClassData(
    id: 'priest',
    name: '牧师',
    emoji: '✨🙏',
    description: '神圣的治疗者，能治愈伤痛并净化邪恶。',
    baseStats: {'strength': 4, 'dexterity': 3, 'intelligence': 7, 'constitution': 6},
    bonus: {'hp': 5, 'atk': 0},
    skills: [
      Skill(
        id: 'priest_1',
        name: '治愈术',
        levelRequired: 1,
        type: 'active',
        description: '恢复 15 HP',
        healAmount: 15,
      ),
      Skill(
        id: 'priest_2',
        name: '神圣庇护',
        levelRequired: 3,
        type: 'passive',
        description: '受到伤害 -2',
        defBonus: 2,
      ),
      Skill(
        id: 'priest_3',
        name: '圣光弹',
        levelRequired: 5,
        type: 'active',
        description: '造成 12 点神圣伤害，对亡灵伤害 ×1.5',
        spellPower: 12,
      ),
      Skill(
        id: 'priest_4',
        name: '生命祝福',
        levelRequired: 7,
        type: 'passive',
        description: 'HP 上限 +10',
      ),
      Skill(
        id: 'priest_5',
        name: '群体治愈',
        levelRequired: 10,
        type: 'active',
        description: '恢复全体 25 HP',
        healAmount: 25,
        aoe: true,
      ),
    ],
  ),

  // ─── 游侠 ───
  ClassData(
    id: 'ranger',
    name: '游侠',
    emoji: '🏹🌿',
    description: '荒野的守护者，擅长远程攻击和追踪。',
    baseStats: {'strength': 5, 'dexterity': 8, 'intelligence': 4, 'constitution': 5},
    bonus: {'hp': 0, 'atk': 0},
    skills: [
      Skill(
        id: 'ranger_1',
        name: '精准射击',
        levelRequired: 1,
        type: 'active',
        description: '造成 140% 伤害，必中',
        damageMultiplier: 1.4,
      ),
      Skill(
        id: 'ranger_2',
        name: '鹰眼',
        levelRequired: 3,
        type: 'passive',
        description: '暴击率 +5%，感知 +1',
      ),
      Skill(
        id: 'ranger_3',
        name: '多重箭',
        levelRequired: 5,
        type: 'active',
        description: '攻击 2 个目标',
        damageMultiplier: 1.0,
        chain: 2,
      ),
      Skill(
        id: 'ranger_4',
        name: '自然亲和',
        levelRequired: 7,
        type: 'passive',
        description: '在森林/花园中回复速度 +50%',
      ),
      Skill(
        id: 'ranger_5',
        name: '致命狙击',
        levelRequired: 10,
        type: 'active',
        description: '造成 300% 伤害，无视护甲',
        damageMultiplier: 3.0,
      ),
    ],
  ),
];

/// 根据职业ID获取职业数据
ClassData? getClassData(String id) {
  try {
    return classData.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

/// 获取职业的所有技能（按等级排序）
List<Skill> getSkillsForClass(String classId) {
  final classData = getClassData(classId);
  if (classData == null) return [];
  return classData.skills..sort((a, b) => a.levelRequired.compareTo(b.levelRequired));
}