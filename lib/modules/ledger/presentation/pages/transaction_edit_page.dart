import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/category_model.dart';
import '../../data/repositories/ledger_repository.dart';

/// 记一笔：支出/收入 Tab + 数字键盘 + 分类网格 + 备注
class TransactionEditPage extends StatefulWidget {
  final String ledgerId;
  const TransactionEditPage({super.key, required this.ledgerId});

  @override
  State<TransactionEditPage> createState() => _TransactionEditPageState();
}

class _TransactionEditPageState extends State<TransactionEditPage> {
  String _type = 'expense'; // expense | income
  String _amount = '0'; // 字符串金额（分）
  String _note = '';
  DateTime _date = DateTime.now();
  LedgerCategory? _selectedCategory;
  List<LedgerCategory> _categories = [];
  bool _saving = false;

  final repo = LedgerRepository();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await repo.categories(type: _type);
    setState(() {
      _categories = cats;
      if (_selectedCategory == null && cats.isNotEmpty) {
        _selectedCategory = cats.first;
      } else if (_selectedCategory != null &&
          !cats.any((c) => c.id == _selectedCategory!.id)) {
        _selectedCategory = cats.isNotEmpty ? cats.first : null;
      }
    });
  }

  void _switchType(String type) {
    setState(() {
      _type = type;
      _selectedCategory = null;
    });
    _loadCategories();
  }

  void _pressKey(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'del') {
        _amount = _amount.length <= 1 ? '0' : _amount.substring(0, _amount.length - 1);
      } else if (key == '.') {
        // 以分为单位存储：允许两位小数输入，简化为整数元输入
        return;
      } else {
        if (_amount == '0') {
          _amount = key;
        } else if (_amount.length < 9) {
          _amount += key;
        }
      }
    });
  }

  double get _amountYuan => int.tryParse(_amount)?.toDouble() ?? 0;

  Future<void> _save(BuildContext context) async {
    if (_saving) return;
    if (_amountYuan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入金额'), duration: Duration(seconds: 1)));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择分类'), duration: Duration(seconds: 1)));
      return;
    }
    setState(() => _saving = true);
    await repo.saveTransactionDraft(
      TransactionDraft(
        type: _type,
        amountCents: (_amountYuan * 100).round(),
        categoryId: _selectedCategory!.id,
        accountId: 'cash', // 默认现金账户；账户切换后续增强
        note: _note,
        date: _date,
      ),
      ledgerId: widget.ledgerId,
    );
    if (!mounted) return;
    Navigator.pop(this.context, true);
  }

  static const keys = [
    ['1', '2', '3', 'del'],
    ['4', '5', '6', '+'],
    ['7', '8', '9', '-'],
    ['.', '0', '保存', ''],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = Colors.blue.shade400;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        elevation: 0,
        title: const Text('记一笔'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 类型切换
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _typeTab('expense', '支出', _type == 'expense',
                      Colors.orange.shade700, isDark),
                  const SizedBox(width: 12),
                  _typeTab('income', '收入', _type == 'income',
                      Colors.green.shade600, isDark),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text('备注: ${_note.isEmpty ? "无" : _note}',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                  ).withTap(() async {
                    final c = TextEditingController(text: _note);
                    final note = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('备注'),
                        content: TextField(controller: c, autofocus: true,
                          decoration: const InputDecoration(hintText: '写点什么…')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, c.text),
                              child: const Text('确定')),
                        ],
                      ),
                    );
                    if (note != null) setState(() => _note = note);
                  }),
                ],
              ),
            ),
            // 分类网格
            SizedBox(
              height: 210,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.6),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final sel = _selectedCategory?.id == c.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sel
                            ? catColor.withValues(alpha: 0.15)
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? catColor : Colors.transparent, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(c.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // 金额显示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              child: Row(
                children: [
                  Text('¥',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87)),
                  const Spacer(),
                  Text(_amount,
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ),
            // 数字键盘
            Expanded(child: LayoutBuilder(builder: (context, c) {
              const rows = 4, cols = 4;
              return Column(
                children: List.generate(rows, (r) => Expanded(
                  child: Row(children: List.generate(cols, (col) {
                    final k = keys[r][col];
                    final isSave = k == '保存';
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isSave) { _save(context); return; }
                          if (k.isEmpty) return;
                          _pressKey(k);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSave
                                ? catColor
                                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: isSave
                                ? const Icon(Icons.check, color: Colors.white)
                                : Text(k == 'del' ? '⌫' : k,
                                    style: TextStyle(
                                        fontSize: k == '.' || k == 'del' ? 18 : 22,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87)),
                          ),
                        ),
                      ),
                    );
                  })),
                )),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String type, String label, bool selected, Color color, bool isDark) {
    return GestureDetector(
      onTap: () => _switchType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? color : (isDark ? Colors.grey.shade400 : Colors.grey.shade500))),
      ),
    );
  }
}

extension on Widget {
  Widget withTap(VoidCallback fn) => GestureDetector(onTap: fn, child: this);
}
