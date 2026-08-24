import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/error_log_service.dart';

/// 错误日志查看页：查看 / 导出分享 / 清除
class ErrorLogPage extends StatefulWidget {
  const ErrorLogPage({super.key});

  @override
  State<ErrorLogPage> createState() => _ErrorLogPageState();
}

class _ErrorLogPageState extends State<ErrorLogPage> {
  String _content = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await ErrorLogService.readAll();
    if (!mounted) return;
    setState(() {
      _content = content;
      _loading = false;
    });
  }

  Future<void> _export() async {
    final path = await ErrorLogService.path();
    if (!mounted) return;
    if (path == null || _content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('暂无日志可导出'), duration: Duration(seconds: 1)));
      return;
    }
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path)],
      text: '题屿错误日志',
    ));
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除日志'),
        content: const Text('确定清空全部错误日志？此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('清除')),
        ],
      ),
    );
    if (ok == true) {
      await ErrorLogService.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries =
        _content.split('─').where((e) => e.trim().startsWith('[20')).length;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('📋 错误日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '导出',
            onPressed: _export,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _content.trim().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 56,
                          color: isDark
                              ? Colors.green.shade700
                              : Colors.green.shade400),
                      const SizedBox(height: 12),
                      Text('运行良好，暂无错误记录',
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          Text('约 $entries 条记录 · 自动滚动保留最近一段',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _content,
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
