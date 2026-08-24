import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/transaction_model.dart';
import '../../data/repositories/ledger_repository.dart';
import '../bloc/ledger_bloc.dart';
import 'account_manage_page.dart';
import 'budget_page.dart';
import 'category_manage_page.dart';
import 'ledger_stats_page.dart';
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

  /// 导出本月流水 CSV 并唤起系统分享
  Future<void> _exportCsv() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('正在生成 CSV...'), duration: Duration(seconds: 1)));
      final csv = await LedgerRepository().exportMonthCsv(_month);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tiyu_ledger_$_month.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '题屿记账 $_month 流水',
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('导出失败: $e'), backgroundColor: Colors.red));
    }
  }

  void _shiftMonth(int delta) {    final parts = _month.split('-');
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
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => _shiftMonth(-1),
            ),
            Text(_month,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: '收支统计',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<LedgerBloc>(),
                  child: const LedgerStatsPage(),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多',
            onSelected: (value) async {
              if (value == 'export') {
                await _exportCsv();
                return;
              }
              final bloc = context.read<LedgerBloc>();
              final s = bloc.state;
              late final Widget page;
              switch (value) {
                case 'accounts':
                  page = const AccountManagePage();
                case 'categories':
                  page = const CategoryManagePage();
                default: // budget
                  page = BudgetPage(
                    month: _month,
                    monthExpenseCents:
                        (s is LedgerLoaded) ? s.expenseCents : 0,
                  );
              }
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
              // 管理页返回后刷新汇总与流水
              if (context.mounted) bloc.add(LedgerStarted());
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                height: 44,
                child: Row(children: [
                  Icon(Icons.ios_share, size: 20),
                  SizedBox(width: 10),
                  Text('导出本月流水 CSV'),
                ]),
              ),
              PopupMenuItem(
                value: 'accounts',
                height: 44,
                child: Row(children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('账户管理'),
                ]),
              ),
              PopupMenuItem(
                value: 'categories',
                height: 44,
                child: Row(children: [
                  Icon(Icons.category_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('分类管理'),
                ]),
              ),
              PopupMenuItem(
                value: 'budget',
                height: 44,
                child: Row(children: [
                  Icon(Icons.savings_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('预算'),
                ]),
              ),
            ],
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
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
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
          final iconMap = {
            for (final s in [...state.expenseByCategory, ...state.incomeByCategory])
              s.categoryId: s.icon,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              _summaryCard(isDark, income, expense),
              const SizedBox(height: 14),
              if (byCat.isNotEmpty) ...[
                _categoryChart(isDark, byCat, expense),
                const SizedBox(height: 14),
              ],
              _txList(isDark, txs, iconMap),
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
                      child: Text(
                          s.name.contains(' ')
                              ? s.name.substring(s.name.indexOf(' ') + 1)
                              : s.name,
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
  Widget _txList(bool isDark, List<LedgerTransaction> txs,
      Map<String, String> iconMap) {
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
