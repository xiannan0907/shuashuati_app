import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../bloc/quiz_bloc.dart';

class ExampleImportPage extends StatefulWidget {
  const ExampleImportPage({super.key});

  @override
  State<ExampleImportPage> createState() => _ExampleImportPageState();
}

class _ExampleImportPageState extends State<ExampleImportPage> {
  bool _isImporting = false;

  // ---------- 示例题库数据 ----------
  final List<Map<String, dynamic>> _exampleQuestions = [
    // 选择题
    {
      'content': 'Flutter中用于构建UI的组件是？',
      'options': ['Widget', 'View', 'Controller', 'Component'],
      'correctIndex': 0,
      'source': '示例-选择题',
    },
    {
      'content': 'Dart语言中，用于声明不可变变量的关键字是？',
      'options': ['var', 'dynamic', 'final', 'const'],
      'correctIndex': 2,
      'source': '示例-选择题',
    },
    {
      'content': 'Flutter中的热重载快捷键是？',
      'options': ['Ctrl+R', 'Ctrl+S', 'Ctrl+Shift+R', 'r'],
      'correctIndex': 3,
      'source': '示例-选择题',
    },
    // 判断题
    {
      'content': 'Flutter使用Dart语言进行开发。',
      'options': ['正确', '错误'],
      'correctIndex': 0,
      'source': '示例-判断题',
    },
    {
      'content': 'StatelessWidget是有状态的组件。',
      'options': ['正确', '错误'],
      'correctIndex': 1,
      'source': '示例-判断题',
    },
    {
      'content': 'Flutter的UI是自绘制的，不依赖平台原生控件。',
      'options': ['正确', '错误'],
      'correctIndex': 0,
      'source': '示例-判断题',
    },
    // 填空题
    {
      'content': 'Flutter中，用于创建可变状态组件的基类是______。',
      'options': ['（填空题）'],
      'correctIndex': 0,
      'source': '示例-填空题',
      'answer': 'StatefulWidget',
    },
    {
      'content': '在Flutter中，______是应用程序的根组件。',
      'options': ['（填空题）'],
      'correctIndex': 0,
      'source': '示例-填空题',
      'answer': 'MaterialApp',
    },
    {
      'content': 'Flutter的布局组件中，______用于垂直排列子组件。',
      'options': ['（填空题）'],
      'correctIndex': 0,
      'source': '示例-填空题',
      'answer': 'Column',
    },
  ];

  Future<void> _importExample() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final repository = QuestionRepository();
      String? currentSet = await repository.getCurrentSetName();
      if (currentSet == null || currentSet.isEmpty) {
        currentSet = '默认题库';
        await repository.setCurrentSetName(currentSet);
      }

      final existingQuestions = await repository.getQuestions(setName: currentSet);
      final hasExample = existingQuestions.any((q) =>
      q.source == '示例-选择题' ||
          q.source == '示例-判断题' ||
          q.source == '示例-填空题');

      if (hasExample) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('当前题库已包含示例题目，无需重复导入'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final List<Question> questions = [];
      for (var data in _exampleQuestions) {
        questions.add(
          Question(
            id: 'example_${DateTime.now().millisecondsSinceEpoch}_${questions.length}',
            content: data['content'],
            options: List<String>.from(data['options']),
            correctIndex: data['correctIndex'],
            source: data['source'] ?? '示例导入',
            answer: data['answer'],
            isAnswered: false,
            selectedOption: null,
            isWrong: false,
          ),
        );
      }

      final allQuestions = [...existingQuestions, ...questions];
      await repository.saveQuestions(allQuestions, setName: currentSet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 成功导入 ${questions.length} 道示例题目！'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // ✅ 修复：只 pop 返回，刷新由 QuizSetListPage 的 then 回调处理
      if (mounted) {
        // 通知 BLoC 刷新列表（在 pop 之前）
        context.read<QuizBloc>().add(LoadQuizSetList());
        // 延迟一点点 pop，确保 BLoC 事件已处理
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📥 导入示例题库'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚀 快速开始',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '导入示例题库，立即体验刷刷题的全部功能！',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importExample,
                      icon: _isImporting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      )
                          : const Icon(Icons.download),
                      label: Text(_isImporting ? '导入中...' : '导入示例题库 (9题)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 示例预览
            const Text(
              '📖 示例题目预览',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 选择题示例
            _buildExampleCard(
              icon: Icons.radio_button_checked,
              iconColor: Colors.green,
              title: '选择题 (3题)',
              example: 'Flutter中用于构建UI的组件是？\nA. Widget  B. View  C. Controller  D. Component',
              answer: '正确答案：A',
            ),

            // 判断题示例
            _buildExampleCard(
              icon: Icons.check_box,
              iconColor: Colors.purple,
              title: '判断题 (3题)',
              example: 'Flutter使用Dart语言进行开发。\n选项：正确 / 错误',
              answer: '正确答案：正确',
            ),

            // 填空题示例
            _buildExampleCard(
              icon: Icons.edit_note,
              iconColor: Colors.orange,
              title: '填空题 (3题)',
              example: 'Flutter中，用于创建可变状态组件的基类是______。',
              answer: '正确答案：StatefulWidget',
            ),

            const SizedBox(height: 16),

            // 底部提示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '导入示例题目不会覆盖您已有的题目，只会在当前题库中追加。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String example,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            example,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}