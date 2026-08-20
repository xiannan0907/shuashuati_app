/// 每日运势系统数据
library;

class Fortune {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double probability; // 出现概率
  final Map<String, dynamic> effects; // 具体效果

  const Fortune({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.probability,
    required this.effects,
  });
}

/// 6种运势数据
final List<Fortune> fortunes = [
  Fortune(
    id: 'lucky',
    name: '幸运日',
    emoji: '🍀',
    description: '今天你被幸运女神眷顾！',
    probability: 0.15,
    effects: {
      'dropRate': 1.2, // 掉落率 +20%
      'critRate': 0.05, // 暴击率 +5%
    },
  ),
  Fortune(
    id: 'unlucky',
    name: '厄运日',
    emoji: '☠️',
    description: '今天运势不佳，万事小心。',
    probability: 0.10,
    effects: {
      'dropRate': 0.8, // 掉落率 -20%
      'enemyAtkBonus': 2, // 怪物攻击 +2
    },
  ),
  Fortune(
    id: 'wise',
    name: '智慧日',
    emoji: '📚',
    description: '今天你的思维格外清晰。',
    probability: 0.15,
    effects: {
      'expRate': 1.3, // 经验获取 +30%
    },
  ),
  Fortune(
    id: 'rich',
    name: '财富日',
    emoji: '💰',
    description: '财神爷今天特别眷顾你。',
    probability: 0.15,
    effects: {
      'goldRate': 1.5, // 金币获取 +50%
    },
  ),
  Fortune(
    id: 'brave',
    name: '勇气日',
    emoji: '💪',
    description: '今天你充满勇气和力量！',
    probability: 0.15,
    effects: {
      'atkBonus': 3, // 攻击力 +3
    },
  ),
  Fortune(
    id: 'normal',
    name: '平庸日',
    emoji: '😐',
    description: '今天没有什么特别之处。',
    probability: 0.30,
    effects: {},
  ),
];

/// 根据ID获取运势
Fortune? getFortune(String id) {
  try {
    return fortunes.firstWhere((f) => f.id == id);
  } catch (_) {
    return null;
  }
}

/// 按概率随机选择运势
Fortune getRandomFortune() {
  final random = DateTime.now().millisecondsSinceEpoch.toDouble() % 100;
  var cumulative = 0.0;
  for (final fortune in fortunes) {
    cumulative += fortune.probability;
    if (random / 100 < cumulative) {
      return fortune;
    }
  }
  return fortunes.last; // fallback
}

/// 基于日期生成运势（同一日期返回相同结果）
Fortune getFortuneByDate(DateTime date) {
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final randomValue = seed % 100;
  var cumulative = 0.0;
  for (final fortune in fortunes) {
    cumulative += fortune.probability;
    if (randomValue / 100 < cumulative) {
      return fortune;
    }
  }
  return fortunes.last;
}