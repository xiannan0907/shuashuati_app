import 'package:flutter/material.dart';

import '../../data/models/account_model.dart';
import '../../data/repositories/ledger_repository.dart';

/// 账户管理：列表 + 余额 + 增改删
class AccountManagePage extends StatefulWidget {
  const AccountManagePage({super.key});

  @override
  State<AccountManagePage> createState() => _AccountManagePageState();
}

class _AccountManagePageState extends State<AccountManagePage> {
  final repo = LedgerRepository();
  List<LedgerAccount> _accounts = [];
  Map<String, int> _balances = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await repo.accounts();
    final balances = <String, int>{};
    for (final a in accounts) {
      balances[a.id] = await repo.accountBalanceCents(a.id);
    }
    setState(() {
      _accounts = accounts;
      _balances = balances;
      _loading = false;
    });
  }

  Future<void> _editDialog([LedgerAccount? account]) async {
    final nameCtrl = TextEditingController(text: account?.name ?? '');
    final balanceCtrl = TextEditingController(
        text: account != null
            ? (account.initialBalanceCents / 100).toStringAsFixed(2)
            : '0.00');
    final icons = ['💵', '💬', '🅰️', '💳', '🏦', '🐷'];
    var selectedIcon = account?.icon ?? '💵';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(account == null ? '新建账户' : '编辑账户'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '账户名称'),
              ),
              TextField(
                controller: balanceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '初始余额（元）'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: icons
                    .map((i) => GestureDetector(
                          onTap: () => setDialog(() => selectedIcon = i),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: selectedIcon == i
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: selectedIcon == i
                                      ? Colors.blue.shade400
                                      : Colors.transparent,
                                  width: 2),
                            ),
                            child: Center(child: Text(i, style: const TextStyle(fontSize: 22))),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
          ],
        ),
      ),
    );

    if (ok != true || nameCtrl.text.trim().isEmpty) return;

    final cents =
        ((double.tryParse(balanceCtrl.text) ?? 0) * 100).round();
    await repo.saveAccount(LedgerAccount(
      id: account?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameCtrl.text.trim(),
      icon: selectedIcon,
      initialBalanceCents: cents,
      sortIndex: account?.sortIndex ?? _accounts.length,
    ));
    await _load();
  }

  Future<void> _deleteAccount(LedgerAccount a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账户'),
        content: Text('确定删除「${a.name}」吗？已有流水不会删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await repo.deleteAccount(a.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF7F8FA),
      appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        title: const Text('账户管理'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editDialog(),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, i) {
                final a = _accounts[i];
                final balance = _balances[a.id] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Text(a.icon, style: const TextStyle(fontSize: 26)),
                    title: Text(a.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade800)),
                    subtitle: Text('余额 ¥${(balance / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: balance >= 0
                                ? Colors.green.shade600
                                : Colors.red.shade400)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editDialog(a)),
                        IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 20, color: Colors.red.shade300),
                            onPressed: () => _deleteAccount(a)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
