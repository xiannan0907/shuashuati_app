import 'package:hive_ce/hive.dart';

part 'account_model.g.dart';

/// 资产账户（现金/微信/支付宝/银行卡…）
/// typeId: 50
@HiveType(typeId: 50)
class LedgerAccount {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon; // emoji

  /// 初始余额（分单位存储，避免浮点误差；显示时 /100）
  @HiveField(3)
  int initialBalanceCents;

  @HiveField(4)
  int sortIndex;

  /// 是否计入总资产（如报销卡可不计）
  @HiveField(5)
  bool includeInNet;

  LedgerAccount({
    required this.id,
    required this.name,
    this.icon = '💰',
    this.initialBalanceCents = 0,
    this.sortIndex = 0,
    this.includeInNet = true,
  });
}
