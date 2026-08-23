import 'package:hive_ce/hive.dart';

part 'budget_model.g.dart';

/// 月度预算（categoryId 为空 = 总预算）
/// typeId: 54
@HiveType(typeId: 54)
class LedgerBudget {
  @HiveField(0)
  final String id;

  /// 'yyyy-MM'
  @HiveField(1)
  String month;

  /// 预算金额（分单位）
  @HiveField(2)
  int amountCents;

  /// 关联分类（空 = 整月总预算）
  @HiveField(3)
  String? categoryId;

  LedgerBudget({
    required this.id,
    required this.month,
    required this.amountCents,
    this.categoryId,
  });
}
