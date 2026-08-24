import 'package:hive_ce/hive.dart';

import '../data/models/account_model.dart';
import '../data/models/category_model.dart';

/// 记账 box（'ledger'）schema 迁移框架。
///
/// 约定：
/// - box 内以 `schemaVersion` 键记录当前数据版本（int，缺省视为 0）
/// - [_steps] 中第 i 个函数表示「从版本 i 升级到 i+1」的一次性迁移
/// - 迁移必须幂等友好：重复执行不应产生副作用（框架保证只执行一次，
///   但防御性写法可以在函数内部再做条件判断）
///
/// 新增迁移：在 [_steps] 末尾追加函数，并让 [currentVersion] 保持
/// 与 _steps.length 一致。
class LedgerMigrations {
  LedgerMigrations._();

  static const int currentVersion = 1;

  static final List<Future<void> Function(Box)> _steps = [
    _v0ToV1,
  ];

  /// 将 box 数据迁移到 [currentVersion]。幂等，可每次启动调用。
  static Future<void> migrate(Box box) async {
    final v = box.get('schemaVersion') as int? ?? 0;
    if (v >= currentVersion) return;
    for (var i = v; i < _steps.length && i < currentVersion; i++) {
      await _steps[i](box);
      await box.put('schemaVersion', i + 1);
    }
  }

  /// v0 → v1：
  /// 1. 同 id 账户去重（历史键名差异 account_cash / account_acc_cash 造成重复）
  /// 2. 分类 icon 仍为默认 '🏷️' 的旧数据，从名称首段提取 emoji（'🍜 餐饮' → '🍜'）
  static Future<void> _v0ToV1(Box box) async {
    // 1) 账户去重：优先保留带余额数据的记录（initialBalanceCents != 0），
    //    全部为 0 时保留遍历遇到的第一条
    final accountsById = <String, List<MapEntry<dynamic, LedgerAccount>>>{};
    for (final key in box.keys) {
      final v = box.get(key);
      if (v is! LedgerAccount) continue;
      accountsById.putIfAbsent(v.id, () => []).add(MapEntry(key, v));
    }
    for (final entries in accountsById.values) {
      if (entries.length <= 1) continue;
      entries.sort((a, b) {
        final aHasData = a.value.initialBalanceCents != 0 ? 0 : 1;
        final bHasData = b.value.initialBalanceCents != 0 ? 0 : 1;
        return aHasData.compareTo(bHasData);
      });
      for (var i = 1; i < entries.length; i++) {
        await box.delete(entries[i].key);
      }
    }

    // 2) 分类 icon 迁移
    for (final key in box.keys.where((k) => k.toString().startsWith('category_'))) {
      final c = box.get(key);
      if (c is LedgerCategory &&
          c.icon == '🏷️' &&
          c.name.contains(' ') &&
          c.name.split(' ').first.isNotEmpty) {
        c.icon = c.name.split(' ').first;
        await box.put(key, c);
      }
    }
  }
}
