import 'dart:math';

import '../data/models/item_model.dart';
import '../data/seed_data/items.dart';
import '../data/seed_data/affixes.dart';

/// 装备生成器
///
/// 负责为物品附加随机词缀，生成带属性的装备
class GearGenerator {
  static final Random _random = Random();

  /// 生成带词缀的装备
  ///
  /// [baseItemId] 基础物品ID（如 'iron_sword'）
  /// [playerLevel] 玩家等级，影响词缀稀有度上限
  /// [forceAffixId] 强制指定词缀（可选）
  static GameItem generateGear({
    required String baseItemId,
    int playerLevel = 1,
    String? forceAffixId,
  }) {
    // 1. 获取基础物品模板
    final baseItem = getItemTemplate(baseItemId);
    if (baseItem == null) {
      throw Exception('物品模板不存在: $baseItemId');
    }

    // 2. 确定可用词缀
    final isWeapon = baseItem.type == 'weapon';
    final isArmor = baseItem.type == 'armor';
    final isAccessory = baseItem.type == 'accessory';

    String? equipmentType;
    if (isWeapon) equipmentType = 'weapon';
    if (isArmor) equipmentType = 'armor';
    if (isAccessory) equipmentType = 'accessory';

    // 3. 选择词缀
    EquipmentAffix? selectedAffix;
    if (forceAffixId != null) {
      selectedAffix = getAffix(forceAffixId);
    } else if (equipmentType != null) {
      // 根据稀有度权重选择
      selectedAffix = _selectAffixByRarity(equipmentType, playerLevel);
    }

    // 4. 构建最终物品
    final finalName = selectedAffix != null
        ? '${selectedAffix.name}${baseItem.name}'
        : baseItem.name;

    final finalEmoji = selectedAffix != null
        ? '${selectedAffix.emoji}${baseItem.emoji}'
        : baseItem.emoji;

    // 5. 应用词缀属性加成
    var atkBonus = baseItem.atkBonus;
    var defBonus = baseItem.defBonus;
    var extraData = Map<String, dynamic>.from(baseItem.extraData ?? {});

    if (selectedAffix != null) {
      final effects = selectedAffix.effects;
      effects.forEach((key, value) {
        switch (key) {
          case 'atk':
            atkBonus += value as int;
            break;
          case 'def':
            defBonus += value as int;
            break;
          case 'str':
            extraData['strengthBonus'] = (extraData['strengthBonus'] ?? 0) + value;
            break;
          case 'dex':
            extraData['dexterityBonus'] = (extraData['dexterityBonus'] ?? 0) + value;
            break;
          case 'int':
            extraData['intelligenceBonus'] = (extraData['intelligenceBonus'] ?? 0) + value;
            break;
          case 'critRate':
            extraData['critRateBonus'] = (extraData['critRateBonus'] ?? 0.0) + (value as double);
            break;
          case 'lifeSteal':
            extraData['lifeSteal'] = (extraData['lifeSteal'] ?? 0.0) + (value as double);
            break;
          case 'hpRegen':
            extraData['hpRegen'] = (extraData['hpRegen'] ?? 0) + value;
            break;
          case 'magicResist':
            extraData['magicResist'] = (extraData['magicResist'] ?? 0.0) + (value as double);
            break;
          case 'dropRate':
            extraData['dropRateBonus'] = (extraData['dropRateBonus'] ?? 0.0) + (value as double);
            break;
          case 'expRate':
            extraData['expRateBonus'] = (extraData['expRateBonus'] ?? 0.0) + (value as double);
            break;
          case 'goldRate':
            extraData['goldRateBonus'] = (extraData['goldRateBonus'] ?? 0.0) + (value as double);
            break;
          case 'durabilityBonus':
            final newDurability = (baseItem.maxDurability * (1 + (value as double))).round();
            extraData['maxDurability'] = newDurability;
            break;
          case 'elementFire':
            extraData['elementFire'] = (extraData['elementFire'] ?? 0) + value;
            break;
          case 'elementFrost':
            extraData['elementFrost'] = (extraData['elementFrost'] ?? 0) + value;
            break;
          case 'elementLightning':
            extraData['elementLightning'] = (extraData['elementLightning'] ?? 0) + value;
            break;
          case 'holyDamage':
            extraData['holyDamageBonus'] = (extraData['holyDamageBonus'] ?? 0.0) + (value as double);
            break;
          case 'rangedBonus':
            extraData['rangedBonus'] = (extraData['rangedBonus'] ?? 0.0) + (value as double);
            break;
          case 'blockRate':
            extraData['blockRateBonus'] = (extraData['blockRateBonus'] ?? 0.0) + (value as double);
            break;
          default:
            extraData[key] = value;
        }
      });

      // 记录词缀ID
      extraData['affixId'] = selectedAffix.id;
      extraData['affixName'] = selectedAffix.name;
      extraData['affixRarity'] = selectedAffix.rarity;
    }

    // 6. 更新标签（词缀稀有度影响品质标签）
    final tags = List<String>.from(baseItem.tags);
    if (selectedAffix != null) {
      switch (selectedAffix.rarity) {
        case 2:
          if (!tags.contains('rare')) tags.add('rare');
          break;
        case 3:
          tags.remove('rare');
          if (!tags.contains('epic')) tags.add('epic');
          break;
        case 4:
          tags.remove('rare');
          tags.remove('epic');
          if (!tags.contains('legendary')) tags.add('legendary');
          break;
      }
    }

    return baseItem.copyWith(
      name: finalName,
      emoji: finalEmoji,
      atkBonus: atkBonus,
      defBonus: defBonus,
      value: baseItem.value + (selectedAffix?.rarity ?? 0) * 10,
      tags: tags,
      extraData: extraData,
    );
  }

  /// 根据玩家等级选择合适稀有度的词缀
  static EquipmentAffix? _selectAffixByRarity(String equipmentType, int playerLevel) {
    // 1. 确定最大稀有度
    int maxRarity;
    if (playerLevel >= 10) {
      maxRarity = 4; // 传说
    } else if (playerLevel >= 7) {
      maxRarity = 3; // 史诗
    } else if (playerLevel >= 4) {
      maxRarity = 2; // 稀有
    } else {
      maxRarity = 1; // 普通
    }

    // 2. 获取候选词缀
    final candidates = affixes.where((a) {
      // 适用类型匹配
      if (!a.applicableTypes.contains(equipmentType)) return false;
      // 稀有度不超过上限
      if (a.rarity > maxRarity) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) return null;

    // 3. 按权重随机选择（高品质词缀权重降低）
    final weighted = <EquipmentAffix, double>{};
    for (final affix in candidates) {
      // 稀有度越高，额外权重惩罚
      final rarityPenalty = 1.0 / (affix.rarity * 0.5 + 0.5);
      weighted[affix] = affix.spawnWeight * rarityPenalty;
    }

    // 4. 加权随机选择
    final totalWeight = weighted.values.fold(0.0, (sum, w) => sum + w);
    var random = _random.nextDouble() * totalWeight;
    for (final entry in weighted.entries) {
      random -= entry.value;
      if (random <= 0) {
        return entry.key;
      }
    }
    return candidates.last;
  }

  /// 判断是否为可装备物品
  static bool isEquippable(GameItem item) {
    return item.type == 'weapon' || item.type == 'armor' || item.type == 'accessory';
  }

  /// 获取词缀稀有度显示名
  static String getRarityLabel(int rarity) {
    switch (rarity) {
      case 1:
        return '普通';
      case 2:
        return '稀有';
      case 3:
        return '史诗';
      case 4:
        return '传说';
      default:
        return '普通';
    }
  }

  /// 获取词缀稀有度颜色
  static String getRarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return '#8a8a8a';
      case 2:
        return '#3399ff';
      case 3:
        return '#aa55ff';
      case 4:
        return '#ffaa00';
      default:
        return '#8a8a8a';
    }
  }
}