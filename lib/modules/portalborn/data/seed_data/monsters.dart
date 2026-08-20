import '../models/monster_model.dart';

/// 30+ 怪物模板数据
/// 按主题和难度分类
final List<MonsterTemplate> monsterTemplates = [
  // ═══════════════════════════════════════════════
  // 🌲 森林主题（低难度）
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'slime',
    name: '史莱姆',
    emoji: '🟢',
    description: '一团颤抖的绿色胶状物，表面泛着湿润的光泽。它的移动速度很慢，但具有腐蚀性。',
    baseHp: 8,
    attack: 3,
    defense: 1,
    expReward: 5,
    goldReward: 2,
    drops: [
      DropTable(itemId: 'slime_gel', probability: 0.3, minCount: 1, maxCount: 2),
    ],
    tags: ['beast'],
  ),
  MonsterTemplate(
    id: 'wolf',
    name: '暗影狼',
    emoji: '🐺',
    description: '一头毛发漆黑的巨狼，眼中闪烁着绿色的幽光。它的牙缝间还残留着上一个猎物的痕迹。',
    baseHp: 14,
    attack: 6,
    defense: 2,
    expReward: 10,
    goldReward: 4,
    drops: [
      DropTable(itemId: 'wolf_fang', probability: 0.25, minCount: 1, maxCount: 2),
    ],
    tags: ['beast'],
  ),
  MonsterTemplate(
    id: 'bear',
    name: '林地巨熊',
    emoji: '🐻',
    description: '一头体型庞大的棕色巨熊，肩高超过两米。它的咆哮声能让整片森林安静下来。',
    baseHp: 25,
    attack: 8,
    defense: 4,
    expReward: 18,
    goldReward: 8,
    drops: [
      DropTable(itemId: 'bear_hide', probability: 0.4, minCount: 1, maxCount: 2),
    ],
    tags: ['beast', 'elite'],
  ),
  MonsterTemplate(
    id: 'treant',
    name: '古树守卫',
    emoji: '🌳',
    description: '一棵古老的大树被魔法活化，树干上浮现出愤怒的面孔。它的树枝如手臂般挥舞，根须如脚般移动。',
    baseHp: 30,
    attack: 7,
    defense: 6,
    expReward: 20,
    goldReward: 10,
    drops: [
      DropTable(itemId: 'ancient_wood', probability: 0.5, minCount: 1, maxCount: 2),
    ],
    tags: ['beast', 'elite'],
  ),
  MonsterTemplate(
    id: 'forest_goblin',
    name: '林地地精',
    emoji: '👺',
    description: '一个矮小但肌肉结实的绿色地精，手持铁制短剑，露出狡诈的笑容。它喜欢在树丛中偷袭。',
    baseHp: 12,
    attack: 5,
    defense: 2,
    expReward: 8,
    goldReward: 5,
    drops: [
      DropTable(itemId: 'goblin_ear', probability: 0.3, minCount: 1, maxCount: 1),
    ],
    tags: ['humanoid'],
  ),

  // ═══════════════════════════════════════════════
  // 💀 墓穴主题（亡灵系）
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'skeleton',
    name: '骷髅兵',
    emoji: '💀',
    description: '一具手持锈剑的骷髅，眼眶中闪烁着幽蓝的磷火。它的关节发出咯吱咯吱的声响。',
    baseHp: 10,
    attack: 5,
    defense: 3,
    expReward: 7,
    goldReward: 3,
    drops: [
      DropTable(itemId: 'bone_shard', probability: 0.2, minCount: 1, maxCount: 2),
    ],
    tags: ['undead'],
  ),
  MonsterTemplate(
    id: 'zombie',
    name: '行尸',
    emoji: '🧟',
    description: '一具腐烂的僵尸，身上散发着泥土和死亡的气息。它拖着脚步向你走来，口中发出低沉的呻吟。',
    baseHp: 20,
    attack: 4,
    defense: 2,
    expReward: 12,
    goldReward: 5,
    drops: [
      DropTable(itemId: 'rotten_flesh', probability: 0.3, minCount: 1, maxCount: 1),
    ],
    tags: ['undead'],
  ),
  MonsterTemplate(
    id: 'ghost',
    name: '幽魂',
    emoji: '👻',
    description: '一个半透明的灵体，散发着寒冷的气息。它的面容模糊不清，但你能感受到它深深的怨恨。',
    baseHp: 12,
    attack: 7,
    defense: 0,
    expReward: 15,
    goldReward: 6,
    drops: [
      DropTable(itemId: 'ectoplasm', probability: 0.2, minCount: 1, maxCount: 2),
    ],
    tags: ['undead', 'magical'],
  ),
  MonsterTemplate(
    id: 'skeleton_archer',
    name: '骷髅弓箭手',
    emoji: '🏹',
    description: '一具手持长弓的骷髅，箭袋中插满了骨箭。它的目标极其精准。',
    baseHp: 12,
    attack: 8,
    defense: 1,
    expReward: 12,
    goldReward: 5,
    drops: [
      DropTable(itemId: 'bone_arrow', probability: 0.3, minCount: 2, maxCount: 5),
    ],
    tags: ['undead'],
  ),
  MonsterTemplate(
    id: 'necromancer',
    name: '死灵法师',
    emoji: '🧙',
    description: '一个披着黑袍的法师，手持骨制法杖，眼中燃烧着幽绿的火焰。它能召唤亡灵为你作战。',
    baseHp: 18,
    attack: 9,
    defense: 2,
    expReward: 22,
    goldReward: 12,
    drops: [
      DropTable(itemId: 'soul_shard', probability: 0.2, minCount: 1, maxCount: 1),
    ],
    tags: ['undead', 'magical', 'elite'],
    specialAbility: '召唤骷髅',
    abilityCooldown: 3,
    abilityDamage: 0,
  ),

  // ═══════════════════════════════════════════════
  // 🏚️ 巢穴主题（高级）
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'harpy',
    name: '鹰身女妖',
    emoji: '🦅',
    description: '一个长着鸟翼和利爪的怪物，有着女人的面孔和鸟类的身体。它的尖叫能震碎玻璃。',
    baseHp: 18,
    attack: 8,
    defense: 2,
    expReward: 14,
    goldReward: 7,
    drops: [
      DropTable(itemId: 'harpy_feather', probability: 0.25, minCount: 1, maxCount: 2),
    ],
    tags: ['beast'],
  ),
  MonsterTemplate(
    id: 'giant_spider',
    name: '巨型蜘蛛',
    emoji: '🕷️',
    description: '一只毛茸茸的巨大蜘蛛，八只眼睛闪烁着红光。它的毒牙能注入麻痹毒素。',
    baseHp: 22,
    attack: 7,
    defense: 3,
    expReward: 16,
    goldReward: 8,
    drops: [
      DropTable(itemId: 'spider_silk', probability: 0.35, minCount: 1, maxCount: 3),
    ],
    tags: ['beast'],
  ),
  MonsterTemplate(
    id: 'basilisk',
    name: '石化蜥蜴',
    emoji: '🦎',
    description: '一只体型庞大的爬行动物，鳞片呈暗绿色，双眼闪烁着危险的金色光芒。与它对视可能被石化。',
    baseHp: 28,
    attack: 10,
    defense: 5,
    expReward: 25,
    goldReward: 15,
    drops: [
      DropTable(itemId: 'basilisk_eye', probability: 0.15, minCount: 1, maxCount: 1),
    ],
    tags: ['beast', 'elite'],
    specialAbility: '石化凝视',
    abilityCooldown: 4,
    abilityDamage: 5,
  ),

  // ═══════════════════════════════════════════════
  // ⛩️ 神殿主题（高难度）
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'cultist',
    name: '疯狂信徒',
    emoji: '🧛',
    description: '一个身穿破旧长袍的狂热信徒，眼神空洞，口中念念有词。它手持仪式匕首，随时准备献祭。',
    baseHp: 16,
    attack: 7,
    defense: 2,
    expReward: 14,
    goldReward: 6,
    drops: [
      DropTable(itemId: 'cultist_robe', probability: 0.2, minCount: 1, maxCount: 1),
    ],
    tags: ['humanoid'],
  ),
  MonsterTemplate(
    id: 'shadow_priest',
    name: '暗影祭司',
    emoji: '🌑',
    description: '一位被黑暗力量腐蚀的祭司，周身环绕着暗影能量。它的低语能腐蚀意志。',
    baseHp: 20,
    attack: 10,
    defense: 3,
    expReward: 22,
    goldReward: 12,
    drops: [
      DropTable(itemId: 'shadow_crystal', probability: 0.2, minCount: 1, maxCount: 1),
    ],
    tags: ['humanoid', 'magical'],
    specialAbility: '暗影波',
    abilityCooldown: 3,
    abilityDamage: 10,
  ),
  MonsterTemplate(
    id: 'corrupted_guardian',
    name: '堕落守护者',
    emoji: '🗿',
    description: '一座被黑暗力量腐化的石像，原本神圣的外表被扭曲成了狰狞的面孔。它的移动缓慢但势不可挡。',
    baseHp: 35,
    attack: 12,
    defense: 8,
    expReward: 30,
    goldReward: 18,
    drops: [
      DropTable(itemId: 'corrupted_stone', probability: 0.3, minCount: 1, maxCount: 2),
    ],
    tags: ['elite', 'magical'],
  ),

  // ═══════════════════════════════════════════════
  // 🌀 虚空主题（极高难度）
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'void_spawn',
    name: '虚空幼体',
    emoji: '🌌',
    description: '一个从虚空中诞生的扭曲生物，体型不定，表面流动着星辰般的光芒。它的存在本身就在侵蚀现实。',
    baseHp: 30,
    attack: 14,
    defense: 4,
    expReward: 35,
    goldReward: 20,
    drops: [
      DropTable(itemId: 'void_essence', probability: 0.2, minCount: 1, maxCount: 1),
    ],
    tags: ['magical', 'elite'],
    specialAbility: '虚空吞噬',
    abilityCooldown: 4,
    abilityDamage: 15,
  ),
  MonsterTemplate(
    id: 'abyss_watcher',
    name: '深渊守望者',
    emoji: '👁️',
    description: '一只巨大的眼瞳悬浮在虚空中，周围环绕着触须。它的凝视能让人陷入疯狂。',
    baseHp: 40,
    attack: 16,
    defense: 6,
    expReward: 45,
    goldReward: 25,
    drops: [
      DropTable(itemId: 'abyss_eye', probability: 0.15, minCount: 1, maxCount: 1),
    ],
    tags: ['magical', 'elite'],
    specialAbility: '疯狂凝视',
    abilityCooldown: 3,
    abilityDamage: 12,
  ),

  // ═══════════════════════════════════════════════
  // 🔥 火山主题
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'fire_elemental',
    name: '火焰元素',
    emoji: '🔥',
    description: '一团由纯火焰构成的元素生物，散发着灼热的高温。它的形态不断变化，仿佛有生命一般。',
    baseHp: 20,
    attack: 12,
    defense: 2,
    expReward: 20,
    goldReward: 10,
    drops: [
      DropTable(itemId: 'fire_essence', probability: 0.3, minCount: 1, maxCount: 2),
    ],
    tags: ['magical'],
  ),
  MonsterTemplate(
    id: 'lava_golem',
    name: '熔岩傀儡',
    emoji: '🗿🔥',
    description: '一个由熔岩和岩石构成的巨型傀儡，体表流淌着赤红的岩浆。它的每一步都在地面上留下焦痕。',
    baseHp: 40,
    attack: 14,
    defense: 10,
    expReward: 35,
    goldReward: 20,
    drops: [
      DropTable(itemId: 'lava_core', probability: 0.25, minCount: 1, maxCount: 1),
    ],
    tags: ['elite'],
  ),

  // ═══════════════════════════════════════════════
  // 🧊 冰洞主题
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'ice_elemental',
    name: '冰霜元素',
    emoji: '❄️',
    description: '一个由冰晶和寒气构成的元素生物，散发着刺骨的寒冷。它的触碰能让水瞬间结冰。',
    baseHp: 18,
    attack: 9,
    defense: 4,
    expReward: 18,
    goldReward: 9,
    drops: [
      DropTable(itemId: 'ice_essence', probability: 0.3, minCount: 1, maxCount: 2),
    ],
    tags: ['magical'],
  ),
  MonsterTemplate(
    id: 'frost_wyrm',
    name: '霜霜蠕虫',
    emoji: '🐉❄️',
    description: '一条盘踞在冰川深处的古老龙族，通体覆盖着冰晶鳞甲。它呼出的寒气能冻住灵魂。',
    baseHp: 45,
    attack: 15,
    defense: 9,
    expReward: 40,
    goldReward: 25,
    drops: [
      DropTable(itemId: 'frost_scale', probability: 0.3, minCount: 1, maxCount: 2),
    ],
    tags: ['dragon', 'elite'],
    specialAbility: '冰霜吐息',
    abilityCooldown: 3,
    abilityDamage: 15,
  ),

  // ═══════════════════════════════════════════════
  // 🏴‍☠️ 海盗沉船主题
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'drowned_sailor',
    name: '溺亡水手',
    emoji: '💀🌊',
    description: '一个被海水浸泡多年的腐烂尸体，仍穿着破损的海军制服。它的眼中闪烁着幽蓝的光。',
    baseHp: 14,
    attack: 6,
    defense: 2,
    expReward: 10,
    goldReward: 5,
    drops: [
      DropTable(itemId: 'sailor_medal', probability: 0.15, minCount: 1, maxCount: 1),
    ],
    tags: ['undead'],
  ),
  MonsterTemplate(
    id: 'crab_giant',
    name: '巨型螃蟹',
    emoji: '🦀',
    description: '一只轿车般大小的螃蟹，蟹钳能轻易夹断铁链。它的背壳上长满了藤壶。',
    baseHp: 25,
    attack: 8,
    defense: 6,
    expReward: 18,
    goldReward: 10,
    drops: [
      DropTable(itemId: 'crab_shell', probability: 0.3, minCount: 1, maxCount: 1),
    ],
    tags: ['beast'],
  ),
  MonsterTemplate(
    id: 'ghost_captain',
    name: '鬼魂船长',
    emoji: '👨‍✈️👻',
    description: '一位穿着华丽海军制服的无头幽灵，手持生锈的指挥剑。它的怒吼能让海水沸腾。',
    baseHp: 35,
    attack: 13,
    defense: 5,
    expReward: 35,
    goldReward: 25,
    drops: [
      DropTable(itemId: 'captain_sword', probability: 0.1, minCount: 1, maxCount: 1),
    ],
    tags: ['undead', 'boss'],
    specialAbility: '幽灵咆哮',
    abilityCooldown: 3,
    abilityDamage: 12,
  ),

  // ═══════════════════════════════════════════════
  // 🧪 混沌实验室主题
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'mutant_rat',
    name: '变异巨鼠',
    emoji: '🐀💉',
    description: '一只被实验药剂催化变异的巨鼠，体型如狗，牙齿上滴落着腐蚀性唾液。',
    baseHp: 12,
    attack: 5,
    defense: 1,
    expReward: 8,
    goldReward: 3,
    drops: [
      DropTable(itemId: 'mutant_tooth', probability: 0.2, minCount: 1, maxCount: 2),
    ],
    tags: ['beast'],
  ),
  MonsterTemplate(
    id: 'experiment_001',
    name: '实验体 001',
    emoji: '🧬',
    description: '一个由多个生物缝合而成的怪物，不同部位来自不同的物种。它发出令人不安的哀嚎。',
    baseHp: 30,
    attack: 11,
    defense: 4,
    expReward: 28,
    goldReward: 16,
    drops: [
      DropTable(itemId: 'experimental_serum', probability: 0.2, minCount: 1, maxCount: 1),
    ],
    tags: ['beast', 'elite'],
  ),

  // ═══════════════════════════════════════════════
  // 🏆 BOSS 级怪物（独立）
  // ═══════════════════════════════════════════════
  MonsterTemplate(
    id: 'shadow_dragon',
    name: '暗影幼龙',
    emoji: '🐉',
    description: '一头被阴影腐蚀的幼龙，鳞片呈暗紫色，散发着不祥的气息。它的眼睛燃烧着紫色的火焰。',
    baseHp: 50,
    attack: 18,
    defense: 10,
    expReward: 60,
    goldReward: 40,
    drops: [
      DropTable(itemId: 'dragon_scale', probability: 0.5, minCount: 1, maxCount: 2),
      DropTable(itemId: 'dragon_heart', probability: 0.1, minCount: 1, maxCount: 1),
    ],
    tags: ['boss', 'dragon', 'elite'],
    specialAbility: '暗影吐息',
    abilityCooldown: 3,
    abilityDamage: 18,
  ),
  MonsterTemplate(
    id: 'lich_king',
    name: '巫妖王',
    emoji: '👑💀',
    description: '一位曾经统治广阔疆域的王者，死后不腐，以巫妖之身继续统治亡灵军团。它的权杖上镶嵌着灵魂宝石。',
    baseHp: 55,
    attack: 16,
    defense: 12,
    expReward: 70,
    goldReward: 50,
    drops: [
      DropTable(itemId: 'lich_crown', probability: 0.1, minCount: 1, maxCount: 1),
      DropTable(itemId: 'soul_gem', probability: 0.3, minCount: 1, maxCount: 1),
    ],
    tags: ['boss', 'undead', 'elite'],
    specialAbility: '亡灵军团召唤',
    abilityCooldown: 4,
    abilityDamage: 0,
  ),
  MonsterTemplate(
    id: 'ancient_ent',
    name: '远古树精',
    emoji: '🌳👁️',
    description: '一棵存活了数千年的远古巨树，树皮上浮现出老人般的面孔。它的根须覆盖了整座山丘。',
    baseHp: 60,
    attack: 14,
    defense: 14,
    expReward: 55,
    goldReward: 35,
    drops: [
      DropTable(itemId: 'heartwood', probability: 0.4, minCount: 1, maxCount: 1),
    ],
    tags: ['boss', 'beast'],
    specialAbility: '根须缠绕',
    abilityCooldown: 3,
    abilityDamage: 10,
  ),
];

/// 根据怪物ID获取模板
MonsterTemplate? getMonsterTemplate(String id) {
  try {
    return monsterTemplates.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}

/// 根据标签获取怪物列表
List<MonsterTemplate> getMonstersByTag(String tag) {
  return monsterTemplates.where((m) => m.tags.contains(tag)).toList();
}