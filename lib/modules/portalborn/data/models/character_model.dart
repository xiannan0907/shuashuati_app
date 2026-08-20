import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'character_model.g.dart';

/// 游戏角色 Hive 实体
/// typeId: 33
@HiveType(typeId: 33)
class GameCharacter {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // 角色名（2-12字符）

  @HiveField(2)
  final String mainClass; // 'warrior'|'mage'|'rogue'|'priest'|'ranger'

  @HiveField(3)
  final List<String> unlockedClasses; // 已解锁的副职业列表

  @HiveField(4)
  final List<String> equippedSkills; // 已装备的技能ID列表（最多3个）

  @HiveField(5)
  int level;

  @HiveField(6)
  int exp;

  @HiveField(7)
  int maxHp;

  @HiveField(8)
  int currentHp;

  @HiveField(9)
  int baseAttack;

  @HiveField(10)
  int baseDefense;

  @HiveField(11)
  int strength;

  @HiveField(12)
  int dexterity;

  @HiveField(13)
  int intelligence;

  @HiveField(14)
  int constitution;

  @HiveField(15)
  int availablePoints; // 可分配属性点

  @HiveField(16)
  List<String> inventoryIds; // 背包物品ID列表（上限20）

  @HiveField(17)
  Map<String, int> materials; // 材料库存: {'iron': 3}

  @HiveField(18)
  String? weaponId; // 当前装备的武器ID

  @HiveField(19)
  String? armorId; // 当前装备的护甲ID

  @HiveField(20)
  String? accessoryId; // 当前装备的饰品ID

  @HiveField(21)
  List<String> completedRealms; // 已完成领域ID列表

  @HiveField(22)
  List<String> discoveredLore; // 已解锁词条ID列表

  @HiveField(23)
  int gold;

  @HiveField(24)
  int totalDeaths;

  @HiveField(25)
  int totalKills;

  @HiveField(26)
  int playTimeSeconds;

  @HiveField(27)
  String lineage; // 'scholar'|'wanderer'|'warrior'|'mystic'|'merchant'|'hunter'

  @HiveField(28)
  int heritagePoints; // 遗产点（未使用的）

  @HiveField(29)
  Map<String, int> heritageTree; // 永久增益树: {'combat_atk': 1}

  @HiveField(30)
  DateTime? lastPlayDate; // 上次游戏日期（用于每日运势）

  @HiveField(31)
  String todayFortune; // 'lucky'|'unlucky'|'wise'|'rich'|'brave'|'normal'

  @HiveField(32)
  bool hasRerolledFortuneToday; // 今日是否已重掷运势

  GameCharacter({
    String? id,
    required this.name,
    required this.mainClass,
    this.unlockedClasses = const [],
    this.equippedSkills = const [],
    this.level = 1,
    this.exp = 0,
    this.maxHp = 20,
    this.currentHp = 20,
    this.baseAttack = 2,
    this.baseDefense = 1,
    this.strength = 5,
    this.dexterity = 5,
    this.intelligence = 5,
    this.constitution = 5,
    this.availablePoints = 0,
    this.inventoryIds = const [],
    this.materials = const {},
    this.weaponId,
    this.armorId,
    this.accessoryId,
    this.completedRealms = const [],
    this.discoveredLore = const [],
    this.gold = 0,
    this.totalDeaths = 0,
    this.totalKills = 0,
    this.playTimeSeconds = 0,
    this.lineage = 'wanderer',
    this.heritagePoints = 0,
    this.heritageTree = const {},
    this.lastPlayDate,
    this.todayFortune = 'normal',
    this.hasRerolledFortuneToday = false,
  }) : id = id ?? const Uuid().v4();

  /// 复制并更新
  GameCharacter copyWith({
    String? id,
    String? name,
    String? mainClass,
    List<String>? unlockedClasses,
    List<String>? equippedSkills,
    int? level,
    int? exp,
    int? maxHp,
    int? currentHp,
    int? baseAttack,
    int? baseDefense,
    int? strength,
    int? dexterity,
    int? intelligence,
    int? constitution,
    int? availablePoints,
    List<String>? inventoryIds,
    Map<String, int>? materials,
    String? weaponId,
    String? armorId,
    String? accessoryId,
    List<String>? completedRealms,
    List<String>? discoveredLore,
    int? gold,
    int? totalDeaths,
    int? totalKills,
    int? playTimeSeconds,
    String? lineage,
    int? heritagePoints,
    Map<String, int>? heritageTree,
    DateTime? lastPlayDate,
    String? todayFortune,
    bool? hasRerolledFortuneToday,
  }) {
    return GameCharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      mainClass: mainClass ?? this.mainClass,
      unlockedClasses: unlockedClasses ?? this.unlockedClasses,
      equippedSkills: equippedSkills ?? this.equippedSkills,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      baseAttack: baseAttack ?? this.baseAttack,
      baseDefense: baseDefense ?? this.baseDefense,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      intelligence: intelligence ?? this.intelligence,
      constitution: constitution ?? this.constitution,
      availablePoints: availablePoints ?? this.availablePoints,
      inventoryIds: inventoryIds ?? this.inventoryIds,
      materials: materials ?? this.materials,
      weaponId: weaponId ?? this.weaponId,
      armorId: armorId ?? this.armorId,
      accessoryId: accessoryId ?? this.accessoryId,
      completedRealms: completedRealms ?? this.completedRealms,
      discoveredLore: discoveredLore ?? this.discoveredLore,
      gold: gold ?? this.gold,
      totalDeaths: totalDeaths ?? this.totalDeaths,
      totalKills: totalKills ?? this.totalKills,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
      lineage: lineage ?? this.lineage,
      heritagePoints: heritagePoints ?? this.heritagePoints,
      heritageTree: heritageTree ?? this.heritageTree,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
      todayFortune: todayFortune ?? this.todayFortune,
      hasRerolledFortuneToday: hasRerolledFortuneToday ?? this.hasRerolledFortuneToday,
    );
  }

  /// 计算总攻击力（基础 + 武器加成）
  int get totalAttack {
    // 后续在 Repository 中计算，这里留作便捷属性
    return baseAttack;
  }

  /// 计算总防御力（基础 + 护甲加成）
  int get totalDefense {
    return baseDefense;
  }

  /// 是否需要升级
  bool get canLevelUp {
    final expNeeded = level * 15 + 10;
    return exp >= expNeeded;
  }

  /// HP 百分比（0.0 - 1.0）
  double get hpPercent {
    if (maxHp <= 0) return 0.0;
    return currentHp.clamp(0, maxHp) / maxHp;
  }
}