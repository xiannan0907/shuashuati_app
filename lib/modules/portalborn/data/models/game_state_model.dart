import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'game_state_model.g.dart';

/// 游戏状态 Hive 实体
/// typeId: 35
@HiveType(typeId: 35)
class GameState {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String currentCharacterId; // 当前角色ID

  @HiveField(2)
  String? currentRealmId; // 当前所在领域ID（null = 大厅）

  @HiveField(3)
  String? currentRoomId; // 当前所在房间ID

  @HiveField(4)
  List<String> visitedRoomIds; // 本次会话已访问的房间ID

  @HiveField(5)
  List<String> unlockedThemes; // 已解锁的领域主题

  @HiveField(6)
  int totalRealmsCompleted;

  @HiveField(7)
  int totalItemsCrafted;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime lastSavedAt;

  @HiveField(10)
  bool isInBattle; // 是否处于战斗中（运行时状态，存档时保存）

  @HiveField(11)
  String? currentBattleMonsterId; // 当前战斗的怪物ID（运行时）

  GameState({
    String? id,
    required this.currentCharacterId,
    this.currentRealmId,
    this.currentRoomId,
    this.visitedRoomIds = const [],
    this.unlockedThemes = const [],
    this.totalRealmsCompleted = 0,
    this.totalItemsCrafted = 0,
    DateTime? createdAt,
    DateTime? lastSavedAt,
    this.isInBattle = false,
    this.currentBattleMonsterId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastSavedAt = lastSavedAt ?? DateTime.now();

  /// 复制并更新
  GameState copyWith({
    String? id,
    String? currentCharacterId,
    String? currentRealmId,
    String? currentRoomId,
    List<String>? visitedRoomIds,
    List<String>? unlockedThemes,
    int? totalRealmsCompleted,
    int? totalItemsCrafted,
    DateTime? createdAt,
    DateTime? lastSavedAt,
    bool? isInBattle,
    String? currentBattleMonsterId,
  }) {
    return GameState(
      id: id ?? this.id,
      currentCharacterId: currentCharacterId ?? this.currentCharacterId,
      currentRealmId: currentRealmId ?? this.currentRealmId,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      visitedRoomIds: visitedRoomIds ?? this.visitedRoomIds,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      totalRealmsCompleted: totalRealmsCompleted ?? this.totalRealmsCompleted,
      totalItemsCrafted: totalItemsCrafted ?? this.totalItemsCrafted,
      createdAt: createdAt ?? this.createdAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      isInBattle: isInBattle ?? this.isInBattle,
      currentBattleMonsterId: currentBattleMonsterId ?? this.currentBattleMonsterId,
    );
  }
}