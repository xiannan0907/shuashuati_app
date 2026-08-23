import 'package:flutter/material.dart';

import '../../data/models/category_model.dart';
import '../../data/repositories/ledger_repository.dart';

/// 分类管理：支出/收入 Tab、新增自定义分类、删除自定义分类
class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage>
    with SingleTickerProviderStateMixin {
  final repo = LedgerRepository();
  late final TabController _tab =
      TabController(length: 2, vsync: this)..addListener(_onTab);

  String _type = 'expense';
  List<LedgerCategory> _categories = [];
  bool _loading = true;

  void _onTab() {
    if (_tab.indexIsChanging) return;
    setState(() => _type = _tab.index == 0 ? 'expense' : 'income');
    _load();
  }

  Future<void> _load() async {
    final cats = await repo.categories(type: _type);
    setState(() => _categories = cats);
    setState(() => _loading = false);
  }

  static const _emojiChoices = [
    '🍜', '🚌', '📚', '🎓', '🖨️', '📝', '🛒', '🎮', '🏠', '🏷️',
    '💰', '🎯', '🧧', '📈', '☕', '💊', '👕', '✈️', '🐱', '🎁',
  ];

  Future<void> _addDialog() async {
    var selectedEmoji = _emojiChoices.first;
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(_type == 'expense' ? '新增支出分类' : '新增收入分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _emojiChoices
                    .map((e) => GestureDetector(
                          onTap: () => setDialog(() => selectedEmoji = e),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedEmoji == e
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: selectedEmoji == e
                                      ? Colors.blue.shade400
                                      : Colors.transparent,
                                  width: 2),
                            ),
                            child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: '分类名称'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('添加')),
          ],
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await repo.saveCategory(LedgerCategory(
        id: 'cat_custom_${DateTime.now().microsecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        type: _type,
        icon: selectedEmoji,
        isCustom: true,
        sortIndex: 999,
      ));
      await _load();
    }
  }

  Future<void> _deleteCategory(LedgerCategory c) async {
    if (!c.isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预置分类不可删除'), duration: Duration(seconds: 1)),
      );
      return;
    }
    await repo.deleteCategory(c.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF7F8FA),
        appBar: AppBar(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          title: const Text('分类管理'),
          elevation: 0,
          bottom: TabBar(
            controller: _tab,
            labelColor: Colors.white,
            unselectedLabelColor:
                isDark ? Colors.grey.shade500 : Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [Tab(text: '支出'), Tab(text: '收入')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addDialog,
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add),
          label: const Text('新分类'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
                      title: Text(c.name,
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.grey.shade800)),
                      trailing: c.isCustom
                          ? IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red.shade300),
                              onPressed: () => _deleteCategory(c),
                            )
                          : const SizedBox(width: 8),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
