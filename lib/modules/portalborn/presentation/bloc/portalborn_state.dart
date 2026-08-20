import 'package:equatable/equatable.dart';

import '../../data/models/character_model.dart';
import '../../data/models/item_model.dart';
import '../../data/models/game_state_model.dart';
import '../../data/models/realm_model.dart';
import '../../data/models/monster_model.dart';

/// Portalborn 所有状态定义
abstract class PortalbornState extends Equatable {
  const PortalbornState();

  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════
// 🚀 加载与初始化
// ═══════════════════════════════════════════════════════════════

/// 加载中
class PortalbornLoading extends PortalbornState {}

/// 主菜单
class PortalbornMainMenu extends PortalbornState {
  final bool hasSave;
  final List<GameCharacter> characters;

  const PortalbornMainMenu({
    required this.hasSave,
    this.characters = const [],
  });

  @override
  List<Object?> get props => [hasSave, characters];
}

/// 错误状态
class PortalbornError extends PortalbornState {
  final String message;

  const PortalbornError(this.message);

  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════
// 🏠 游戏大厅（核心状态）
// ═══════════════════════════════════════════════════════════════

/// 游戏大厅（安全区）
class PortalbornHub extends PortalbornState {
  final GameCharacter character;
  final List<GameItem> inventory;
  final GameState gameState;
  final List<String> messages;
  final bool isInventoryOpen;
  final bool isCraftingOpen;
  final bool isWorkshopOpen;
  final bool isLoreOpen;

  const PortalbornHub({
    required this.character,
    required this.inventory,
    required this.gameState,
    this.messages = const [],
    this.isInventoryOpen = false,
    this.isCraftingOpen = false,
    this.isWorkshopOpen = false,
    this.isLoreOpen = false,
  });

  PortalbornHub copyWith({
    GameCharacter? character,
    List<GameItem>? inventory,
    GameState? gameState,
    List<String>? messages,
    bool? isInventoryOpen,
    bool? isCraftingOpen,
    bool? isWorkshopOpen,
    bool? isLoreOpen,
  }) {
    return PortalbornHub(
      character: character ?? this.character,
      inventory: inventory ?? this.inventory,
      gameState: gameState ?? this.gameState,
      messages: messages ?? this.messages,
      isInventoryOpen: isInventoryOpen ?? this.isInventoryOpen,
      isCraftingOpen: isCraftingOpen ?? this.isCraftingOpen,
      isWorkshopOpen: isWorkshopOpen ?? this.isWorkshopOpen,
      isLoreOpen: isLoreOpen ?? this.isLoreOpen,
    );
  }

  @override
  List<Object?> get props => [
    character,
    inventory,
    gameState,
    messages,
    isInventoryOpen,
    isCraftingOpen,
    isWorkshopOpen,
    isLoreOpen,
  ];
}

// ═══════════════════════════════════════════════════════════════
// 🧭 探索状态
// ═══════════════════════════════════════════════════════════════

/// 探索中
class PortalbornExploring extends PortalbornState {
  final GameCharacter character;
  final List<GameItem> inventory;
  final GameState gameState;
  final Realm currentRealm;
  final Room currentRoom;
  final int roomIndex;
  final int totalRooms;
  final List<String> messages;
  final bool isInBattle;
  final MonsterInstance? currentMonster;

  const PortalbornExploring({
    required this.character,
    required this.inventory,
    required this.gameState,
    required this.currentRealm,
    required this.currentRoom,
    required this.roomIndex,
    required this.totalRooms,
    this.messages = const [],
    this.isInBattle = false,
    this.currentMonster,
  });

  PortalbornExploring copyWith({
    GameCharacter? character,
    List<GameItem>? inventory,
    GameState? gameState,
    Realm? currentRealm,
    Room? currentRoom,
    int? roomIndex,
    int? totalRooms,
    List<String>? messages,
    bool? isInBattle,
    MonsterInstance? currentMonster,
  }) {
    return PortalbornExploring(
      character: character ?? this.character,
      inventory: inventory ?? this.inventory,
      gameState: gameState ?? this.gameState,
      currentRealm: currentRealm ?? this.currentRealm,
      currentRoom: currentRoom ?? this.currentRoom,
      roomIndex: roomIndex ?? this.roomIndex,
      totalRooms: totalRooms ?? this.totalRooms,
      messages: messages ?? this.messages,
      isInBattle: isInBattle ?? this.isInBattle,
      currentMonster: currentMonster ?? this.currentMonster,
    );
  }

  /// 获取当前房间的可见出口
  List<Exit> get visibleExits => currentRoom.visibleExits;

  /// 获取当前房间的可互动物件
  List<InteractableObject> get interactableObjects =>
      currentRoom.objects.where((o) => o.isInteractable).toList();

  /// 探索进度
  double get progress => currentRealm.progress;

  @override
  List<Object?> get props => [
    character,
    inventory,
    gameState,
    currentRealm,
    currentRoom,
    roomIndex,
    totalRooms,
    messages,
    isInBattle,
    currentMonster,
  ];
}

// ═══════════════════════════════════════════════════════════════
// ⚔️ 战斗状态（专用）
// ═══════════════════════════════════════════════════════════════

/// 战斗中
class PortalbornBattle extends PortalbornState {
  final GameCharacter character;
  final List<GameItem> inventory;
  final GameState gameState;
  final Realm currentRealm;
  final Room currentRoom;
  final MonsterInstance monster;
  final List<String> battleLog;
  final bool isPlayerTurn;

  const PortalbornBattle({
    required this.character,
    required this.inventory,
    required this.gameState,
    required this.currentRealm,
    required this.currentRoom,
    required this.monster,
    this.battleLog = const [],
    this.isPlayerTurn = true,
  });

  PortalbornBattle copyWith({
    GameCharacter? character,
    List<GameItem>? inventory,
    GameState? gameState,
    Realm? currentRealm,
    Room? currentRoom,
    MonsterInstance? monster,
    List<String>? battleLog,
    bool? isPlayerTurn,
  }) {
    return PortalbornBattle(
      character: character ?? this.character,
      inventory: inventory ?? this.inventory,
      gameState: gameState ?? this.gameState,
      currentRealm: currentRealm ?? this.currentRealm,
      currentRoom: currentRoom ?? this.currentRoom,
      monster: monster ?? this.monster,
      battleLog: battleLog ?? this.battleLog,
      isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
    );
  }

  @override
  List<Object?> get props => [
    character,
    inventory,
    gameState,
    currentRealm,
    currentRoom,
    monster,
    battleLog,
    isPlayerTurn,
  ];
}