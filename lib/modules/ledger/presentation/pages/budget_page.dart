import 'package:flutter/material.dart';

import '../../data/models/budget_model.dart';
import '../../data/repositories/ledger_repository.dart';

/// 月度预算设置：总预算 + 分类预算，含本月消耗进度
class BudgetPage extends StatefulWidget {
  final String month; // 'yyyy-MM'
  final int monthExpenseCents; // 本月已花
  final Map<String, int> categoryExpenseCents; // 分类已花
  const BudgetPage({
    super.key,
    required this.month,
    required this.monthExpenseCents,
    this.categoryExpenseCents = const {},
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final repo = LedgerRepository();
  List<LedgerBudget> _budgets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final budgets = await repo.budgets(widget.month);
    setState(() => _budgets = budgets);
    setState(() => _loading = false);
  }

  Future<void> _editDialog([LedgerBudget? existing]) async {
    final amountCtrl = TextEditingController(
        text: existing != null
            ? (existing.amountCents / 100).toStringAsFixed(2)
            : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null
            ? '设置${existing == null && _budgets.any((b) => b.categoryId == null) ? '' : ''}预算'
            : '编辑预算'),
        content: TextField(
          controller: amountCtrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: '预算金额（元）', prefixText: '¥ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    final cents = ((double.tryParse(amountCtrl.text) ?? 0) * 100).round();
    if (ok != true || cents <= 0) return;

    if (existing != null) {
      existing.amountCents = cents;
      await repo.saveBudget(existing);
    } else {
      await repo.saveBudget(LedgerBudget(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        month: widget.month,
        amountCents: cents,
        categoryId: null, // MVP：仅总预算；分类预算后续增强
      ));
    }
    await _load();
  }

  Future<void> _deleteBudget(LedgerBudget b) async {
    await repo.deleteBudget(b.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _budgets
        .where((b) => b.categoryId == null)
        .fold<int>(0, (sum, b) => sum + b.amountCents);
    final spent = widget.monthExpenseCents;
    final percent = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final over = total > 0 && spent > total;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF7F8FA),
      appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        title: Text('预算 · ${widget.month}'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('设预算'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: over
                        ? Colors.red.shade50
                        : (isDark ? Colors.grey.shade800 : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: over
                            ? Colors.red.shade200
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
                  ),
                  child: total > 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('本月总预算',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600)),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _editDialog(_budgets
                                          .firstWhere((b) => b.categoryId == null)),
                                      child: Icon(Icons.edit,
                                          size: 16,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade500)),
                                    if (_budgets.any((b) => b.categoryId == null))
                                      GestureDetector(
                                        onTap: () => _deleteBudget(_budgets
                                            .firstWhere((b) => b.categoryId == null)),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Icon(Icons.delete_outline,
                                              size: 16,
                                              color: Colors.red.shade300),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('¥ ${(spent / 100).toStringAsFixed(2)} / ¥ ${(total / 100).toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: over
                                        ? Colors.red.shade600
                                        : (isDark
                                            ? Colors.white
                                            : Colors.grey.shade800))),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 10,
                                backgroundColor: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200,
                                color: over
                                    ? Colors.red.shade400
                                    : Colors.green.shade400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                over
                                    ? '⚠️ 已超支 ¥${((spent - total) / 100).toStringAsFixed(2)}'
                                    : '还剩 ¥${((total - spent) / 100).toStringAsFixed(2)}（${(percent * 100).toStringAsFixed(0)}%）',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: over
                                        ? Colors.red.shade600
                                        : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade500))),
                          ],
                        )
                      : Column(
                          children: [
                            Text('还没有设置 ${widget.month} 的预算',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('点右下角「设预算」开始控制开销',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400)),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
