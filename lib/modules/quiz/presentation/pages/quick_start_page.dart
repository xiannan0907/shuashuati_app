import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/quiz_bloc.dart';
import 'quiz_page.dart';
import '../../data/repositories/question_repository.dart';

class QuickStartPage extends StatefulWidget {
  const QuickStartPage({super.key});

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  String? _currentSetName;
  int _totalQuestions = 0;
  int _answeredQuestions = 0;
  List<String> _setNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = QuestionRepository();
      _currentSetName = await repo.getCurrentSetName() ?? '默认题库';
      _setNames = await repo.getAllSetNames();

      final questions = await repo.getQuestions(setName: _currentSetName);
      _totalQuestions = questions.length;
      _answeredQuestions = questions.where((q) => q.isAnsweredValue).length;
    } catch (e) {
      debugPrint('加载快速开始数据失败: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = _totalQuestions > 0
        ? (_answeredQuestions / _totalQuestions * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✏️ 继续刷题',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '从上次中断的地方继续',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // 当前题库卡片
          InkWell(
            onTap: () {
              final quizBloc = context.read<QuizBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: quizBloc,
                    child: QuizPage(setName: _currentSetName!),
                  ),
                ),
              ).then((_) => _loadData());
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentSetName ?? '默认题库',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '进度 $_answeredQuestions/$_totalQuestions 题',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _totalQuestions > 0 ? _answeredQuestions / _totalQuestions : 0,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '📖 继续刷题',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 快速切换题库
          if (_setNames.length > 1) ...[
            const Text(
              '⚡ 快速切换题库',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _setNames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final name = _setNames[index];
                  final isCurrent = name == _currentSetName;
                  return FilterChip(
                    label: Text(name),
                    selected: isCurrent,
                    onSelected: (_) {
                      setState(() {
                        _currentSetName = name;
                      });
                      _loadData();
                    },
                    selectedColor: Colors.blue.shade100,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isCurrent ? Colors.blue.shade700 : Colors.grey.shade700,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ),
          ],

          const Spacer(),

          // 今日统计
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$_answeredQuestions',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '已答题',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      '${_totalQuestions - _answeredQuestions}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text(
                      '待答题',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: progress >= 60 ? Colors.green : Colors.orange,
                      ),
                    ),
                    const Text(
                      '完成率',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}