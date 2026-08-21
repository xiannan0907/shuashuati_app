import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/backup_service.dart';
import '../../core/services/storage_service.dart';
import '../../modules/timetable/presentation/pages/timetable_settings_page.dart';

class StorageManagementPage extends StatefulWidget {
  const StorageManagementPage({super.key});

  @override
  State<StorageManagementPage> createState() => _StorageManagementPageState();
}

class _StorageManagementPageState extends State<StorageManagementPage> {
  late Future<StorageInfo> _storageFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _storageFuture = StorageService.getStorageInfo();
    });
  }

  // ============================================================
  // ✅ 数据备份 / 恢复
  // ============================================================

  Future<void> _exportBackup() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在打包备份...'), duration: Duration(seconds: 1)),
      );
      final (path, size) = await BackupService.exportBackup();
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(path)],
        text: '刷刷题数据备份（${(size / 1024).toStringAsFixed(0)} KB）——请妥善保存',
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result.isEmpty) return;
      final path = result.first.path;
      if (path == null) return;

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('恢复备份'),
          content: const Text(
            '将用备份文件覆盖当前所有数据（题库/错题/闯塔/课表/游戏存档等），'
            '此操作不可撤销。\n\n恢复完成后应用会关闭，请重新打开。',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确认恢复'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await BackupService.restoreBackup(path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('✅ 恢复完成'),
          content: const Text('数据已恢复，应用即将关闭。\n请重新打开刷刷题查看恢复的数据。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      // 关闭应用让 Hive 重新加载数据文件
      await SystemNavigator.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // 清理缓存
  // ============================================================

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text(
            '这将删除所有临时文件（包括导入的Excel、导出的文件等），'
                '但不会删除任何课程数据或进度。\n\n确定继续吗？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清理'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await StorageService.clearCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 缓存已清理')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清理失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // ✅ 清理其他数据
  // ============================================================

  Future<void> _clearOtherData() async {
    // 先获取当前数据
    final info = await _storageFuture;
    if (!mounted) return;
    if (info.otherCleanableSize == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可清理的其他数据')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清理其他数据'),
        content: Text(
            '这将删除所有非关键的其他数据文件（如导出的Excel/JSON、日志文件等），'
                '但不会删除课表、刷题进度或用户信息。\n\n'
                '可清理大小：${info.otherCleanableSizeStr}\n\n'
                '确定继续吗？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清理'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await StorageService.clearOtherData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 其他数据已清理')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清理失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('存储管理'),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: FutureBuilder<StorageInfo>(
        future: _storageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('加载失败: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final info = snapshot.data!;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // ✅ 数据备份 / 恢复
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_sync, size: 18,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade600),
                          const SizedBox(width: 6),
                          Text('数据备份',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.grey.shade800)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('备份题库、错题、闯塔、课表与游戏存档；恢复将覆盖当前数据并需重启应用。',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _exportBackup,
                              icon: const Icon(Icons.ios_share, size: 16),
                              label: const Text('备份数据'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _importBackup,
                              icon: const Icon(Icons.restore, size: 16),
                              label: const Text('恢复备份'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============================================================
                // 总览卡片
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '总占用空间',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.totalSizeStr,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ============================================================
                // 数据详情
                // ============================================================
                _buildSection(
                  context,
                  title: '数据详情',
                  children: [
                    // 课表数据
                    _buildStorageItem(
                      icon: Icons.calendar_month,
                      label: '课表数据',
                      size: info.timetableSizeStr,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TimetableSettingsPage(),
                          ),
                        ).then((_) => _loadData());
                      },
                    ),
                    // 刷题数据
                    _buildStorageItem(
                      icon: Icons.quiz,
                      label: '刷题数据',
                      size: info.quizSizeStr,
                      color: Colors.orange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('刷题模块设置功能开发中，请在刷题模块内清理'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    // ✅ 其他数据（带清理按钮）
                    _buildStorageItem(
                      icon: Icons.folder,
                      label: '其他数据',
                      size: info.otherSizeStr,
                      color: Colors.grey,
                      onTap: null,
                      showCleanButton: info.otherCleanableSize > 0,
                      onCleanTap: _clearOtherData,
                      cleanLabel: '清理 (${info.otherCleanableSizeStr})',
                    ),
                    // 缓存文件
                    _buildStorageItem(
                      icon: Icons.cached,
                      label: '缓存文件',
                      size: info.cacheSizeStr,
                      color: Colors.green,
                      showCleanButton: info.cacheSize > 0,
                      onCleanTap: _clearCache,
                      cleanLabel: info.cacheSize > 0 ? '清理' : null,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ============================================================
                // 说明
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '点击“课表数据”可进入课表设置清理课程；'
                              '“其他数据”可安全清理非关键文件（导出文件、日志等），'
                              '不影响您的数据和进度。',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // UI 辅助组件
  // ============================================================

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStorageItem({
    required IconData icon,
    required String label,
    required String size,
    required Color color,
    VoidCallback? onTap,
    bool showCleanButton = false,
    VoidCallback? onCleanTap,
    String? cleanLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Text(
              size,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            if (showCleanButton) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCleanTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    cleanLabel ?? '清理',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
            if (onTap != null && !showCleanButton)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}