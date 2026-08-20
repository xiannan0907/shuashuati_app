import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/timetable_bloc.dart';

class ShareCenterPage extends StatefulWidget {
  const ShareCenterPage({super.key});

  @override
  State<ShareCenterPage> createState() => _ShareCenterPageState();
}

class _ShareCenterPageState extends State<ShareCenterPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('分享中心'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocConsumer<TimetableBloc, TimetableState>(
        listener: (context, state) {
          if (state is TimetableError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          if (state is TimetableLoaded && state.importMessage != null) {
            final msg = state.importMessage!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // 如果是导出成功，且文件路径存在，弹出分享选项
            if (msg.contains('导出') && state.lastExportedFilePath != null) {
              _showShareActionSheet(context, state.lastExportedFilePath!);
            }
          }
        },
        builder: (context, state) {
          if (state is! TimetableLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final courseCount = state.courses.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(context, courseCount, isDark),
                const SizedBox(height: 16),
                _buildFunctionGrid(context, isDark),
                const SizedBox(height: 16),
                _buildFooter(isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, int courseCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month,
              color: Colors.blue.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前课表',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '共 $courseCount 门课程',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (courseCount == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '空课表',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFunctionGrid(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        // 1. 导出 JSON → 导出并分享
        _buildFunctionCard(
          icon: Icons.code,
          color: Colors.blue,
          title: '导出 JSON',
          subtitle: '导出并分享',
          onTap: () => _exportAndShareCourses(context, 'json'),
        ),
        // 2. 导出 Excel → 导出并分享
        _buildFunctionCard(
          icon: Icons.table_chart,
          color: Colors.green,
          title: '导出 Excel',
          subtitle: '导出并分享',
          onTap: () => _exportAndShareCourses(context, 'xlsx'),
        ),
        // 3. 导入课表
        _buildFunctionCard(
          icon: Icons.download,
          color: Colors.purple,
          title: '导入课表',
          subtitle: '从文件导入',
          onTap: () => _importCourses(context),
        ),
        // 4. 分享文件（选择格式）
        _buildFunctionCard(
          icon: Icons.share,
          color: Colors.orange,
          title: '分享文件',
          subtitle: '选择格式分享',
          onTap: () => _shareCourses(context),
        ),
        // 5. 生成二维码（未来扩展）
        _buildFunctionCard(
          icon: Icons.qr_code,
          color: Colors.teal,
          title: '分享二维码',
          subtitle: '生成课表二维码',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔜 二维码分享功能即将上线'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        // 6. 分享码（未来扩展）
        _buildFunctionCard(
          icon: Icons.numbers,
          color: Colors.indigo,
          title: '分享码',
          subtitle: '生成分享码',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔜 分享码功能即将上线'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFunctionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ 导出并分享（替代直接保存）
  // ============================================================

  Future<void> _exportAndShareCourses(BuildContext context, String format) async {
    final state = context.read<TimetableBloc>().state;
    if (state is! TimetableLoaded || state.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前课表没有课程可导出'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileName(format);
      final filePath = '${tempDir.path}/$fileName';

      // 执行导出到临时文件
      if (!context.mounted) return;
      context.read<TimetableBloc>().add(ExportCourses(filePath, format));

      // ✅ 分享对话框会在 BlocListener 中自动弹出

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ✅ 分享文件（选择格式）
  // ============================================================

  Future<void> _shareCourses(BuildContext context) async {
    final state = context.read<TimetableBloc>().state;
    if (state is! TimetableLoaded || state.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前课表没有课程可分享'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择分享格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code, color: Colors.blue),
              title: const Text('JSON 格式'),
              subtitle: const Text('通用数据格式'),
              onTap: () => Navigator.pop(ctx, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel 格式'),
              subtitle: const Text('表格格式，方便查看'),
              onTap: () => Navigator.pop(ctx, 'xlsx'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (format == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileName(format);
      final filePath = '${tempDir.path}/$fileName';

      if (!context.mounted) return;
      context.read<TimetableBloc>().add(ExportCourses(filePath, format));

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ✅ 导入
  // ============================================================

  Future<void> _importCourses(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json', 'xlsx', 'xls'],
      );

      if (file == null) return;

      final path = file.path;

      if (path == null) {
        throw Exception('无法获取文件路径');
      }

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('导入课表'),
          content: Text(
            '确定要导入文件 "${file.name}" 吗？\n\n'
                '⚠️ 导入将替换当前课表中的所有课程！',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('确认导入'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!context.mounted) return;
      context.read<TimetableBloc>().add(ImportCourses(path));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ✅ 分享对话框
  // ============================================================

  void _showShareActionSheet(BuildContext context, String filePath) {
    final fileName = filePath.split('/').last;
    final isExcel = fileName.endsWith('.xlsx');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                isExcel ? Icons.table_chart : Icons.code,
                color: Colors.blue,
              ),
              title: Text('已导出: $fileName'),
              subtitle: const Text('点击「分享」保存或发送文件'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(filePath)],
                              text: '📚 分享课表文件',
                            ),
                          );
                          // ✅ 分享成功提示
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('分享完成，点击系统返回键可回到应用'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } catch (e) {
                          // 用户取消分享，静默忽略
                          debugPrint('分享取消: $e');
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }  // ============================================================
  // 底部说明
  // ============================================================

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '支持 JSON / Excel 格式导入导出，分享功能即将支持更多方式',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 辅助方法
  // ============================================================

  String _getFileName(String format) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final ext = format == 'json' ? 'json' : 'xlsx';
    return '课表_$dateStr.$ext';
  }
}