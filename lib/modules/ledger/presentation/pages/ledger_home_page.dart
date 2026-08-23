import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../bloc/ledger_bloc.dart';
import 'account_manage_page.dart';
import 'budget_page.dart';
import 'category_manage_page.dart';
import 'transaction_edit_page.dart';

/// 记账主页：月份切换 + 收支汇总 + 分类占比 + 流水列表
class LedgerHomePage extends StatefulWidget {
  const LedgerHomePage({super.key});

  @override
  State<LedgerHomePage> createState() => _LedgerHomePageState();
}

class _LedgerHomePageState extends State<LedgerHomePage> {
  String _month = _ym(DateTime.now());

  static String _ym(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  void _shiftMonth(int delta) {
    final parts = _month.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]) + delta;
    while (m > 12) { m -= 12; y++; }
    while (m < 1) { m += 12; y--; }
    setState(() => _month = '$y-${m.toString().padLeft(2, '0')}');
    context.read<LedgerBloc>().add(LedgerMonthChanged(_month));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF7F8FA),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shiftMonth(-1),
            ),
            Text(_month,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade800)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: '账户管理',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountManagePage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: '分类管理',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryManagePage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.savings_outlined),
            tooltip: '预算',
            onPressed: () {
              final s = context.read<LedgerBloc>().state;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BudgetPage(
                    month: _month,
                    monthExpenseCents:
                        (s is LedgerLoaded) ? s.expenseCents : 0,
                  ),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<LedgerBloc>().add(LedgerStarted());
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionEditPage(ledgerId: 'default')),
          );
          if (context.mounted) {
            context.read<LedgerBloc>().add(LedgerStarted());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: BlocBuilder<LedgerBloc, LedgerLoaded?>(
        builder: (context, state) {
          if (state == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final income = state.incomeCents;
          final expense = state.expenseCents;
          final txs = state.transactions;
          final byCat = state.expenseByCategory;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              _summaryCard(isDark, income, expense),
              const SizedBox(height: 14),
              if (byCat.isNotEmpty) ...[
                _categoryChart(isDark, byCat, expense),
                const SizedBox(height: 14),
              ],
              _txList(isDark, txs),
            ],
          );
        },
      ),
    );
  }

  // ── 收支汇总卡 ──
  Widget _summaryCard(bool isDark, int income, int expense) {
    String yuan(int cents) => (cents / 100).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.shade900, Colors.indigo.shade900]
              : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本月支出',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 4),
          Text('¥ ${yuan(expense)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: Text('收入 ¥${yuan(income)}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13))),
              Expanded(
                  child: Text('结余 ¥${yuan(income - expense)}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13))),
            ],
          ),
        ],
      ),
    );
  }

  // ── 分类占比（横向条形）──
  Widget _categoryChart(bool isDark, List items, int totalExpense) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('支出分类',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 12),
          ...items.take(6).map((s) {
            final percent = (s.percent * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(s.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  SizedBox(width: 72,
                      child: Text(s.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.percent.toDouble(),
                        minHeight: 8,
                        backgroundColor:
                            isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ),
                  SizedBox(width: 64,
                      child: Text('$percent%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 流水列表（按日分组）──
  Widget _txList(bool isDark, List<LedgerTransaction> txs) {
    if (txs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Text('本月暂无记录，点右下角「记一笔」开始',
            style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
      );
    }

    // 按日分组
    final df = DateFormat('MM-dd');
    final groups = <String, List<LedgerTransaction>>{};
    for (final t in txs) {
      groups.putIfAbsent(df.format(t.date), () => []).add(t);
    }

    String amountStr(int cents, bool isIncome) =>
        '${isIncome ? '+' : '-'}¥${(cents / 100).abs().toStringAsFixed(2)}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: groups.entries.expand((g) {
          final dayTotal = g.value.fold<int>(0, (sum, t) {
            if (t.type == 'expense') return sum - t.amountCents;
            if (t.type == 'income') return sum + t.amountCents;
            return sum;
          });
          return [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(g.key,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                  Text('${dayTotal >= 0 ? '' : ''}${(dayTotal / 100).toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: dayTotal >= 0
                              ? Colors.green.shade600
                              : Colors.orange.shade700)),
                ],
              ),
            ),
            ...g.value.map((t) => ListTile(
                  dense: true,
                  leading: Text(t.type == 'income' ? '💰' : '🏷️',
                      style: const TextStyle(fontSize: 20)),
                  title: Text(t.note.isEmpty ? (t.type == 'income' ? '收入' : '支出') : t.note,
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.grey.shade800)),
                  subtitle: Text(DateFormat('HH:mm').format(t.date),
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
                  trailing: Text(
                    amountStr(t.amountCents, t.type == 'income'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.type == 'income'
                          ? Colors.green.shade600
                          : (isDark ? Colors.orange.shade300 : Colors.orange.shade800),
                    ),
                  ),
                )),
            const Divider(height: 1),
          ];
        }).toList(),
      ),
    );
  }
}
