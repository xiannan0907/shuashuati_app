// LedgerMigrations 测试：v0 旧数据 → v1（账户去重 + 分类 icon 迁移）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:shuashuati_app/hive_registrar.g.dart';
import 'package:shuashuati_app/modules/ledger/data/ledger_migrations.dart';
import 'package:shuashuati_app/modules/ledger/data/models/account_model.dart';
import 'package:shuashuati_app/modules/ledger/data/models/category_model.dart';

void main() {
  late Directory tmp;
  late Box box;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('mig_test');
    Hive.init(tmp.path);
    Hive.registerAdapters();
    box = await Hive.openBox('ledger');
  });

  tearDownAll(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('v0→v1：同 id 账户去重保留首个，icon 从名称提取', () async {
    // 模拟旧数据：两个键存同一个 id=cash 的账户；分类 icon 为默认标签
    await box.put(
        'account_cash',
        LedgerAccount(
            id: 'cash', name: '现金', icon: '💵', sortIndex: 0)
          ..initialBalanceCents = -5700);
    await box.put(
        'account_acc_cash',
        LedgerAccount(
            id: 'cash', name: '现金', icon: '💵', sortIndex: 0));
    await box.put(
      'category_old',
      LedgerCategory(
          id: 'cat_exp_old',
          name: '🍜 餐饮',
          type: 'expense',
          colorKey: 'orange'),
    );

    await LedgerMigrations.migrate(box);

    final accounts =
        box.values.whereType<LedgerAccount>().toList();
    expect(accounts.length, 1, reason: '重复账户应被去重');
    expect(accounts.single.initialBalanceCents, -5700,
        reason: '应保留最先写入的一条');

    final cat = box.get('category_old') as LedgerCategory;
    expect(cat.icon, '🍜');
    expect(box.get('schemaVersion'), LedgerMigrations.currentVersion);
  });

  test('migrate 幂等：二次调用不再改动', () async {
    final before = box.keys.length;
    await LedgerMigrations.migrate(box);
    expect(box.keys.length, before);
    expect(box.get('schemaVersion'), LedgerMigrations.currentVersion);
  });
}
