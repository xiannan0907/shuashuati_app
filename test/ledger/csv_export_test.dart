// 记账 CSV 导出测试：临时 Hive 环境 + 种子数据 → 校验表头/转义/分类账户名解析
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:shuashuati_app/hive_registrar.g.dart';
import 'package:shuashuati_app/modules/ledger/data/models/account_model.dart';
import 'package:shuashuati_app/modules/ledger/data/models/category_model.dart';
import 'package:shuashuati_app/modules/ledger/data/models/transaction_model.dart';
import 'package:shuashuati_app/modules/ledger/data/repositories/ledger_repository.dart';

void main() {
  late Directory tmp;
  late LedgerRepository repo;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('csv_test');
    Hive.init(tmp.path);
    Hive.registerAdapters();
    repo = LedgerRepository();
    await repo.initIfNeeded();
  });

  tearDownAll(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('CSV 导出：表头/BOM/分类与账户名解析', () async {
    await repo.saveTransaction(LedgerTransaction(
      id: 't1',
      type: 'expense',
      amountCents: 5800,
      categoryId: 'cat_exp_${Uri.encodeComponent('🍜 餐饮')}',
      accountId: 'acc_cash',
      note: '午饭, 含饮料',
      date: DateTime(2026, 8, 23, 12, 30),
      ledgerId: 'default',
    ));

    final csv = await repo.exportMonthCsv('2026-08');
    final lines = csv.trim().split('\n');

    expect(csv.startsWith('\uFEFF'), isTrue, reason: '应有 UTF-8 BOM');
    expect(lines.first, contains('日期,星期,类型,分类,账户,金额(元),备注'));
    expect(lines.length, 2, reason: '表头 + 1 条流水');

    expect(lines[1], contains('支出'));
    expect(lines[1], contains('🍜 餐饮'));
    expect(lines[1], contains('58.00'));
    // 备注含逗号应被引号包裹
    expect(lines[1], contains('"午饭, 含饮料"'));
  });

  test('CSV 导出：空月份只有表头', () async {
    final csv = await repo.exportMonthCsv('1999-01');
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv.trim().split('\n').length, 1);
  });
}
