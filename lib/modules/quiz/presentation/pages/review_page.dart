import 'package:flutter/material.dart';

import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../widgets/question_card.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Question> _reviewQuestions = [];
  List<Map<String, dynamic>> _reviewStats = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isStudyMode = false;

  final Map<String, int> _tempSelectedOptions = {};
  final Map<String, bool> _tempIsAnswered = {};
  final Map<String, String> _fillAnswers = {};

  int _correctCount = 0;
  int _wrongCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviewQuestions();
  }

  Future<void> _loadReviewQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = QuestionRepository();
      await repository.migrateReviewFields();

      final questions = await repository.getReviewQuestions(limit: 30);

      final stats = <Map<String, dynamic>>[];
      for (var q in questions) {
        final stat = await repository.getWrongQuestionStats(q.id);
        if (stat != null) {
          stats.add({
            'questionId': q.id,
            'interval': stat.interval,
            'consecutiveCorrect': stat.consecutiveCorrect,
            'masteryLevel': stat.masteryLevel,
            'nextReviewDate': stat.nextReviewDate,
          });
        }
      }

      setState(() {
        _reviewQuestions = questions;
        _reviewStats = stats;
        _currentIndex = 0;
        _isLoading = false;
        _tempSelectedOptions.clear();
        _tempIsAnswered.clear();
        _fillAnswers.clear();
        _correctCount = 0;
        _wrongCount = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载复习题目失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAnswer(Question question, bool isCorrect) async {
    if (_tempIsAnswered[question.id] == true) return;

    setState(() {
      _tempIsAnswered[question.id] = true;
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    final repository = QuestionRepository();
    await repository.updateReviewStats(question.id, isCorrect);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect
              ? '✅ 记住了！间隔延长 🎉'
              : '❌ 再想想！间隔缩短 💪',
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      if (_currentIndex < _reviewQuestions.length - 1) {
        setState(() {
          _currentIndex++;
          _tempIsAnswered.remove(question.id);
          _tempSelectedOptions.remove(question.id);
          _fillAnswers.remove(question.id);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 本轮复习完成！正确率 ${_correctCount + _wrongCount > 0 ? ((_correctCount / (_correctCount + _wrongCount)) * 100).round() : 0}%'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {});
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isStudyMode = !_isStudyMode;
      _tempIsAnswered.clear();
      _tempSelectedOptions.clear();
      _fillAnswers.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isStudyMode ? '📖 切换到背题模式' : '🔄 切换到复习模式'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 智能复习'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isStudyMode ? Icons.visibility : Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _toggleMode,
            tooltip: _isStudyMode ? '切换到复习模式' : '切换到背题模式',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviewQuestions,
            tooltip: '刷新',
          ),
        ],
        bottom: _isLoading
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildStatsBar(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviewQuestions.isEmpty
          ? _buildEmptyState(context)
          : _buildContent(context),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: QuestionRepository().getReviewStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final total = stats['total'] ?? 0;
        final dueCount = stats['dueCount'] ?? 0;
        final mastered = stats['mastered'] ?? 0;
        final reviewedToday = stats['reviewedToday'] ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.purple.shade800,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('📚 总错题', '$total', Colors.white),
              _buildStatItem('📝 待复习', '$dueCount', Colors.yellowAccent),
              _buildStatItem('✅ 已掌握', '$mastered', Colors.greenAccent),
              _buildStatItem('📖 今日复习', '$reviewedToday', Colors.cyanAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            '🎉 今天没有需要复习的题目！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '继续保持，全部掌握！',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final total = _reviewQuestions.length;
    final currentQuestion = _reviewQuestions[_currentIndex];

    final isAnswered = _tempIsAnswered[currentQuestion.id] ?? false;
    final selectedOption = _tempSelectedOptions[currentQuestion.id];

    final currentStats = _reviewStats.isNotEmpty && _currentIndex < _reviewStats.length
        ? _reviewStats[_currentIndex]
        : null;
    final interval = currentStats?['interval'] ?? 1;

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final appBarHeight = AppBar().preferredSize.height + 50;
    final availableHeight = screenHeight - statusBarHeight - bottomPadding - appBarHeight - 16;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🧠 ${_currentIndex + 1}/$total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⏳ ${total - _currentIndex - 1} 题剩余',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '📊 正确率 ${_correctCount + _wrongCount > 0 ? ((_correctCount / (_correctCount + _wrongCount)) * 100).round() : 0}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '📅 ${interval}天',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            backgroundColor: theme.colorScheme.surfaceVariant,
            color: Colors.purple,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: availableHeight * 0.45,
            child: SingleChildScrollView(
              child: QuestionCard(
                key: ValueKey(currentQuestion.id),
                question: currentQuestion,
                currentIndex: _currentIndex,
                total: total,
                isShuffled: false,
                isStudyMode: _isStudyMode,
                fillAnswer: _fillAnswers[currentQuestion.id] ?? '',
                onFillChanged: (value) {
                  setState(() {
                    _fillAnswers[currentQuestion.id] = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (_isStudyMode) ...[
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _handleAnswer(currentQuestion, true);
                },
                icon: const Icon(Icons.visibility),
                label: const Text('查看答案并标记已复习'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '📖 背题模式：查看答案后标记为已复习',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (isAnswered) ...[
            const Center(
              child: Text(
                '⏳ 正在跳转下一题...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _handleAnswer(currentQuestion, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.close, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              '记错了 ❌',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.lightGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _handleAnswer(currentQuestion, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              '记住了 ✅',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '根据记忆判断是否记住，系统会自动调整复习间隔',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}