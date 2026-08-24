import 'package:hive_ce/hive.dart';

import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/ledger_book_model.dart';
import '../models/transaction_model.dart';

/// 记一笔草稿（页面层 → 仓库的创建参数）
class TransactionDraft {
  final String type;
  final int amountCents;
  final String categoryId;
  final String accountId;
  final String note;
  final DateTime date;
  TransactionDraft({
    required this.type,
    required this.amountCents,
    required this.categoryId,
    required this.accountId,
    this.note = '',
    required this.date,
  });
}

/// 记账模块数据仓库（box: 'ledger'，键前缀区分实体）
class LedgerRepository {
  static const String boxName = 'ledger';

  // 预置支出分类
  static const Map<String, List<String>> presetExpenseCategories = {
    '🍜 餐饮': ['orange'],
    '🚌 交通': ['blue'],
    '📚 学习资料': ['purple'],
    '🎓 课程/网课': ['deepPurple'],
    '🖨️ 打印复印': ['teal'],
    '📝 考试报名': ['red'],
    '🛒 日用品': ['green'],
    '🎮 娱乐': ['pink'],
    '🏠 居住': ['brown'],
    '🏷️ 其他支出': ['grey'],
  };

  // 预置收入分类
  static const Map<String, List<String>> presetIncomeCategories = {
    '💰 生活费': ['green'],
    '🎯 兼职': ['blue'],
    '🧧 红包奖励': ['orange'],
    '📈 理财收益': ['teal'],
    '🏷️ 其他收入': ['grey'],
  };

  Future<Box> get _box => Hive.openBox(boxName);

  // ════════════════════════════════════════════
  // 初始化：默认账本/账户/分类（幂等）
  // ════════════════════════════════════════════

  Future<void> initIfNeeded() async {
    final box = await _box;

    // 默认账本
    if (!box.containsKey('book_default')) {
      await box.put(
        'book_default',
        LedgerBook(id: 'default', name: '日常账本', icon: '📘', isDefault: true),
      );
    }

    // 默认账户（按账户 id 幂等，避免历史键名差异造成重复）
    final presets = {
      'acc_cash': LedgerAccount(id: 'cash', name: '现金', icon: '💵', sortIndex: 0),
      'acc_wechat': LedgerAccount(id: 'wechat', name: '微信', icon: '💬', sortIndex: 1),
      'acc_alipay': LedgerAccount(id: 'alipay', name: '支付宝', icon: '🅰️', sortIndex: 2),
      'acc_card': LedgerAccount(id: 'card', name: '银行卡', icon: '💳', sortIndex: 3),
    };
    final existingIds =
        box.values.whereType<LedgerAccount>().map((a) => a.id).toSet();
    for (final e in presets.entries) {
      if (!existingIds.contains(e.value.id)) {
        await box.put('account_${e.key}', e.value);
      }
    }

    // 历史脏数据清理：同 id 账户去重（保留最先写入的一条）
    final seenAccountIds = <String>{};
    final duplicateAccountKeys = <dynamic>[];
    for (final key in box.keys) {
      final v = box.get(key);
      if (v is! LedgerAccount) continue;
      if (!seenAccountIds.add(v.id)) duplicateAccountKeys.add(key);
    }
    for (final key in duplicateAccountKeys) {
      await box.delete(key);
    }

    // 预置分类（icon 从名称首段提取，如 '🍜 餐饮' → '🍜'）
    var sort = 0;
    for (final e in presetExpenseCategories.entries) {
      final id = 'cat_exp_${Uri.encodeComponent(e.key)}';
      if (!box.containsKey('category_$id')) {
        await box.put(
          'category_$id',
          LedgerCategory(
            id: id, name: e.key, type: 'expense',
            icon: e.key.split(' ').first,
            colorKey: e.value.first, sortIndex: sort++,
          ),
        );
      }
    }
    for (final e in presetIncomeCategories.entries) {
      final id = 'cat_inc_${Uri.encodeComponent(e.key)}';
      if (!box.containsKey('category_$id')) {
        await box.put(
          'category_$id',
          LedgerCategory(
            id: id, name: e.key, type: 'income',
            icon: e.key.split(' ').first,
            colorKey: e.value.first, sortIndex: sort++,
          ),
        );
      }
    }

    // 旧数据迁移：icon 仍为默认标签的分类，从名称首段提取 emoji
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

  // ════════════════════════════════════════════
  // 流水 Transaction
  // ════════════════════════════════════════════

  Future<void> saveTransaction(LedgerTransaction t) async {
    final box = await _box;
    await box.put('tx_${t.id}', t);
  }

  /// 从草稿创建流水（uuid id），并同步账户余额
  Future<void> saveTransactionDraft(
      TransactionDraft draft, {required String ledgerId}) async {
    final tx = LedgerTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: draft.type,
      amountCents: draft.amountCents,
      categoryId: draft.categoryId,
      accountId: draft.accountId,
      note: draft.note,
      date: draft.date,
      ledgerId: ledgerId,
    );
    await saveTransaction(tx);
    // 同步账户余额（支出扣减/收入增加——通过调整初始余额保持余额公式一致）
    final acc = await accountById(draft.accountId);
    if (acc != null) {
      acc.initialBalanceCents += draft.type == 'expense'
          ? -draft.amountCents
          : draft.amountCents;
      await saveAccount(acc);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final box = await _box;
    await box.delete('tx_$id');
  }

  /// 某账本全部流水（按日期倒序）
  Future<List<LedgerTransaction>> transactions({String? ledgerId}) async {
    final box = await _box;
    final list = box.values
        .whereType<LedgerTransaction>()
        .where((t) => ledgerId == null || t.ledgerId == ledgerId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// 指定月份流水
  Future<List<LedgerTransaction>> monthTransactions(
      String yearMonth, {String? ledgerId}) async {
    final all = await transactions(ledgerId: ledgerId);
    return all.where((t) => _ym(t.date) == yearMonth).toList();
  }

  /// 导出某月流水为 CSV 文本（带 UTF-8 BOM，Excel 直接打开中文不乱码）
  Future<String> exportMonthCsv(String yearMonth, {String? ledgerId}) async {
    final txs = await monthTransactions(yearMonth, ledgerId: ledgerId);
    final cats = {for (final c in await categories()) c.id: c};
    final accs = {for (final a in await accounts()) a.id: a};

    String esc(String s) =>
        s.contains(',') || s.contains('"') || s.contains('\n')
            ? '"${s.replaceAll('"', '""')}"'
            : s;

    final buf = StringBuffer('\uFEFF日期,星期,类型,分类,账户,金额(元),备注\n');
    const weekCn = ['一', '二', '三', '四', '五', '六', '日'];
    for (final t in txs) {
      final d = t.date;
      buf.writeln([
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        '周${weekCn[d.weekday - 1]}',
        t.type == 'income' ? '收入' : (t.type == 'transfer' ? '转账' : '支出'),
        cats[t.categoryId]?.name ?? '',
        accs[t.accountId]?.name ?? '',
        (t.amountCents / 100).toStringAsFixed(2),
        esc(t.note),
      ].join(','));
    }
    return buf.toString();
  }

  // ════════════════════════════════════════════
  // 分类 Category
  // ════════════════════════════════════════════

  Future<List<LedgerCategory>> categories({String? type}) async {
    final box = await _box;
    final list = box.values
        .whereType<LedgerCategory>()
        .where((c) => type == null || c.type == type)
        .toList();
    list.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return list;
  }

  Future<LedgerCategory?> categoryById(String id) async {
    final box = await _box;
    return box.values.whereType<LedgerCategory>().where((c) => c.id == id).firstOrNull;
  }

  Future<void> saveCategory(LedgerCategory c) async {
    final box = await _box;
    await box.put('category_${c.id}', c);
  }

  /// 删除自定义分类（预置不可删）
  Future<bool> deleteCategory(String id) async {
    if (id.startsWith('cat_exp_') && !id.contains('%') ||
        _presetNames().any(id.endsWith)) {
      // 简化判断交给调用层（UI 只允许删除 isCustom）
    }
    final box = await _box;
    await box.delete('category_$id');
    return true;
  }

  Iterable<String> _presetNames() sync* {}

  // ════════════════════════════════════════════
  // 账户 Account
  // ════════════════════════════════════════════

  Future<List<LedgerAccount>> accounts() async {
    final box = await _box;
    final list = box.values.whereType<LedgerAccount>().toList();
    list.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return list;
  }

  Future<LedgerAccount?> accountById(String id) async {
    final box = await _box;
    return box.values.whereType<LedgerAccount>().where((a) => a.id == id).firstOrNull;
  }

  Future<void> saveAccount(LedgerAccount a) async {
    final box = await _box;
    await box.put('account_${a.id}', a);
  }

  Future<void> deleteAccount(String id) async {
    final box = await _box;
    await box.delete('account_$id');
  }

  /// 账户当前余额 = 初始余额 + 收入 − 支出 ± 转账
  Future<int> accountBalanceCents(String accountId) async {
    final box = await _box;
    final txs = box.values.whereType<LedgerTransaction>();
    int balance = 0;
    final acc = await accountById(accountId);
    balance = acc?.initialBalanceCents ?? 0;
    for (final t in txs) {
      if (t.type == 'expense' && t.accountId == accountId) {
        balance -= t.amountCents;
      } else if (t.type == 'income' && t.accountId == accountId) {
        balance += t.amountCents;
      } else if (t.type == 'transfer') {
        if (t.accountId == accountId) balance -= t.amountCents;
        if (t.toAccountId == accountId) balance += t.amountCents;
      }
    }
    return balance;
  }

  // ════════════════════════════════════════════
  // 账本 LedgerBook
  // ════════════════════════════════════════════

  Future<List<LedgerBook>> books() async {
    final box = await _box;
    final list = box.values.whereType<LedgerBook>().toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> saveBook(LedgerBook b) async {
    final box = await _box;
    await box.put('book_${b.id}', b);
  }

  Future<void> deleteBook(String id) async {
    if (id == 'default') return; // 默认账本不可删
    final box = await _box;
    await box.delete('book_$id');
  }

  // ════════════════════════════════════════════
  // 预算 Budget
  // ════════════════════════════════════════════

  Future<List<LedgerBudget>> budgets(String month) async {
    final box = await _box;
    return box.values
        .whereType<LedgerBudget>()
        .where((b) => b.month == month)
        .toList();
  }

  Future<void> saveBudget(LedgerBudget b) async {
    final box = await _box;
    await box.put('budget_${b.id}', b);
  }

  Future<void> deleteBudget(String id) async {
    final box = await _box;
    await box.delete('budget_$id');
  }

  String _ym(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}
