import 'dart:math';
import 'package:uuid/uuid.dart';

import '../data/models/realm_model.dart';
import '../data/models/monster_model.dart';
import '../data/seed_data/monsters.dart';
import 'theme_data.dart';
import 'gear_generator.dart';

/// 领域生成器
class RealmGenerator {
  static final Random _random = Random();
  static const Uuid _uuid = Uuid();

  /// 生成一个完整的领域
  static Realm generateRealm({
    String? themeId,
    int? difficulty,
    int playerLevel = 1,
  }) {
    // 1. 选择主题
    final selectedThemeId = themeId ?? _selectTheme();
    final theme = getThemeData(selectedThemeId)!;

    // 2. 确定房间数量
    final roomCount = _random.nextInt(theme.maxRooms - theme.minRooms + 1) + theme.minRooms;

    // 3. 确定难度
    final actualDifficulty = difficulty ?? theme.baseDifficulty;

    // 4. 生成房间
    final rooms = <Room>[];
    final roomIds = <String>[];

    // 创建入口房间
    final entryRoom = _createEntryRoom(theme);
    rooms.add(entryRoom);
    roomIds.add(entryRoom.id);

    // 创建中间房间
    for (var i = 1; i < roomCount - 1; i++) {
      final room = _createRoom(theme, i, playerLevel, actualDifficulty);
      rooms.add(room);
      roomIds.add(room.id);
    }

    // 创建 Boss 房间（最后一个房间）
    final bossRoom = _createBossRoom(theme, playerLevel, actualDifficulty);
    rooms.add(bossRoom);
    roomIds.add(bossRoom.id);

    // 5. 连接房间（生成出口）
    _connectRooms(rooms, roomIds);

    // 6. 分配怪物和物件
    _populateRooms(rooms, theme, playerLevel, actualDifficulty);

    // 7. 生成领域
    return Realm(
      id: _uuid.v4(),
      name: _generateRealmName(theme),
      theme: selectedThemeId,
      description: theme.description,
      difficulty: actualDifficulty,
      rooms: rooms,
      entryRoomId: entryRoom.id,
      bossRoomId: bossRoom.id,
      requiredItems: [],
      isCompleted: false,
    );
  }

  /// 选择主题（按权重随机）
  static String _selectTheme() {
    final themes = themeDataMap.keys.toList();
    return themes[_random.nextInt(themes.length)];
  }

  /// 创建入口房间
  static Room _createEntryRoom(ThemeData theme) {
    return Room(
      id: _uuid.v4(),
      name: '${theme.name}入口',
      description: '你踏入了一片${theme.name}。${theme.description}',
      tags: ['safe'],  // ✅ 改为可变列表
      exits: [],       // ✅ 改为可变列表
      isExplored: false,
    );
  }

  /// 创建普通房间
  static Room _createRoom(ThemeData theme, int index, int playerLevel, int difficulty) {
    final tags = <String>[];

    // 随机添加特殊标签
    if (_random.nextDouble() < 0.15) tags.add('dark');
    if (_random.nextDouble() < 0.10) tags.add('noisy');
    if (_random.nextDouble() < 0.05) tags.add('treasure');

    return Room(
      id: _uuid.v4(),
      name: _generateRoomName(theme, index),
      description: _generateRoomDescription(theme, index),
      tags: tags,
      exits: [],       // ✅ 改为可变列表
      isExplored: false,
    );
  }

  /// 创建 Boss 房间
  static Room _createBossRoom(ThemeData theme, int playerLevel, int difficulty) {
    // 选择 Boss 怪物
    final bossPool = theme.monsterPool
        .where((id) => getMonsterTemplate(id)?.tags.contains('boss') ?? false)
        .toList();
    final bossId = bossPool.isNotEmpty
        ? bossPool[_random.nextInt(bossPool.length)]
        : 'shadow_dragon';

    final bossTemplate = getMonsterTemplate(bossId)!;
    final bossInstance = bossTemplate.createInstance(playerLevel);

    return Room(
      id: _uuid.v4(),
      name: 'Boss 房间',
      description: '空气中弥漫着压迫感。你能感觉到强大的存在就在前方。',
      monster: bossInstance,
      tags: ['boss_room', 'elite'],  // ✅ 改为可变列表
      exits: [],                     // ✅ 改为可变列表
      isExplored: false,
    );
  }

  /// 连接房间（生成出口）
  static void _connectRooms(List<Room> rooms, List<String> roomIds) {
    if (rooms.length < 2) return;

    // 按顺序连接房间形成路径
    for (var i = 0; i < rooms.length - 1; i++) {
      final current = rooms[i];
      final next = rooms[i + 1];
      final direction = _getRandomDirection();

      // 当前房间 → 下一个房间
      current.exits.add(Exit(
        id: _uuid.v4(),
        direction: direction,
        targetRoomId: next.id,
        description: '通往 ${next.name}',
        isHidden: false,
        isLocked: false,
        isOneWay: false,
      ));

      // 下一个房间 → 当前房间（反向出口）
      final reverseDir = _getReverseDirection(direction);
      next.exits.add(Exit(
        id: _uuid.v4(),
        direction: reverseDir,
        targetRoomId: current.id,
        description: '返回 ${current.name}',
        isHidden: false,
        isLocked: false,
        isOneWay: false,
      ));
    }

    // 随机添加一些额外连接（形成环路）
    if (rooms.length >= 4 && _random.nextDouble() < 0.3) {
      final fromIndex = _random.nextInt(rooms.length - 2);
      final toIndex = fromIndex + 2 + _random.nextInt(min(3, rooms.length - fromIndex - 2));
      if (toIndex < rooms.length) {
        final from = rooms[fromIndex];
        final to = rooms[toIndex];
        final dir = _getRandomDirection();
        from.exits.add(Exit(
          id: _uuid.v4(),
          direction: dir,
          targetRoomId: to.id,
          description: '一条隐蔽的小路',
          isHidden: true,
          isLocked: false,
          isOneWay: false,
        ));
        to.exits.add(Exit(
          id: _uuid.v4(),
          direction: _getReverseDirection(dir),
          targetRoomId: from.id,
          description: '隐蔽的小路',
          isHidden: true,
          isLocked: false,
          isOneWay: false,
        ));
      }
    }
  }

  /// 分配怪物和物件
  static void _populateRooms(
      List<Room> rooms,
      ThemeData theme,
      int playerLevel,
      int difficulty,
      ) {
    for (final room in rooms) {
      // 跳过入口（安全区）和 Boss 房
      if (room.tags.contains('safe')) continue;
      if (room.tags.contains('boss_room')) continue;

      // 75% 概率放置怪物
      if (_random.nextDouble() < 0.75) {
        final monsterId = theme.getRandomMonster(_random);
        final template = getMonsterTemplate(monsterId);
        if (template != null) {
          final monster = template.createInstance(playerLevel);
          room.monster = monster;
        }
      }

      // 60% 概率放置物件
      if (_random.nextDouble() < 0.6) {
        final objectId = theme.getRandomObject(_random);
        final object = _createInteractableObject(objectId);
        if (object != null) {
          room.objects.add(object);
        }
      }

      // 如果房间有 treasure 标签，保证有一个宝箱
      if (room.tags.contains('treasure')) {
        room.objects.add(InteractableObject(
          id: _uuid.v4(),
          name: '宝箱',
          description: '一个精致的木质宝箱，上面雕刻着精美的花纹。',
          actions: ['open', 'search', 'examine'],
          result: {
            'type': 'chest',
            'gold': 5 + _random.nextInt(15),
            'itemChance': 0.3,
          },
          isUsed: false,
        ));
      }
    }
  }

  /// 创建可互动物件
  static InteractableObject? _createInteractableObject(String objectId) {
    const objectMap = {
      'chest': ['open', 'search', 'examine'],
      'fountain': ['drink', 'examine'],
      'ancient_tree': ['examine', 'search'],
      'shrine': ['examine', 'pray'],
      'mossy_stone': ['examine', 'search'],
      'sarcophagus': ['open', 'search', 'examine'],
      'altar': ['examine', 'pray'],
      'candle_holder': ['take', 'examine'],
      'tombstone': ['examine', 'search'],
      'bone_pile': ['search', 'examine'],
      'workbench': ['examine', 'search'],
      'tool_rack': ['take', 'examine'],
      'healing_fountain': ['drink', 'examine'],
      'elven_statue': ['examine', 'pray'],
      'magic_flower': ['take', 'examine'],
    };

    final actions = objectMap[objectId] ?? ['examine'];
    final nameMap = {
      'chest': '宝箱',
      'fountain': '喷泉',
      'ancient_tree': '古树',
      'shrine': '祭坛',
      'mossy_stone': '苔藓石',
      'sarcophagus': '石棺',
      'altar': '祭坛',
      'candle_holder': '烛台',
      'tombstone': '墓碑',
      'bone_pile': '骨堆',
      'workbench': '工作台',
      'tool_rack': '工具架',
      'healing_fountain': '治愈之泉',
      'elven_statue': '精灵雕像',
      'magic_flower': '魔法之花',
    };

    final descriptions = {
      'chest': '一个木质宝箱，表面覆盖着灰尘。',
      'fountain': '石砌喷泉，水面上漂浮着金色落叶。',
      'ancient_tree': '一棵枝繁叶茂的巨树，树干上刻满了古老的符文。',
      'shrine': '一座小型祭坛，供奉着模糊的神像。',
      'mossy_stone': '长满青苔的石头，似乎被移动过。',
      'sarcophagus': '雕刻着铭文的石棺，年代久远。',
      'altar': '石制祭坛，上面摆着几根熄灭的蜡烛。',
      'candle_holder': '黄铜烛台，上面凝结着蜡泪。',
      'tombstone': '古老的墓碑，字迹已经模糊不清。',
      'bone_pile': '一堆骨头，属于某种大型生物。',
      'workbench': '堆满了工具和半成品的工作台。',
      'tool_rack': '挂着各种工具的架子。',
      'healing_fountain': '清澈的泉水池，水面泛着柔和的光芒。',
      'elven_statue': '手持弓箭的精灵雕像，神情庄重。',
      'magic_flower': '一朵散发着微光的奇异花朵。',
    };

    return InteractableObject(
      id: _uuid.v4(),
      name: nameMap[objectId] ?? objectId,
      description: descriptions[objectId] ?? '一个可以互动的物品。',
      actions: actions,
      result: {'type': 'object', 'objectId': objectId},
      isUsed: false,
    );
  }

  /// 生成房间名
  static String _generateRoomName(ThemeData theme, int index) {
    final prefixes = ['昏暗的', '空旷的', '狭窄的', '潮湿的', '寂静的', '古老的'];
    final suffixes = ['走廊', '大厅', '房间', '洞穴', '密室', '过道'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final suffix = suffixes[_random.nextInt(suffixes.length)];
    return '$prefix$suffix ${index + 1}';
  }

  /// 生成房间描述
  static String _generateRoomDescription(ThemeData theme, int index) {
    final details = [
      '地面上散落着碎石和枯叶。',
      '空气中弥漫着潮湿的气息。',
      '墙壁上爬满了藤蔓和青苔。',
      '你能听到远处传来的滴水声。',
      '这里似乎很久没有人来过了。',
      '角落里有几块碎裂的陶片。',
      '头顶的岩石缝隙中透下微弱的光线。',
    ];
    return details[_random.nextInt(details.length)];
  }

  /// 生成领域名称
  static String _generateRealmName(ThemeData theme) {
    final prefixes = ['古老的', '被遗忘的', '黑暗的', '神秘的', '荒芜的', '破碎的', '永恒的'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    return '$prefix${theme.name}';
  }

  /// 获取随机方向
  static String _getRandomDirection() {
    const directions = ['north', 'south', 'east', 'west', 'up', 'down'];
    return directions[_random.nextInt(directions.length)];
  }

  /// 获取反向方向
  static String _getReverseDirection(String direction) {
    const map = {
      'north': 'south',
      'south': 'north',
      'east': 'west',
      'west': 'east',
      'up': 'down',
      'down': 'up',
    };
    return map[direction] ?? 'north';
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎁 战利品生成（集成词缀系统）
  // ═══════════════════════════════════════════════════════════════

  /// 生成怪物掉落（包含装备）
  static List<RealmDropResult> generateMonsterDrops(
      MonsterInstance monster,
      int playerLevel,
      ) {
    final results = <RealmDropResult>[];

    // 1. 基础掉落（材料）
    for (final drop in monster.drops) {
      if (_random.nextDouble() < drop.probability) {
        final count = drop.minCount + _random.nextInt(drop.maxCount - drop.minCount + 1);
        results.add(RealmDropResult(itemId: drop.itemId, count: count));
      }
    }

    // 2. 装备掉落（15%概率）
    if (_random.nextDouble() < 0.15) {
      final equipmentPool = _getEquipmentPool(monster, playerLevel);
      if (equipmentPool.isNotEmpty) {
        final baseItemId = equipmentPool[_random.nextInt(equipmentPool.length)];
        try {
          final gear = GearGenerator.generateGear(
            baseItemId: baseItemId,
            playerLevel: playerLevel,
          );
          results.add(RealmDropResult(itemId: gear.id, count: 1));
        } catch (_) {
          // 生成失败则忽略
        }
      }
    }

    // 3. Boss 额外掉落（Boss房核心奖励）
    if (monster.isBoss) {
      // 高概率掉落稀有装备
      if (_random.nextDouble() < 0.6) {
        final bossPool = ['steel_sword', 'chain_mail', 'gem_ring', 'frost_sword'];
        final baseId = bossPool[_random.nextInt(bossPool.length)];
        try {
          final gear = GearGenerator.generateGear(
            baseItemId: baseId,
            playerLevel: playerLevel,
            forceAffixId: _selectBossAffix(),
          );
          results.add(RealmDropResult(itemId: gear.id, count: 1));
        } catch (_) {}
      }

      // Boss 额外金币奖励
      final bonusGold = 10 + _random.nextInt(20);
      results.add(RealmDropResult(itemId: 'gold_bonus', count: bonusGold));
    }

    return results;
  }

  /// 获取装备池（根据怪物类型和玩家等级）
  static List<String> _getEquipmentPool(MonsterInstance monster, int playerLevel) {
    final pool = <String>[];
    final tags = monster.tags;

    // 基础装备池
    pool.addAll(['iron_sword', 'leather_armor']);

    if (tags.contains('beast')) {
      pool.addAll(['iron_sword', 'leather_armor', 'wooden_shield']);
    }
    if (tags.contains('undead')) {
      pool.addAll(['bone_shard', 'cultist_robe', 'iron_dagger']);
    }
    if (tags.contains('magical')) {
      pool.addAll(['gem_ring', 'fire_staff', 'shadow_dagger']);
    }
    if (tags.contains('elite') || tags.contains('boss')) {
      pool.addAll(['steel_sword', 'chain_mail', 'plate_armor']);
    }
    if (tags.contains('dragon')) {
      pool.addAll(['frost_sword', 'dragon_scale', 'dragon_hammer']);
    }

    // 高等级玩家有更高概率获得好装备
    if (playerLevel >= 5) {
      pool.addAll(['steel_sword', 'chain_mail', 'gem_ring']);
    }
    if (playerLevel >= 8) {
      pool.addAll(['plate_armor', 'frost_sword', 'shadow_dagger']);
    }
    if (playerLevel >= 10) {
      pool.addAll(['dragon_hammer', 'dragon_scale_armor', 'archmage_staff']);
    }

    return pool;
  }

  /// Boss专属词缀选择
  static String? _selectBossAffix() {
    const bossAffixes = [
      'affix_flame', 'affix_frost', 'affix_thunder',
      'affix_holy', 'affix_shadow', 'affix_life',
      'affix_critical', 'affix_dragon_soul', 'affix_ancient',
      'affix_lucky', 'affix_doom', 'affix_archmage',
    ];
    return bossAffixes[_random.nextInt(bossAffixes.length)];
  }
}

/// 掉落结果数据类
class RealmDropResult {
  final String itemId;
  final int count;

  RealmDropResult({required this.itemId, required this.count});
}