
/// 制作配方数据
class Recipe {
  final String id;
  final String name;
  final String itemId; // 制作出的物品ID
  final Map<String, int> materials; // 所需材料: {'iron_ingot': 2}
  final String skillRequired; // 所需技能
  final String description;
  final String emoji;

  Recipe({
    required this.id,
    required this.name,
    required this.itemId,
    required this.materials,
    required this.skillRequired,
    required this.description,
    required this.emoji,
  });
}

/// 所有制作配方
final List<Recipe> recipes = [
  // ─── 武器配方 ───
  Recipe(
    id: 'craft_iron_sword',
    name: '铁剑',
    itemId: 'iron_sword',
    materials: {'iron_ingot': 3},
    skillRequired: '锻造',
    description: '将铁锭锻造成一把可靠的长剑。',
    emoji: '🗡️',
  ),
  Recipe(
    id: 'craft_steel_sword',
    name: '钢剑',
    itemId: 'steel_sword',
    materials: {'iron_ingot': 5, 'coal': 2},
    skillRequired: '锻造',
    description: '用精钢打造一把锋利的钢剑。',
    emoji: '⚔️',
  ),
  Recipe(
    id: 'craft_iron_hammer',
    name: '铁锤',
    itemId: 'iron_hammer',
    materials: {'iron_ingot': 4, 'wood': 1},
    skillRequired: '锻造',
    description: '锻造一把沉重的铁锤。',
    emoji: '🔨',
  ),

  // ─── 护甲配方 ───
  Recipe(
    id: 'craft_leather_armor',
    name: '皮甲',
    itemId: 'leather_armor',
    materials: {'leather': 3},
    skillRequired: '制皮',
    description: '用鞣制皮革制作一件轻便护甲。',
    emoji: '🦺',
  ),
  Recipe(
    id: 'craft_chain_mail',
    name: '锁子甲',
    itemId: 'chain_mail',
    materials: {'iron_ingot': 6},
    skillRequired: '锻造',
    description: '用铁环编织一件锁子甲。',
    emoji: '⛓️',
  ),

  // ─── 药水配方 ───
  Recipe(
    id: 'craft_health_potion_small',
    name: '治疗药水（小）',
    itemId: 'health_potion_small',
    materials: {'herb': 2, 'water': 1},
    skillRequired: '炼金术',
    description: '将草药与水混合，制成治疗药水。',
    emoji: '🧪',
  ),
  Recipe(
    id: 'craft_health_potion_medium',
    name: '治疗药水（中）',
    itemId: 'health_potion_medium',
    materials: {'herb': 4, 'life_essence': 1},
    skillRequired: '炼金术',
    description: '加入生命精华，制作更高效的治疗药水。',
    emoji: '🧪',
  ),

  // ─── 材料转化 ───
  Recipe(
    id: 'smelt_iron',
    name: '熔炼铁锭',
    itemId: 'iron_ingot',
    materials: {'iron_ore': 2},
    skillRequired: '熔炼',
    description: '将铁矿石熔炼成铁锭。',
    emoji: '🔥',
  ),
  Recipe(
    id: 'tan_leather',
    name: '鞣制皮革',
    itemId: 'leather',
    materials: {'bear_hide': 1},
    skillRequired: '制皮',
    description: '将生皮鞣制成可用的皮革。',
    emoji: '🧵',
  ),
];

/// 根据配方ID获取配方
Recipe? getRecipe(String id) {
  try {
    return recipes.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
}

/// 根据物品ID获取配方
Recipe? getRecipeByItemId(String itemId) {
  try {
    return recipes.firstWhere((r) => r.itemId == itemId);
  } catch (_) {
    return null;
  }
}