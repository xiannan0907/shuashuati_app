import 'package:hive_ce/hive.dart';

part 'transaction_model.g.dart';

/// 记账流水
/// typeId: 52
@HiveType(typeId: 52)
class LedgerTransaction {
  @HiveField(0)
  final String id;

  /// 'expense' | 'income' | 'transfer'
  @HiveField(1)
  String type;

  /// 金额（分单位）
  @HiveField(2)
  int amountCents;

  /// 分类 id（转账时为空）
  @HiveField(3)
  String? categoryId;

  /// 支出/收入所用账户
  @HiveField(4)
  String accountId;

  /// 转账目标账户（仅 transfer）
  @HiveField(5)
  String? toAccountId;

  @HiveField(6)
  String note;

  @HiveField(7)
  DateTime date;

  @HiveField(8)
  final String ledgerId;

  @HiveField(9)
  final DateTime createdAt;

  /// 报销标记
  @HiveField(10)
  bool reimbursable;

  LedgerTransaction({
    required this.id,
    required this.type,
    required this.amountCents,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.note = '',
    required this.date,
    required this.ledgerId,
    DateTime? createdAt,
    this.reimbursable = false,
  }) : createdAt = createdAt ?? DateTime.now();
}
