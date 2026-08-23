import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/ledger_repository.dart';

// ════════════════════ 事件 ════════════════════

abstract class LedgerEvent {}

class LedgerStarted extends LedgerEvent {
  final String? ledgerId;
  LedgerStarted({this.ledgerId});
}

class LedgerMonthChanged extends LedgerEvent {
  final String yearMonth; // 'yyyy-MM'
  LedgerMonthChanged(this.yearMonth);
}

class LedgerTransactionSaved extends LedgerEvent {
  final LedgerTransaction tx;
  final String? oldAccountId;
  final String? oldToAccountId;
  final int? oldAmountCents;
  final String? oldType;
  LedgerTransactionSaved(this.tx,
      {this.oldAccountId, this.oldToAccountId, this.oldAmountCents, this.oldType});
}

class LedgerTransactionDeleted extends LedgerEvent {
  final LedgerTransaction tx;
  LedgerTransactionDeleted(this.tx);
}

class LedgerAccountSaved extends LedgerEvent {
  final LedgerAccount account;
  final int oldInitialCents;
  LedgerAccountSaved(this.account, {this.oldInitialCents = 0});
}

class LedgerCategorySaved extends LedgerEvent {
  final LedgerCategory category;
  LedgerCategorySaved(this.category);
}

class LedgerCategoryDeleted extends LedgerEvent {
  final String categoryId;
  LedgerCategoryDeleted(this.categoryId);
}

class LedgerBudgetSaved extends LedgerEvent {
  final LedgerBudget budget;
  LedgerBudgetSaved(this.budget);
}

class LedgerBudgetDeleted extends LedgerEvent {
  final String budgetId;
  LedgerBudgetDeleted(this.budgetId);
}

// ════════════════════ 状态 ════════════════════

class LedgerSummaryItem extends Equatable {
  final String categoryId;
  final String name;
  final String icon;
  final int totalCents; // 正数
  final double percent;

  const LedgerSummaryItem({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.totalCents,
    required this.percent,
  });

  @override
  List<Object?> get props => [categoryId, totalCents];
}

class LedgerLoaded extends Equatable {
  final String ledgerId;
  final String month; // 'yyyy-MM'
  final List<LedgerTransaction> transactions; // 当月，按日倒序
  final int incomeCents;
  final int expenseCents;
  final List<LedgerSummaryItem> expenseByCategory;
  final List<LedgerSummaryItem> incomeByCategory;
  final List<LedgerAccount> accounts;
  final Map<String, int> balancesCents; // accountId -> balance
  final List<LedgerBudget> budgets;
  final Map<String, int> budgetSpentCents; // categoryId(''=总) -> spent

  const LedgerLoaded({
    required this.ledgerId,
    required this.month,
    required this.transactions,
    required this.incomeCents,
    required this.expenseCents,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.accounts,
    required this.balancesCents,
    required this.budgets,
    required this.budgetSpentCents,
  });

  @override
  List<Object?> get props => [ledgerId, month, transactions.length];
}

// ════════════════════ Bloc ════════════════════

class LedgerBloc extends Bloc<LedgerEvent, LedgerLoaded?> {
  final LedgerRepository repository;
  String _ledgerId = 'default';

  LedgerBloc({required this.repository}) : super(null) {
    on<LedgerStarted>((e, emit) async {
      if (e.ledgerId != null) _ledgerId = e.ledgerId!;
      await _load(emit.call);
    });
    on<LedgerMonthChanged>((e, emit) async => await _reload(e.yearMonth, emit.call));
    on<LedgerTransactionSaved>((e, emit) async {
      // 回滚旧金额对账户的影响
      if (e.oldType == 'expense' && e.oldAccountId != null) {
        await _adjustInitial(e.oldAccountId!, e.oldAmountCents ?? 0);
      } else if (e.oldType == 'income' && e.oldAccountId != null) {
        await _adjustInitial(e.oldAccountId!, -(e.oldAmountCents ?? 0));
      }
      await repository.saveTransaction(e.tx);
      await _reload(_currentMonthFromTx(e.tx), emit.call);
    });
    on<LedgerTransactionDeleted>((e, emit) async {
      await repository.deleteTransaction(e.tx.id);
      await _adjustForDelete(e.tx);
      await _reload(_ymOf(e.tx.date), emit.call);
    });
    on<LedgerAccountSaved>((e, emit) async {
      // 初始余额变化直接反映在余额上；这里仅保存账户
      await repository.saveAccount(e.account);
      await _load(emit.call);
    });
    on<LedgerCategorySaved>((e, emit) async {
      await repository.saveCategory(e.category);
      await _load(emit.call);
    });
    on<LedgerCategoryDeleted>((e, emit) async {
      await repository.deleteCategory(e.categoryId);
      await _load(emit.call);
    });
    on<LedgerBudgetSaved>((e, emit) async {
      await repository.saveBudget(e.budget);
      await _load(emit.call);
    });
    on<LedgerBudgetDeleted>((e, emit) async {
      await repository.deleteBudget(e.budgetId);
      await _load(emit.call);
    });
  }

  String _ymOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  String _currentMonthFromTx(LedgerTransaction tx) => _ymOf(tx.date);

  Future<void> _adjustInitial(String accountId, int deltaCents) async {
    final acc = await repository.accountById(accountId);
    if (acc != null && deltaCents != 0) {
      acc.initialBalanceCents += deltaCents;
      await repository.saveAccount(acc);
    }
  }

  Future<void> _adjustForDelete(LedgerTransaction t) async {
    if (t.type == 'expense') {
      await _adjustInitial(t.accountId, t.amountCents); // 加回
    } else if (t.type == 'income') {
      await _adjustInitial(t.accountId, -t.amountCents); // 扣回
    }
  }

  Future<void> _load(void Function(LedgerLoaded?) emit) async {
    final now = DateTime.now();
    final ym =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await _reload(ym, emit);
  }

  Future<void> _reload(String yearMonth, void Function(LedgerLoaded?) emit) async {
    final txs = await repository.monthTransactions(yearMonth, ledgerId: _ledgerId);

    int income = 0, expense = 0;
    final expByCat = <String, int>{};
    final incByCat = <String, int>{};
    for (final t in txs) {
      if (t.type == 'expense') {
        expense += t.amountCents;
        expByCat[t.categoryId ?? ''] =
            (expByCat[t.categoryId ?? ''] ?? 0) + t.amountCents;
      } else if (t.type == 'income') {
        income += t.amountCents;
        incByCat[t.categoryId ?? ''] =
            (incByCat[t.categoryId ?? ''] ?? 0) + t.amountCents;
      }
    }

    List<LedgerSummaryItem> buildSummary(
        Map<String, int> map, List<LedgerCategory> cats) {
      final catMap = {for (final c in cats) c.id: c};
      final items = map.entries.map((e) {
        final c = catMap[e.key];
        return LedgerSummaryItem(
          categoryId: e.key,
          name: c?.name ?? '未知',
          icon: c?.icon ?? '🏷️',
          totalCents: e.value,
          percent: expense > 0 ? e.value / map.values.fold(0, (a, b) => a + b) : 0,
        );
      }).toList();
      items.sort((a, b) => b.totalCents.compareTo(a.totalCents));
      return items;
    }

    final allCats = await repository.categories();
    final expSummary =
        buildSummary(expByCat, allCats.where((c) => c.type == 'expense').toList());
    final incSummary =
        buildSummary(incByCat, allCats.where((c) => c.type == 'income').toList());

    // 归一化百分比
    double pct(int v, int total) => total > 0 ? v / total : 0;
    final expTotal = expByCat.values.fold(0, (a, b) => a + b);
    final normalizedExp = expSummary
        .map((s) => LedgerSummaryItem(
              categoryId: s.categoryId,
              name: s.name,
              icon: s.icon,
              totalCents: s.totalCents,
              percent: pct(s.totalCents, expTotal),
            ))
        .toList();

    final accounts = await repository.accounts();
    final balances = <String, int>{};
    for (final a in accounts) {
      balances[a.id] = await repository.accountBalanceCents(a.id);
    }

    final budgets = await repository.budgets(yearMonth);
    final spent = <String, int>{'': expense};
    for (final b in budgets) {
      if (b.categoryId != null) {
        spent[b.categoryId!] = expByCat[b.categoryId] ?? 0;
      }
    }

    emit(LedgerLoaded(
      ledgerId: _ledgerId,
      month: yearMonth,
      transactions: txs,
      incomeCents: income,
      expenseCents: expense,
      expenseByCategory: normalizedExp,
      incomeByCategory: incSummary,
      accounts: accounts,
      balancesCents: balances,
      budgets: budgets,
      budgetSpentCents: spent,
    ));
  }
}
