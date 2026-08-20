/// 词条系统数据
library;

class LoreEntry {
  final String id;
  final String title;
  final String category; // 'realm' | 'monster' | 'item' | 'character'
  final String content;
  final String unlockCondition; // 解锁条件描述
  final String? relatedRealm; // 相关领域ID
  final String? relatedMonster; // 相关怪物ID
  final bool isHidden; // 是否隐藏（需要特殊条件触发）

  const LoreEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.unlockCondition,
    this.relatedRealm,
    this.relatedMonster,
    this.isHidden = false,
  });
}

/// 20+ 词条数据
final List<LoreEntry> loreEntries = [
  // ═══════════════════════════════════════════════
  // 📖 领域知识 (Realm Lore)
  // ═══════════════════════════════════════════════
  LoreEntry(
    id: 'lore_forest_origin',
    title: '暮色森林的起源',
    category: 'realm',
    content:
    '据说暮色森林曾是精灵王 Elandor 的狩猎场。他在一场与黑暗势力的战斗中被困于此，森林从此笼罩在永恒黄昏之中。据说在森林的最深处，还保留着他最后的营地遗迹。',
    unlockCondition: '进入暮色森林领域',
    relatedRealm: 'forest',
  ),
  LoreEntry(
    id: 'lore_crypt_king',
    title: '墓穴之王',
    category: 'realm',
    content:
    '废弃墓穴曾是古代王国 Valdoria 的皇家陵墓。传说最后一位国王 Kasimir 被自己的兄弟背叛，死后怨念不散，化作了巫妖。他的宝藏至今仍未被发现。',
    unlockCondition: '进入废弃墓穴领域',
    relatedRealm: 'crypt',
  ),
  LoreEntry(
    id: 'lore_shrine_curse',
    title: '腐化神殿的诅咒',
    category: 'realm',
    content:
    '这座神殿曾供奉着光明女神 Solara。但在千年战争期间，黑暗势力入侵并污染了神殿的核心。据说任何进入神殿的人都会被逐渐侵蚀，最终成为黑暗的仆从。',
    unlockCondition: '进入腐化神殿领域',
    relatedRealm: 'shrine',
  ),
  LoreEntry(
    id: 'lore_void_origin',
    title: '虚空裂隙的形成',
    category: 'realm',
    content:
    '虚空裂隙是现实世界与虚空之间的一道裂缝。它是由古代法师的禁忌实验造成的，那次实验撕开了时空的屏障。裂隙正在缓慢扩张，终有一天会吞噬整个世界。',
    unlockCondition: '进入虚空裂隙领域',
    relatedRealm: 'void',
    isHidden: true,
  ),
  LoreEntry(
    id: 'lore_elven_garden',
    title: '精灵花园的遗落',
    category: 'realm',
    content:
    '精灵花园是高等精灵最后的避难所。在大撤退之后，精灵们放弃了这片土地，只留下了一座被遗忘的花园。这里生长的植物都具有魔力，是炼金术士的宝库。',
    unlockCondition: '进入精灵花园领域',
    relatedRealm: 'elven_garden',
  ),

  // ═══════════════════════════════════════════════
  // 🐉 怪物图鉴 (Monster Lore)
  // ═══════════════════════════════════════════════
  LoreEntry(
    id: 'lore_slime_biology',
    title: '史莱姆的生态',
    category: 'monster',
    content:
    '史莱姆是一种低等生物，通过吞噬有机物存活。它们对火焰极其敏感，但冰系攻击几乎无效。成熟的史莱姆会分裂繁殖，因此在巢穴中经常能看到成群的史莱姆。',
    unlockCondition: '击杀史莱姆 5 次',
    relatedMonster: 'slime',
  ),
  LoreEntry(
    id: 'lore_wolf_pack',
    title: '暗影狼的习性',
    category: 'monster',
    content:
    '暗影狼是群居动物，通常由一只头狼带领。它们具有出色的夜视能力，在月光下最为活跃。暗影狼的牙齿含有微量毒素，被咬伤后会持续出血。',
    unlockCondition: '击杀暗影狼 5 次',
    relatedMonster: 'wolf',
  ),
  LoreEntry(
    id: 'lore_ghost_origin',
    title: '幽魂的执念',
    category: 'monster',
    content:
    '幽魂是未能安息的灵魂，通常因强烈的执念而留存在人世间。它们对物理攻击免疫，但神圣能量和银质武器能对它们造成有效伤害。',
    unlockCondition: '击杀幽魂 3 次',
    relatedMonster: 'ghost',
    isHidden: true,
  ),
  LoreEntry(
    id: 'lore_dragon_scale',
    title: '龙鳞的秘密',
    category: 'monster',
    content:
    '龙鳞的坚硬程度取决于龙的年龄。幼龙的鳞片比较柔软，但仍能抵挡普通刀剑。成年龙的鳞片则几乎坚不可摧，只有用龙鳞制作的武器才能穿透。',
    unlockCondition: '击杀暗影幼龙',
    relatedMonster: 'shadow_dragon',
  ),
  LoreEntry(
    id: 'lore_basilisk_gaze',
    title: '石化蜥蜴的凝视',
    category: 'monster',
    content:
    '石化蜥蜴的双眼具有超自然的力量，与它对视的人会被逐渐石化。唯一的躲避方法是使用镜面反射它的视线，或者闭着眼睛战斗。',
    unlockCondition: '击杀石化蜥蜴',
    relatedMonster: 'basilisk',
  ),

  // ═══════════════════════════════════════════════
  // 💎 物品传说 (Item Lore)
  // ═══════════════════════════════════════════════
  LoreEntry(
    id: 'lore_frost_sword',
    title: '霜寒之刃的传说',
    category: 'item',
    content:
    '霜寒之刃是由冰霜巨人 King Jotun 用千年寒冰锻造而成。据说这把剑在锻造时吸收了巨人的灵魂，因此拥有自我意识。它渴望寒冷，在温暖的环境中会缓慢失去力量。',
    unlockCondition: '获得霜寒之刃',
  ),
  LoreEntry(
    id: 'lore_dragon_heart',
    title: '龙心的力量',
    category: 'item',
    content:
    '龙心是巨龙体内最珍贵的器官。它蕴含着巨龙的全部生命能量，据说服用龙心的人能获得龙之力。但这是一种极其危险的仪式，大多数人都会被龙心反噬。',
    unlockCondition: '获得龙心',
    isHidden: true,
  ),
  LoreEntry(
    id: 'lore_philosopher_stone',
    title: '贤者之石的真相',
    category: 'item',
    content:
    '贤者之石是炼金术的最高成就。它并非天然形成，而是由炼金术师用多种珍贵材料合成的。贤者之石能点石成金，也能延长寿命，但这只是传说——从未有人真正成功过。',
    unlockCondition: '获得贤者之石',
    isHidden: true,
  ),

  // ═══════════════════════════════════════════════
  // 👤 角色背景 (Character Lore)
  // ═══════════════════════════════════════════════
  LoreEntry(
    id: 'lore_warrior_legacy',
    title: '战士的荣耀',
    category: 'character',
    content:
    '战士后裔继承了古代英雄的血统。他们的先祖曾参与千年前的"暗影战争"，封印了深渊恶魔。每一位战士后裔都背负着守护世界的使命。',
    unlockCondition: '选择"战士后裔"继承系',
  ),
  LoreEntry(
    id: 'lore_mystic_bloodline',
    title: '神秘血脉的起源',
    category: 'character',
    content:
    '神秘血脉来自一个古老的法师世家。该家族的先祖曾与星界生物签订契约，因此后代天生具备魔法感应能力。但这份力量也带来了诅咒——这个家族的寿命都异常短暂。',
    unlockCondition: '选择"神秘血脉"继承系',
    isHidden: true,
  ),
  LoreEntry(
    id: 'lore_merchant_guild',
    title: '商人世家的秘密',
    category: 'character',
    content:
    '商人世家掌控着大陆上最庞大的贸易网络。但他们真正的力量在于情报——每一笔交易背后都隐藏着不为人知的信息。据说商人世家的信鸽能飞到世界任何角落。',
    unlockCondition: '选择"商人世家"继承系',
  ),
  LoreEntry(
    id: 'lore_wanderer_tale',
    title: '流浪者的足迹',
    category: 'character',
    content:
    '流浪者没有固定的家园，他们在世界各地游荡，收集见闻和知识。每一个流浪者都是一部行走的历史书，记录着这片大陆的兴衰。',
    unlockCondition: '选择"流浪者"继承系',
  ),

  // ═══════════════════════════════════════════════
  // 🌌 隐藏词条 (Hidden Lore)
  // ═══════════════════════════════════════════════
  LoreEntry(
    id: 'lore_portalborn_prophecy',
    title: '传送门编年史的预言',
    category: 'realm',
    content:
    '古老的预言记载："当七道传送门同时开启时，世界将迎来终结或新生。穿越所有传送门者，将掌握命运的钥匙。"这个预言的出处已无人知晓，但它始终在流传。',
    unlockCondition: '完成 7 个不同的领域',
    isHidden: true,
  ),
  LoreEntry(
    id: 'lore_the_first_gate',
    title: '第一道传送门',
    category: 'realm',
    content:
    '第一道传送门是由精灵法师 Alduin 在三千年前创造的。他试图开启通往星界的通道，却意外撕裂了时空，创造了第一个口袋领域。那之后，传送门如雨后春笋般出现在世界各处。',
    unlockCondition: '进入 5 个不同主题的领域',
    isHidden: true,
  ),
  LoreEntry(
    id: 'lore_void_whisper',
    title: '虚空的低语',
    category: 'monster',
    content:
    '虚空生物并非恶意的生物——它们只是来自不同的维度，无法理解我们的世界。那些"低语"实际上是它们试图交流的信号，但人类的大脑无法理解这种信息，于是将其解读为疯狂。',
    unlockCondition: '击杀虚空幼体 3 次',
    relatedMonster: 'void_spawn',
    isHidden: true,
  ),
];

/// 根据词条ID获取词条
LoreEntry? getLoreEntry(String id) {
  try {
    return loreEntries.firstWhere((l) => l.id == id);
  } catch (_) {
    return null;
  }
}

/// 获取已解锁的词条（按分类分组）
Map<String, List<LoreEntry>> getLoreByCategory(List<String> unlockedIds) {
  final unlocked = loreEntries.where((l) => unlockedIds.contains(l.id)).toList();
  final Map<String, List<LoreEntry>> grouped = {};
  for (final entry in unlocked) {
    grouped.putIfAbsent(entry.category, () => []).add(entry);
  }
  return grouped;
}