import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'item_model.g.dart';

/// 游戏物品 Hive 实体
/// typeId: 34
@HiveType(typeId: 34)
class GameItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // 'weapon'|'armor'|'accessory'|'potion'|'material'|'quest'|'scroll'

  @HiveField(3)
  final String subType; // 子类型: 'sword'|'shield'|'helmet'|'ring'|'health'|'mana'|'buff'|...

  @HiveField(4)
  final int atkBonus;

  @HiveField(5)
  final int defBonus;

  @HiveField(6)
  final int healAmount;

  @HiveField(7)
  final int manaRestore;

  @HiveField(8)
  final String description;

  @HiveField(9)
  final String emoji;

  @HiveField(10)
  final int value; // 金币价值（出售价格 = value ~/ 2）

  @HiveField(11)
  final bool isEquipped; // 是否已装备（UI使用）

  @HiveField(12)
  int quantity; // 数量（可堆叠物品）

  @HiveField(13)
  final int durability; // -1 表示无限

  @HiveField(14)
  final int maxDurability;

  @HiveField(15)
  final List<String> tags; // ['magical', 'cursed', 'unique', 'set', 'consumable']

  @HiveField(16)
  final Map<String, dynamic>? extraData; // 扩展数据

  GameItem({
    String? id,
    required this.name,
    required this.type,
    required this.subType,
    this.atkBonus = 0,
    this.defBonus = 0,
    this.healAmount = 0,
    this.manaRestore = 0,
    required this.description,
    required this.emoji,
    this.value = 0,
    this.isEquipped = false,
    this.quantity = 1,
    this.durability = -1,
    this.maxDurability = -1,
    this.tags = const [],
    this.extraData,
  }) : id = id ?? const Uuid().v4();

  /// 复制并更新
  GameItem copyWith({
    String? id,
    String? name,
    String? type,
    String? subType,
    int? atkBonus,
    int? defBonus,
    int? healAmount,
    int? manaRestore,
    String? description,
    String? emoji,
    int? value,
    bool? isEquipped,
    int? quantity,
    int? durability,
    int? maxDurability,
    List<String>? tags,
    Map<String, dynamic>? extraData,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      atkBonus: atkBonus ?? this.atkBonus,
      defBonus: defBonus ?? this.defBonus,
      healAmount: healAmount ?? this.healAmount,
      manaRestore: manaRestore ?? this.manaRestore,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      value: value ?? this.value,
      isEquipped: isEquipped ?? this.isEquipped,
      quantity: quantity ?? this.quantity,
      durability: durability ?? this.durability,
      maxDurability: maxDurability ?? this.maxDurability,
      tags: tags ?? this.tags,
      extraData: extraData ?? this.extraData,
    );
  }

  /// 是否为消耗品
  bool get isConsumable => tags.contains('consumable');

  /// 是否为可装备物品
  bool get isEquippable => type == 'weapon' || type == 'armor' || type == 'accessory';

  /// 是否为材料
  bool get isMaterial => type == 'material';

  /// 出售价格（回收半价）
  int get sellPrice => value ~/ 2;

  /// 是否可堆叠
  bool get isStackable => type == 'potion' || type == 'material' || type == 'scroll';
}