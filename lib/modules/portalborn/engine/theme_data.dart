import 'dart:math';

/// 领域主题数据
class ThemeData {
  final String id;
  final String name;
  final String description;
  final int minRooms;
  final int maxRooms;
  final int baseDifficulty;
  final List<String> monsterPool;
  final List<String> objectPool;
  final String ambientSound;
  final String colorHex;

  const ThemeData({
    required this.id,
    required this.name,
    required this.description,
    required this.minRooms,
    required this.maxRooms,
    required this.baseDifficulty,
    required this.monsterPool,
    required this.objectPool,
    required this.ambientSound,
    required this.colorHex,
  });

  /// 随机获取一个怪物
  String getRandomMonster(Random random) {
    return monsterPool[random.nextInt(monsterPool.length)];
  }

  /// 随机获取一个物件
  String getRandomObject(Random random) {
    return objectPool[random.nextInt(objectPool.length)];
  }
}

/// 所有 12 种主题数据
final Map<String, ThemeData> themeDataMap = {
  // 🌲 暮色森林
  'forest': ThemeData(
    id: 'forest',
    name: '暮色森林',
    description: '一片被永恒暮色笼罩的扭曲林地。树木枝干交错，仿佛在低声交谈。',
    minRooms: 3,
    maxRooms: 5,
    baseDifficulty: 1,
    monsterPool: ['slime', 'wolf', 'bear', 'treant', 'forest_goblin'],
    objectPool: ['chest', 'fountain', 'ancient_tree', 'shrine', 'mossy_stone'],
    ambientSound: 'forest_ambient',
    colorHex: '#2d4a2d',
  ),

  // 💀 废弃墓穴
  'crypt': ThemeData(
    id: 'crypt',
    name: '废弃墓穴',
    description: '古老的亡灵栖息地，空气中弥漫着尘土和腐朽的气息。',
    minRooms: 4,
    maxRooms: 6,
    baseDifficulty: 2,
    monsterPool: ['skeleton', 'zombie', 'ghost', 'skeleton_archer', 'necromancer'],
    objectPool: ['sarcophagus', 'altar', 'candle_holder', 'tombstone', 'bone_pile'],
    ambientSound: 'crypt_ambient',
    colorHex: '#2a2a3a',
  ),

  // 🏚️ 怪物巢穴
  'nest': ThemeData(
    id: 'nest',
    name: '怪物巢穴',
    description: '某种生物的地下巢穴，潮湿阴暗，空气中弥漫着腐肉的气味。',
    minRooms: 2,
    maxRooms: 4,
    baseDifficulty: 3,
    monsterPool: ['harpy', 'giant_spider', 'basilisk', 'goblin'],
    objectPool: ['egg_cluster', 'webbed_chest', 'bone_pile', 'sticky_goo'],
    ambientSound: 'nest_ambient',
    colorHex: '#3a2a1a',
  ),

  // ⛩️ 腐化神殿
  'shrine': ThemeData(
    id: 'shrine',
    name: '腐化神殿',
    description: '被黑暗力量侵蚀的古老神殿，墙壁上布满了诡异的符文。',
    minRooms: 4,
    maxRooms: 6,
    baseDifficulty: 3,
    monsterPool: ['cultist', 'shadow_priest', 'corrupted_guardian', 'ghost'],
    objectPool: ['dark_altar', 'cursed_statue', 'ritual_circle', 'offering_table'],
    ambientSound: 'shrine_ambient',
    colorHex: '#2a1a3a',
  ),

  // 🌌 星界虚空
  'void': ThemeData(
    id: 'void',
    name: '星界虚空',
    description: '违背物理法则的奇异空间，星辰在你脚下流动。',
    minRooms: 3,
    maxRooms: 5,
    baseDifficulty: 4,
    monsterPool: ['void_spawn', 'abyss_watcher', 'shadow_priest'],
    objectPool: ['floating_crystal', 'star_pool', 'portal_shard', 'gravity_well'],
    ambientSound: 'void_ambient',
    colorHex: '#1a0a2a',
  ),

  // ⚙️ 地精工坊
  'goblin_workshop': ThemeData(
    id: 'goblin_workshop',
    name: '地精工坊',
    description: '地精建造的机械迷宫，到处是齿轮、管道和故障的机器。',
    minRooms: 4,
    maxRooms: 6,
    baseDifficulty: 2,
    monsterPool: ['goblin', 'forest_goblin', 'giant_spider'],
    objectPool: ['gear_machine', 'workbench', 'pipe_valve', 'tool_rack', 'power_core'],
    ambientSound: 'workshop_ambient',
    colorHex: '#3a3a2a',
  ),

  // ❄️ 冰封洞穴
  'frozen_cave': ThemeData(
    id: 'frozen_cave',
    name: '冰封洞穴',
    description: '极寒之地的冰川洞窟，冰晶反射着微弱的蓝光。',
    minRooms: 3,
    maxRooms: 5,
    baseDifficulty: 3,
    monsterPool: ['ice_elemental', 'frost_wyrm', 'wolf'],
    objectPool: ['ice_altar', 'frozen_chest', 'icicle', 'glacial_pool'],
    ambientSound: 'cave_ambient',
    colorHex: '#2a3a4a',
  ),

  // 🌋 火山腹地
  'volcano': ThemeData(
    id: 'volcano',
    name: '火山腹地',
    description: '活跃火山内部的炽热洞穴，岩浆在脚下缓缓流动。',
    minRooms: 3,
    maxRooms: 4,
    baseDifficulty: 4,
    monsterPool: ['fire_elemental', 'lava_golem', 'basilisk'],
    objectPool: ['lava_pool', 'volcanic_altar', 'obsidian_shard', 'heat_vent'],
    ambientSound: 'volcano_ambient',
    colorHex: '#4a2a1a',
  ),

  // 🌺 精灵花园
  'elven_garden': ThemeData(
    id: 'elven_garden',
    name: '精灵花园',
    description: '被遗忘的精灵族圣地，花草在月光下散发着柔和的光芒。',
    minRooms: 4,
    maxRooms: 5,
    baseDifficulty: 1,
    monsterPool: ['treant', 'slime', 'wolf'],
    objectPool: ['healing_fountain', 'elven_statue', 'magic_flower', 'moon_pool', 'ancient_tree'],
    ambientSound: 'garden_ambient',
    colorHex: '#2a4a3a',
  ),

  // 🌑 虚空裂隙
  'void_rift': ThemeData(
    id: 'void_rift',
    name: '虚空裂隙',
    description: '现实与虚空交界的危险地带，空间在这里扭曲变形。',
    minRooms: 5,
    maxRooms: 7,
    baseDifficulty: 5,
    monsterPool: ['void_spawn', 'abyss_watcher', 'shadow_dragon'],
    objectPool: ['rift_crystal', 'void_altar', 'floating_ruin', 'singularity'],
    ambientSound: 'void_ambient',
    colorHex: '#1a0a1a',
  ),

  // ⛵ 海盗沉船
  'shipwreck': ThemeData(
    id: 'shipwreck',
    name: '海盗沉船',
    description: '搁浅的古船内部，木板腐朽，海水从裂缝中渗入。',
    minRooms: 3,
    maxRooms: 4,
    baseDifficulty: 2,
    monsterPool: ['drowned_sailor', 'crab_giant', 'ghost_captain'],
    objectPool: ['treasure_chest', 'captain_wheel', 'cannon', 'hammock', 'ship_log'],
    ambientSound: 'shipwreck_ambient',
    colorHex: '#3a2a1a',
  ),

  // 🧪 混沌实验室
  'chaos_lab': ThemeData(
    id: 'chaos_lab',
    name: '混沌实验室',
    description: '疯狂法师的实验场所，桌上堆满了烧瓶和不明液体。',
    minRooms: 4,
    maxRooms: 5,
    baseDifficulty: 4,
    monsterPool: ['mutant_rat', 'experiment_001', 'cultist', 'shadow_priest'],
    objectPool: ['experiment_table', 'chemical_vat', 'scroll_rack', 'crystal_cage', 'alchemy_station'],
    ambientSound: 'lab_ambient',
    colorHex: '#2a2a3a',
  ),
};

/// 根据主题ID获取主题数据
ThemeData? getThemeData(String themeId) {
  return themeDataMap[themeId];
}

/// 获取所有主题ID列表
List<String> getAllThemeIds() {
  return themeDataMap.keys.toList();
}

/// 获取所有主题名称列表
List<String> getAllThemeNames() {
  return themeDataMap.values.map((t) => t.name).toList();
}