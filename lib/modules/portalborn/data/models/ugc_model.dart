import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'ugc_model.g.dart';

/// UGC 自定义领域 Hive 实体
/// typeId: 36
@HiveType(typeId: 36)
class UGCCustomRealm {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String author;

  @HiveField(3)
  String description;

  @HiveField(4)
  String version;

  @HiveField(5)
  List<UGCRoom> rooms;

  @HiveField(6)
  String entryRoomId;

  @HiveField(7)
  List<UGCMonster> customMonsters;

  @HiveField(8)
  List<UGCItem> customItems;

  @HiveField(9)
  List<String> requiredItems;

  @HiveField(10)
  bool isImported; // true=导入，false=自建

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? lastPlayedAt;

  UGCCustomRealm({
    String? id,
    required this.name,
    required this.author,
    required this.description,
    this.version = '1.0.0',
    this.rooms = const [],
    required this.entryRoomId,
    this.customMonsters = const [],
    this.customItems = const [],
    this.requiredItems = const [],
    this.isImported = false,
    DateTime? createdAt,
    this.lastPlayedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// 复制并更新
  UGCCustomRealm copyWith({
    String? id,
    String? name,
    String? author,
    String? description,
    String? version,
    List<UGCRoom>? rooms,
    String? entryRoomId,
    List<UGCMonster>? customMonsters,
    List<UGCItem>? customItems,
    List<String>? requiredItems,
    bool? isImported,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
  }) {
    return UGCCustomRealm(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      description: description ?? this.description,
      version: version ?? this.version,
      rooms: rooms ?? this.rooms,
      entryRoomId: entryRoomId ?? this.entryRoomId,
      customMonsters: customMonsters ?? this.customMonsters,
      customItems: customItems ?? this.customItems,
      requiredItems: requiredItems ?? this.requiredItems,
      isImported: isImported ?? this.isImported,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}

/// UGC 房间（嵌套在 UGCCustomRealm 中）
/// typeId: 37
@HiveType(typeId: 37)
class UGCRoom {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<UGCExit> exits;

  @HiveField(4)
  List<UGCInteractable> objects;

  @HiveField(5)
  String? monsterId;

  @HiveField(6)
  List<String> tags; // ['safe', 'dark', 'noisy', 'treasure', 'boss_room']

  UGCRoom({
    String? id,
    required this.name,
    required this.description,
    this.exits = const [],
    this.objects = const [],
    this.monsterId,
    this.tags = const [],
  }) : id = id ?? const Uuid().v4();

  UGCRoom copyWith({
    String? id,
    String? name,
    String? description,
    List<UGCExit>? exits,
    List<UGCInteractable>? objects,
    String? monsterId,
    List<String>? tags,
  }) {
    return UGCRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exits: exits ?? this.exits,
      objects: objects ?? this.objects,
      monsterId: monsterId ?? this.monsterId,
      tags: tags ?? this.tags,
    );
  }
}

/// UGC 出口
@HiveType(typeId: 38)
class UGCExit {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String direction; // 'north'|'south'|'east'|'west'|'up'|'down'|'portal'

  @HiveField(2)
  String targetRoomId;

  @HiveField(3)
  String description;

  @HiveField(4)
  bool isHidden;

  @HiveField(5)
  bool isLocked;

  @HiveField(6)
  String? keyItemId;

  @HiveField(7)
  bool isOneWay;

  UGCExit({
    String? id,
    required this.direction,
    required this.targetRoomId,
    required this.description,
    this.isHidden = false,
    this.isLocked = false,
    this.keyItemId,
    this.isOneWay = false,
  }) : id = id ?? const Uuid().v4();

  UGCExit copyWith({
    String? id,
    String? direction,
    String? targetRoomId,
    String? description,
    bool? isHidden,
    bool? isLocked,
    String? keyItemId,
    bool? isOneWay,
  }) {
    return UGCExit(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      targetRoomId: targetRoomId ?? this.targetRoomId,
      description: description ?? this.description,
      isHidden: isHidden ?? this.isHidden,
      isLocked: isLocked ?? this.isLocked,
      keyItemId: keyItemId ?? this.keyItemId,
      isOneWay: isOneWay ?? this.isOneWay,
    );
  }
}

/// UGC 可互动物件
@HiveType(typeId: 39)
class UGCInteractable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<String> actions; // ['open', 'search', 'examine', 'use', 'take']

  @HiveField(4)
  Map<String, dynamic>? result; // 交互结果

  UGCInteractable({
    String? id,
    required this.name,
    required this.description,
    this.actions = const [],
    this.result,
  }) : id = id ?? const Uuid().v4();

  UGCInteractable copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? actions,
    Map<String, dynamic>? result,
  }) {
    return UGCInteractable(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      actions: actions ?? this.actions,
      result: result ?? this.result,
    );
  }
}

/// UGC 自定义怪物
@HiveType(typeId: 40)
class UGCMonster {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  String description;

  @HiveField(4)
  int baseHp;

  @HiveField(5)
  int attack;

  @HiveField(6)
  int defense;

  @HiveField(7)
  int expReward;

  @HiveField(8)
  int goldReward;

  @HiveField(9)
  List<UGCDrop> drops;

  @HiveField(10)
  List<String> tags; // ['boss', 'undead', 'beast', 'magical', 'elite']

  UGCMonster({
    String? id,
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
  }) : id = id ?? const Uuid().v4();

  UGCMonster copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    int? baseHp,
    int? attack,
    int? defense,
    int? expReward,
    int? goldReward,
    List<UGCDrop>? drops,
    List<String>? tags,
  }) {
    return UGCMonster(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      baseHp: baseHp ?? this.baseHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      expReward: expReward ?? this.expReward,
      goldReward: goldReward ?? this.goldReward,
      drops: drops ?? this.drops,
      tags: tags ?? this.tags,
    );
  }
}

/// UGC 掉落表
@HiveType(typeId: 41)
class UGCDrop {
  @HiveField(0)
  String itemId;

  @HiveField(1)
  double probability; // 0.0 - 1.0

  @HiveField(2)
  int minCount;

  @HiveField(3)
  int maxCount;

  UGCDrop({
    required this.itemId,
    required this.probability,
    this.minCount = 1,
    this.maxCount = 1,
  });
}

/// UGC 自定义物品
@HiveType(typeId: 42)
class UGCItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type;

  @HiveField(3)
  String subType;

  @HiveField(4)
  int atkBonus;

  @HiveField(5)
  int defBonus;

  @HiveField(6)
  int healAmount;

  @HiveField(7)
  String description;

  @HiveField(8)
  String emoji;

  @HiveField(9)
  int value;

  @HiveField(10)
  List<String> tags;

  UGCItem({
    String? id,
    required this.name,
    required this.type,
    required this.subType,
    this.atkBonus = 0,
    this.defBonus = 0,
    this.healAmount = 0,
    required this.description,
    required this.emoji,
    this.value = 0,
    this.tags = const [],
  }) : id = id ?? const Uuid().v4();

  UGCItem copyWith({
    String? id,
    String? name,
    String? type,
    String? subType,
    int? atkBonus,
    int? defBonus,
    int? healAmount,
    String? description,
    String? emoji,
    int? value,
    List<String>? tags,
  }) {
    return UGCItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      atkBonus: atkBonus ?? this.atkBonus,
      defBonus: defBonus ?? this.defBonus,
      healAmount: healAmount ?? this.healAmount,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      value: value ?? this.value,
      tags: tags ?? this.tags,
    );
  }
}