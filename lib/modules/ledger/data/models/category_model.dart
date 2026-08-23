import 'package:hive_ce/hive.dart';

part 'category_model.g.dart';

/// 记账分类
/// typeId: 51
@HiveType(typeId: 51)
class LedgerCategory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  /// 'expense' | 'income'
  @HiveField(2)
  String type;

  @HiveField(3)
  String icon; // emoji

  @HiveField(4)
  String colorKey;

  @HiveField(5)
  bool isCustom; // 用户自建（预置分类不可删除，可改名）

  @HiveField(6)
  int sortIndex;

  LedgerCategory({
    required this.id,
    required this.name,
    required this.type,
    this.icon = '🏷️',
    this.colorKey = 'grey',
    this.isCustom = false,
    this.sortIndex = 0,
  });
}
