import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/models/question_model.dart';
import 'share_qrcode_page.dart';

class ShareCenterPage extends StatefulWidget {
  const ShareCenterPage({super.key});

  @override
  State<ShareCenterPage> createState() => _ShareCenterPageState();
}

class _ShareCenterPageState extends State<ShareCenterPage> {
  List<String> _setNames = [];
  bool _isLoading = true;
  String? _selectedSet;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = QuestionRepository();
      _setNames = await repo.getAllSetNames();
      if (_setNames.isNotEmpty) {
        _selectedSet = _setNames.first;
      }
    } catch (e) {
      print('加载题库列表失败: $e');
    }
    setState(() => _isLoading = false);
  }

  // ==================== 导出JSON ====================
  Future<void> _exportJson() async {
    if (_selectedSet == null) return;
    try {
      final repo = QuestionRepository();
      final jsonData = await repo.exportQuestionsToJson(_selectedSet!);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$_selectedSet.json';
      final file = File(filePath);
      await file.writeAsString(jsonData);

      // ✅ 使用 share_plus 新 API
      final result = await SharePlus.instance.share(
        ShareParams(
          text: '📚 分享题库：$_selectedSet',
          files: [XFile(filePath)],
        ),
      );

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 导出成功！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  // ==================== 导出TXT ====================
  Future<void> _exportTxt() async {
    if (_selectedSet == null) return;
    try {
      final repo = QuestionRepository();
      final txtData = await repo.exportQuestionsToTxt(_selectedSet!);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$_selectedSet.txt';
      final file = File(filePath);
      await file.writeAsString(txtData);

      final result = await SharePlus.instance.share(
        ShareParams(
          text: '📚 分享题库：$_selectedSet',
          files: [XFile(filePath)],
        ),
      );

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 导出成功！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  // ==================== 导入JSON ====================
  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final path = file.path;
      if (path == null) return;

      final content = await File(path).readAsString();
      final jsonData = jsonDecode(content);

      // 验证格式
      if (!jsonData.containsKey('questions') || !jsonData.containsKey('setName')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 无效的题库文件格式')),
        );
        return;
      }

      // 解析题目
      final setName = jsonData['setName'] as String;
      final questionsData = jsonData['questions'] as List;
      final questions = questionsData.map((item) {
        return Question(
          id: item['id'] ??
              'import_${DateTime.now().millisecondsSinceEpoch}_${questionsData.indexOf(item)}',
          content: item['content'] ?? '',
          options: (item['options'] as List?)?.cast<String>() ?? [],
          correctIndex: item['correctIndex'] ?? 0,
          answer: item['answer'],
          source: item['source'] ?? 'imported',
        );
      }).toList();

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 题库为空')),
        );
        return;
      }

      // 保存到本地
      final repo = QuestionRepository();
      final existing = await repo.getQuestions(setName: setName);
      final allQuestions = [...existing, ...questions];
      await repo.saveQuestions(allQuestions, setName: setName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 成功导入 ${questions.length} 道题到 "$setName"'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  // ==================== 生成二维码 ====================
  void _generateQRCode() {
    if (_selectedSet == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareQRCodePage(setName: _selectedSet!),
      ),
    );
  }

  // ==================== 系统分享（纯文本） ====================
  Future<void> _systemShare() async {
    if (_selectedSet == null) return;
    try {
      // ✅ 纯文本分享使用新 API
      await SharePlus.instance.share(
        ShareParams(
          text: '📚 我在刷刷题创建了"$_selectedSet"题库，快来一起学习吧！',
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📤 分享中心'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _setNames.isEmpty
          ? _buildEmptyState(context)
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 选择题库
              const Text(
                '选择题库',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSet,
                    isExpanded: true,
                    items: _setNames.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSet = value),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ====== 导出 ======
              const Text(
                '📤 导出',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildShareCard(
                icon: Icons.qr_code,
                iconColor: Colors.blue,
                title: '二维码',
                subtitle: '生成二维码分享题库',
                onTap: _generateQRCode,
              ),
              _buildShareCard(
                icon: Icons.code,
                iconColor: Colors.deepPurple,
                title: '导出 JSON',
                subtitle: '标准格式，可重新导入刷刷题',
                onTap: _exportJson,
              ),
              _buildShareCard(
                icon: Icons.description,
                iconColor: Colors.orange,
                title: '导出 TXT',
                subtitle: '纯文本格式，方便打印和查看',
                onTap: _exportTxt,
              ),
              _buildShareCard(
                icon: Icons.share,
                iconColor: Colors.green,
                title: '系统分享',
                subtitle: '分享到微信、QQ等应用',
                onTap: _systemShare,
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // ====== 导入 ======
              const Text(
                '📥 导入',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildShareCard(
                icon: Icons.file_upload,
                iconColor: Colors.orange,
                title: '导入 JSON',
                subtitle: '选择刷刷题导出的JSON文件',
                onTap: _importJson,
              ),

              const SizedBox(height: 24),

              // 提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 对方使用刷刷题 App 即可导入题库',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.share, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            '暂无题库可分享',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请先创建或导入题库',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}