import 'package:flutter/material.dart';

import '../../data/models/question_model.dart';
import '../widgets/question_card.dart';

class WrongReinforcePage extends StatefulWidget {
  final List<Question> wrongQuestions;

  const WrongReinforcePage({
    super.key,
    required this.wrongQuestions,
  });

  @override
  State<WrongReinforcePage> createState() => _WrongReinforcePageState();
}

class _WrongReinforcePageState extends State<WrongReinforcePage> {
  List<Question> _practiceQueue = [];
  int _currentIndex = 0;
  bool _isStudyMode = false;
  bool _isCompleted = false;

  final Map<String, int> _tempSelectedOptions = {};
  final Map<String, bool> _tempIsAnswered = {};
  final Map<String, String> _fillAnswers = {};

  int _correctCount = 0;
  int _wrongCount = 0;
  int _totalAttempts = 0;

  @override
  void initState() {
    super.initState();
    _practiceQueue = List.from(widget.wrongQuestions)..shuffle();
    _currentIndex = 0;
  }

  void _handleAnswer(Question question, bool isCorrect) {
    if (_tempIsAnswered[question.id] == true) return;

    setState(() {
      _tempIsAnswered[question.id] = true;
      _totalAttempts++;

      if (isCorrect) {
        _correctCount++;
        _practiceQueue.removeWhere((q) => q.id == question.id);
      } else {
        _wrongCount++;
        _practiceQueue.removeWhere((q) => q.id == question.id);
        _practiceQueue.add(question);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect
              ? '✅ 答对了！已从当前队列移除 🎉'
              : '❌ 答错了！重新排队，稍后再次出现 💪',
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.orange,
        duration: const Duration(milliseconds: 800),
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      if (_practiceQueue.isEmpty) {
        setState(() {
          _isCompleted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 全部掌握！正确率 ${_correctCount + _wrongCount > 0 ? ((_correctCount / (_correctCount + _wrongCount)) * 100).round() : 0}%',
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      if (_currentIndex >= _practiceQueue.length) {
        _currentIndex = 0;
      }

      setState(() {
        _tempIsAnswered.remove(question.id);
        _tempSelectedOptions.remove(question.id);
        _fillAnswers.remove(question.id);
        if (_currentIndex < _practiceQueue.length) {
        } else {
          _currentIndex = 0;
        }
      });
    });
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
        content: Text(_isStudyMode ? '📖 切换到背题模式' : '🔄 切换到强化练习模式'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showExitConfirm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退出？'),
        content: Text(
          '当前进度：\n'
              '✅ 已掌握 $_correctCount 道\n'
              '❌ 还需练习 ${_practiceQueue.length} 道\n\n'
              '退出后进度将丢失，确定退出吗？',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('继续练习'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
  }

  void _resetPractice() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🔄 重新开始？'),
        content: const Text('将重置所有进度，重新开始练习'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _practiceQueue = List.from(widget.wrongQuestions)..shuffle();
                _currentIndex = 0;
                _correctCount = 0;
                _wrongCount = 0;
                _totalAttempts = 0;
                _isCompleted = false;
                _tempIsAnswered.clear();
                _tempSelectedOptions.clear();
                _fillAnswers.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已重置，重新开始练习'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirm();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔄 错题强化练习'),
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(
                _isStudyMode ? Icons.visibility : Icons.refresh,
                color: Colors.white,
              ),
              onPressed: _toggleMode,
              tooltip: _isStudyMode ? '切换到强化练习' : '切换到背题模式',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetPractice,
              tooltip: '重新开始',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _showExitConfirm,
              tooltip: '退出',
            ),
          ],
          bottom: _isCompleted
              ? null
              : PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: _buildStatsBar(context),
          ),
        ),
        body: _isCompleted
            ? _buildCompletionScreen(context)
            : _practiceQueue.isEmpty
            ? _buildEmptyState(context)
            : _buildContent(context),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final total = widget.wrongQuestions.length;
    final remaining = _practiceQueue.length;
    final mastered = total - remaining;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.deepPurple.shade800,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('📚 总数', '$total', Colors.white),
          _buildStatItem('✅ 已掌握', '$mastered', Colors.greenAccent),
          _buildStatItem('📝 待练习', '$remaining', Colors.yellowAccent),
          _buildStatItem(
            '🎯 正确率',
            _correctCount + _wrongCount > 0
                ? '${((_correctCount / (_correctCount + _wrongCount)) * 100).round()}%'
                : '--',
            Colors.cyanAccent,
          ),
          _buildStatItem('🔄 尝试', '$_totalAttempts', Colors.orangeAccent),
        ],
      ),
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

  Widget _buildCompletionScreen(BuildContext context) {
    final theme = Theme.of(context);
    final rate = _correctCount + _wrongCount > 0
        ? ((_correctCount / (_correctCount + _wrongCount)) * 100).round()
        : 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade100,
            ),
            child: Icon(
              Icons.celebration,
              size: 80,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🎉 全部掌握！',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '你已正确答完所有错题！',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '📊 正确率 $rate%  |  总尝试 $_totalAttempts 次',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _resetPractice,
                icon: const Icon(Icons.refresh),
                label: const Text('再来一轮'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回错题集'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            '当前队列已清空！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击「重新开始」继续练习',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetPractice,
            icon: const Icon(Icons.refresh),
            label: const Text('重新开始'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final total = _practiceQueue.length;
    final currentQuestion = _practiceQueue[_currentIndex % total];

    if (_currentIndex >= total) {
      _currentIndex = 0;
    }

    final isAnswered = _tempIsAnswered[currentQuestion.id] ?? false;
    final isFill = currentQuestion.options.length == 1 &&
        currentQuestion.options.first.contains('填空');

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final appBarHeight = AppBar().preferredSize.height + 50;
    final availableHeight = screenHeight - statusBarHeight - bottomPadding - appBarHeight - 16;

    final fillAnswer = _fillAnswers[currentQuestion.id] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 进度信息
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🔄 第 ${(_currentIndex + 1)}/$total 题',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple.shade700,
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
                  '❌ 错题强化',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isStudyMode ? Colors.blue.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isStudyMode ? '📖 背题' : '🔄 练习',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _isStudyMode ? Colors.blue.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (widget.wrongQuestions.length - _practiceQueue.length) /
                widget.wrongQuestions.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: Colors.deepPurple,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已掌握 ${widget.wrongQuestions.length - _practiceQueue.length}/${widget.wrongQuestions.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '尝试: $_totalAttempts 次',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ 使用 QuestionCard，传入 onAnswerSelected 回调
          SizedBox(
            height: availableHeight * 0.50,
            child: SingleChildScrollView(
              child: QuestionCard(
                key: ValueKey('${currentQuestion.id}_$_currentIndex'),
                question: currentQuestion,
                currentIndex: _currentIndex,
                total: total,
                isShuffled: false,
                isStudyMode: _isStudyMode,
                fillAnswer: fillAnswer,
                onFillChanged: (value) {
                  setState(() {
                    _fillAnswers[currentQuestion.id] = value;
                  });
                },
                onAnswerSelected: (question, isCorrect) {
                  // ✅ 使用外部回调处理答题
                  _handleAnswer(question, isCorrect);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 底部提示
          if (_isStudyMode) ...[
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _handleAnswer(currentQuestion, true);
                },
                icon: const Icon(Icons.visibility),
                label: const Text('查看答案并标记已掌握'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '📖 背题模式：查看答案后点击标记已掌握',
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
          ] else if (isFill) ...[
            const SizedBox(height: 8),
            Text(
              '💡 输入答案后点击「确认」按钮提交',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '💡 点击上方选项作答，答错会重新排队 💪',
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