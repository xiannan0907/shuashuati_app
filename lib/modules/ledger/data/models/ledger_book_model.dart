import 'package:hive_ce/hive.dart';

part 'ledger_book_model.g.dart';

/// 账本（多账本：日常/学习/旅行…）
/// typeId: 53
@HiveType(typeId: 53)
class LedgerBook {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  /// 是否默认账本
  @HiveField(3)
  bool isDefault;

  @HiveField(4)
  final DateTime createdAt;

  LedgerBook({
    required this.id,
    required this.name,
    this.icon = '📘',
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
