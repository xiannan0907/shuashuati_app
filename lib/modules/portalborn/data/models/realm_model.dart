import 'monster_model.dart'; // 添加此行
// / 领域模型（运行时使用，不持久化到 Hive）
class Realm {
  final String id;
  final String name;
  final String theme;
  final String description;
  final int difficulty;
  final List<Room> rooms;
  final String entryRoomId;
  final String? bossRoomId;
  final List<String> requiredItems;
  final bool isCompleted;

  Realm({
    required this.id,
    required this.name,
    required this.theme,
    required this.description,
    required this.difficulty,
    required this.rooms,
    required this.entryRoomId,
    this.bossRoomId,
    this.requiredItems = const [],
    this.isCompleted = false,
  });

  Realm copyWith({
    String? id,
    String? name,
    String? theme,
    String? description,
    int? difficulty,
    List<Room>? rooms,
    String? entryRoomId,
    String? bossRoomId,
    List<String>? requiredItems,
    bool? isCompleted,
  }) {
    return Realm(
      id: id ?? this.id,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      rooms: rooms ?? this.rooms,
      entryRoomId: entryRoomId ?? this.entryRoomId,
      bossRoomId: bossRoomId ?? this.bossRoomId,
      requiredItems: requiredItems ?? this.requiredItems,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Room? getRoom(String roomId) {
    try {
      return rooms.firstWhere((r) => r.id == roomId);
    } catch (_) {
      return null;
    }
  }

  Room get entryRoom => rooms.firstWhere((r) => r.id == entryRoomId);
  Room? get bossRoom => bossRoomId != null ? getRoom(bossRoomId!) : null;
  int get exploredCount => rooms.where((r) => r.isExplored).length;
  double get progress => rooms.isEmpty ? 0.0 : exploredCount / rooms.length;
}

/// 房间模型（运行时）
class Room {
  final String id;
  final String name;
  final String description;
  final List<Exit> exits;
  final List<InteractableObject> objects;
  MonsterInstance? monster; // ✅ 改为 MonsterInstance
  final List<String> tags;
  final String? ambientSound;
  final String? secretHint;
  bool isExplored;

  Room({
    required this.id,
    required this.name,
    required this.description,
    this.exits = const [],
    this.objects = const [],
    this.monster,
    this.tags = const [],
    this.ambientSound,
    this.secretHint,
    this.isExplored = false,
  });

  Room copyWith({
    String? id,
    String? name,
    String? description,
    List<Exit>? exits,
    List<InteractableObject>? objects,
    MonsterInstance? monster, // ✅ 改为 MonsterInstance
    List<String>? tags,
    String? ambientSound,
    String? secretHint,
    bool? isExplored,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exits: exits ?? this.exits,
      objects: objects ?? this.objects,
      monster: monster ?? this.monster,
      tags: tags ?? this.tags,
      ambientSound: ambientSound ?? this.ambientSound,
      secretHint: secretHint ?? this.secretHint,
      isExplored: isExplored ?? this.isExplored,
    );
  }

  bool get isSafe => tags.contains('safe');
  bool get isDark => tags.contains('dark');
  bool get hasMonster => monster != null && !monster!.isDead;

  Exit? getExit(String direction) {
    try {
      return exits.firstWhere((e) => e.direction == direction);
    } catch (_) {
      return null;
    }
  }

  List<Exit> get visibleExits => exits.where((e) => !e.isHidden).toList();
}

/// 出口模型（运行时）
class Exit {
  final String id;
  final String direction;
  final String targetRoomId;
  final String description;
  final bool isHidden;
  final bool isLocked;
  final String? keyItemId;
  final bool isOneWay;

  Exit({
    required this.id,
    required this.direction,
    required this.targetRoomId,
    required this.description,
    this.isHidden = false,
    this.isLocked = false,
    this.keyItemId,
    this.isOneWay = false,
  });

  Exit copyWith({
    String? id,
    String? direction,
    String? targetRoomId,
    String? description,
    bool? isHidden,
    bool? isLocked,
    String? keyItemId,
    bool? isOneWay,
  }) {
    return Exit(
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

  String get displayName {
    const map = {
      'north': '北',
      'south': '南',
      'east': '东',
      'west': '西',
      'up': '上',
      'down': '下',
      'portal': '🌀 传送门',
    };
    return map[direction] ?? direction;
  }
}

/// 可互动物件（运行时）
class InteractableObject {
  final String id;
  final String name;
  final String description;
  final List<String> actions;
  final Map<String, dynamic>? result;
  bool isUsed;

  InteractableObject({
    required this.id,
    required this.name,
    required this.description,
    this.actions = const [],
    this.result,
    this.isUsed = false,
  });

  InteractableObject copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? actions,
    Map<String, dynamic>? result,
    bool? isUsed,
  }) {
    return InteractableObject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      actions: actions ?? this.actions,
      result: result ?? this.result,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  bool get isInteractable => actions.isNotEmpty && !isUsed;
}