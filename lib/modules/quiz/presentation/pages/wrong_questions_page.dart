import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import 'wrong_reinforce_page.dart';
import 'review_page.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';

class WrongQuestionsPage extends StatefulWidget {
  const WrongQuestionsPage({super.key});

  @override
  State<WrongQuestionsPage> createState() => _WrongQuestionsPageState();
}

class _WrongQuestionsPageState extends State<WrongQuestionsPage> {
  List<Question> _wrongQuestions = [];
  List<String> _availableSetNames = [];
  String? _selectedSetName;
  bool _isLoading = true;
  int _currentIndex = 0;

  bool _isReviewMode = true;
  bool _isStudyMode = false;

  final Map<String, int> _tempSelectedOptions = {};
  final Map<String, bool> _tempIsAnswered = {};
  final Map<String, String> _fillAnswers = {};
  final Map<String, bool?> _tempIsCorrect = {};

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  Map<String, int> _stats = {};
  int _correctCount = 0;
  int _wrongCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final repository = QuestionRepository();
      final setNames = await repository.getWrongQuestionSetNames();
      setState(() {
        _availableSetNames = setNames;
      });
      await _loadWrongQuestions();
      await _loadStats();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('加载数据失败: $e');
    }
  }

  Future<void> _loadWrongQuestions() async {
    try {
      final repository = QuestionRepository();
      final records = await repository.getWrongQuestionRecordsBySet(
        setName: _selectedSetName,
      );

      final questions = <Question>[];
      if (records.isNotEmpty) {
        for (var record in records) {
          final setName = record['setName'] ?? '默认题库';
          final questionId = record['id'];
          final box = await Hive.openBox<Question>(_getBoxName(setName));
          for (var q in box.values) {
            if (q.id == questionId) {
              final cloned = q.copyWith(
                isAnswered: false,
                selectedOption: null,
                isWrong: true,
                clearSelectedOption: true,
                clearIsAnswered: true,
              );
              questions.add(cloned);
              break;
            }
          }
        }
      }

      setState(() {
        _wrongQuestions = questions;
        _currentIndex = 0;
        _tempSelectedOptions.clear();
        _tempIsAnswered.clear();
        _tempIsCorrect.clear();
        _fillAnswers.clear();
        _selectedIds.clear();
        _isSelectionMode = false;
        _isLoading = false;
        _correctCount = 0;
        _wrongCount = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('加载错题失败: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final repository = QuestionRepository();
      final stats = await repository.getWrongStatsSummary();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      debugPrint('加载统计失败: $e');
    }
  }

  String _getBoxName(String setName) {
    return 'questionsBox_${Uri.encodeComponent(setName)}';
  }

  Future<void> _removeWrongQuestion(String questionId, {bool showSnackBar = true}) async {
    final repository = QuestionRepository();
    await repository.removeWrongQuestion(questionId);
    if (!mounted) return;
    setState(() {
      _wrongQuestions.removeWhere((q) => q.id == questionId);
      _tempSelectedOptions.remove(questionId);
      _tempIsAnswered.remove(questionId);
      _tempIsCorrect.remove(questionId);
      _fillAnswers.remove(questionId);
      _selectedIds.remove(questionId);
      if (_currentIndex >= _wrongQuestions.length) {
        _currentIndex = _wrongQuestions.length - 1;
      }
    });
    _loadStats();
    if (_wrongQuestions.isEmpty && showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 所有错题已掌握！继续加油！'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleChoiceAnswer(Question question, int selectedIndex) {
    if (_tempIsAnswered[question.id] == true) return;

    final isCorrect = selectedIndex == question.correctIndex;

    setState(() {
      _tempSelectedOptions[question.id] = selectedIndex;
      _tempIsAnswered[question.id] = true;
      _tempIsCorrect[question.id] = isCorrect;
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    if (isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 答对了！已从错题集移除 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      _removeWrongQuestion(question.id, showSnackBar: false);
      if (_wrongQuestions.isEmpty) return;
      if (_currentIndex >= _wrongQuestions.length) {
        _currentIndex = _wrongQuestions.length - 1;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 答错了，再想想！继续加油 💪'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _tempIsAnswered[question.id] = false;
            _tempSelectedOptions.remove(question.id);
            _tempIsCorrect.remove(question.id);
          });
        }
      });
    }
  }

  void _handleFillAnswer(Question question) {
    if (_tempIsAnswered[question.id] == true) return;

    final userAnswer = _fillAnswers[question.id]?.trim() ?? '';
    final correctAnswer = question.answer?.trim() ?? '';
    final isCorrect = userAnswer == correctAnswer;

    setState(() {
      _tempIsAnswered[question.id] = true;
      _tempIsCorrect[question.id] = isCorrect;
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    if (isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 答对了！已从错题集移除 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      _removeWrongQuestion(question.id, showSnackBar: false);
      if (_wrongQuestions.isEmpty) return;
      if (_currentIndex >= _wrongQuestions.length) {
        _currentIndex = _wrongQuestions.length - 1;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 答错了，再想想！不显示答案，请自己回忆 💪'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _tempIsAnswered[question.id] = false;
            _tempIsCorrect.remove(question.id);
            _fillAnswers[question.id] = '';
          });
        }
      });
    }
  }

  void _showAnswer(Question question) {
    setState(() {
      _tempIsAnswered[question.id] = true;
      _tempIsCorrect[question.id] = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📖 正确答案：${_getAnswerText(question)}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _batchRemoveWrongQuestions() async {
    if (_selectedIds.isEmpty) return;
    final repository = QuestionRepository();
    await repository.batchRemoveWrongQuestions(_selectedIds.toList());
    if (!mounted) return;
    setState(() {
      _wrongQuestions.removeWhere((q) => _selectedIds.contains(q.id));
      _selectedIds.clear();
      _isSelectionMode = false;
      if (_currentIndex >= _wrongQuestions.length) {
        _currentIndex = _wrongQuestions.length - 1;
      }
    });
    _loadStats();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 已移除 ${_selectedIds.length} 道错题'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _wrongQuestions.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_wrongQuestions.map((q) => q.id));
      }
    });
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _goToNext() {
    if (_currentIndex < _wrongQuestions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🗑️ 清空所有错题？'),
        content: const Text(
          '此操作将删除所有错题记录，且不可恢复。\n\n'
              '确定要继续吗？',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final repository = QuestionRepository();
              await repository.clearAllWrongQuestions();
              if (!context.mounted) return;
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已清空所有错题'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isReviewMode = !_isReviewMode;
      if (_isReviewMode) {
        _isStudyMode = false;
      } else {
        _isStudyMode = true;
      }
      _tempIsAnswered.clear();
      _tempSelectedOptions.clear();
      _tempIsCorrect.clear();
      _fillAnswers.clear();
      _currentIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isReviewMode ? '🔄 复习模式：答对移除，答错不显示答案' : '📖 背题模式：点击"显示答案"查看正确答案'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '❌ 错题集 (${_wrongQuestions.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew, color: Colors.white),
            onPressed: () {
              if (_wrongQuestions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('暂无错题，无法进入强化练习'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WrongReinforcePage(
                    wrongQuestions: _wrongQuestions,
                  ),
                ),
              );
            },
            tooltip: '🔄 错题强化练习（循环刷题）',
          ), // ========== 新增智能复习入口 ==========
          IconButton(
            icon: const Icon(Icons.psychology, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReviewPage(),
                ),
              );
            },
            tooltip: '🧠 智能复习',
          ),
          IconButton(
            icon: Icon(
              _isReviewMode ? Icons.refresh : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: _toggleMode,
            tooltip: _isReviewMode ? '切换到背题模式' : '切换到复习模式',
          ),
          if (_wrongQuestions.isNotEmpty)
            IconButton(
              icon: Icon(
                _isSelectionMode ? Icons.checklist : Icons.checklist_outlined,
                color: Colors.white,
              ),
              onPressed: _toggleSelectionMode,
              tooltip: _isSelectionMode ? '退出选择模式' : '批量选择',
            ),
          if (_isSelectionMode && _selectedIds.isNotEmpty)
            TextButton(
              onPressed: _batchRemoveWrongQuestions,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('移除选中'),
            ),
          if (_availableSetNames.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              tooltip: '筛选题库',
              onSelected: (value) {
                setState(() {
                  _selectedSetName = value == '全部' ? null : value;
                  _currentIndex = 0;
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
                _loadWrongQuestions();
              },
              itemBuilder: (context) {
                final items = <PopupMenuItem<String>>[];
                items.add(
                  const PopupMenuItem(
                    value: '全部',
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, size: 18),
                        SizedBox(width: 8),
                        Text('全部'),
                      ],
                    ),
                  ),
                );
                for (var name in _availableSetNames) {
                  items.add(
                    PopupMenuItem(
                      value: name,
                      child: Row(
                        children: [
                          Icon(Icons.folder, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text(name)),
                          if (_selectedSetName == name)
                            Icon(Icons.check, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  );
                }
                return items;
              },
            ),
          if (_wrongQuestions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearConfirm(context),
              tooltip: '清空所有错题',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
        bottom: _isLoading
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _buildStatsBar(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wrongQuestions.isEmpty
            ? _buildEmptyState(context)
            : _isSelectionMode
            ? _buildSelectionContent(context)
            : _buildContent(context),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final total = _stats['total'] ?? 0;
    final todayNew = _stats['todayNew'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.red.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('📚 总计', '$total', Colors.white),
          _buildStatItem('🆕 今日新增', '$todayNew', Colors.yellowAccent),
          _buildStatItem('✅ 已掌握', '${total - _wrongQuestions.length}', Colors.greenAccent),
          _buildStatItem('📝 待复习', '${_wrongQuestions.length}', Colors.orangeAccent),
          _buildStatItem(
            '🎯 本次正确率',
            _correctCount + _wrongCount > 0
                ? '${((_correctCount / (_correctCount + _wrongCount)) * 100).round()}%'
                : '--',
            Colors.cyanAccent,
          ),
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
          Text(
            _selectedSetName == null
                ? '🎊 没有错题！'
                : '🎊 当前题库没有错题！',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _correctCount + _wrongCount > 0
                ? '本次练习正确率 ${((_correctCount / (_correctCount + _wrongCount)) * 100).round()}%'
                : '继续保持，再接再厉！',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('返回题库列表'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionContent(BuildContext context) {
    final theme = Theme.of(context);
    final total = _wrongQuestions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _selectedIds.length == total,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: Colors.blue,
              ),
              Text(
                '全选 (${_selectedIds.length}/$total)',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_selectedIds.isNotEmpty)
                TextButton(
                  onPressed: _batchRemoveWrongQuestions,
                  child: const Text('移除选中'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: total,
            itemBuilder: (context, index) {
              final q = _wrongQuestions[index];
              final isSelected = _selectedIds.contains(q.id);
              final contentPreview = q.content.length > 40
                  ? '${q.content.substring(0, 40)}...'
                  : q.content;

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => _toggleSelect(q.id),
                title: Text(
                  '${index + 1}. $contentPreview',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '来源: ${q.source}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: theme.primaryColor.withValues(alpha: 0.1),
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final total = _wrongQuestions.length;
    final currentQuestion = _wrongQuestions[_currentIndex];
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == total - 1;

    final isAnswered = _tempIsAnswered[currentQuestion.id] ?? false;
    final selectedOption = _tempSelectedOptions[currentQuestion.id];
    final isCorrect = _tempIsCorrect[currentQuestion.id];
    final isFill = currentQuestion.options.length == 1 &&
        currentQuestion.options.first.contains('填空');
    final isJudge = currentQuestion.options.length == 2 &&
        currentQuestion.options.contains('正确') &&
        currentQuestion.options.contains('错误');

    final unansweredCount = _wrongQuestions
        .where((q) => !(_tempIsAnswered[q.id] ?? false))
        .length;

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final appBarHeight = AppBar().preferredSize.height + 44;
    final availableHeight = screenHeight - statusBarHeight - bottomPadding - appBarHeight - 16;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -300) {
          if (!isLast) {
            _goToNext();
          }
        } else if (details.primaryVelocity! > 300) {
          if (!isFirst) {
            _goToPrevious();
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '❌ $total 道',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedSetName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📂 $_selectedSetName',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⏳ $unansweredCount 题未答',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isReviewMode ? Colors.green.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isReviewMode ? '🔄 复习' : '📖 背题',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _isReviewMode ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: Colors.red,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentIndex + 1} / $total',
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: availableHeight * 0.48,
              child: SingleChildScrollView(
                child: _buildQuestionCard(
                  context,
                  question: currentQuestion,
                  isAnswered: isAnswered,
                  selectedOption: selectedOption,
                  isCorrect: isCorrect,
                  isFill: isFill,
                  isJudge: isJudge,
                  onChoiceSelected: (index) =>
                      _handleChoiceAnswer(currentQuestion, index),
                  onFillSubmitted: () => _handleFillAnswer(currentQuestion),
                  onShowAnswer: () => _showAnswer(currentQuestion),
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (_isReviewMode && isAnswered && isCorrect == true) ...[
              const Center(
                child: Text(
                  '✅ 已掌握！自动移除 🎉',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ] else if (_isReviewMode && isAnswered && isCorrect == false) ...[
              const Center(
                child: Text(
                  '❌ 答错了，请重新作答 💪',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '提示：答错不会显示答案，请自己回忆',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (_isStudyMode && isAnswered) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Text(
                    '📖 正确答案：${_getAnswerText(currentQuestion)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: isFirst
                          ? null
                          : LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: isFirst
                          ? null
                          : [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color: isFirst ? theme.colorScheme.onSurface.withValues(alpha: 0.3) : Colors.white,
                          size: 22),
                      onPressed: isFirst ? null : _goToPrevious,
                      style: IconButton.styleFrom(
                        backgroundColor: isFirst ? theme.colorScheme.surfaceContainerHighest : theme.primaryColor,
                        fixedSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      splashRadius: 24,
                    ),
                  ),
                  if (_isStudyMode)
                    ElevatedButton.icon(
                      onPressed: () => _showAnswer(currentQuestion),
                      icon: const Icon(Icons.lightbulb, size: 18),
                      label: const Text('显示答案'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (!_isStudyMode)
                    ElevatedButton.icon(
                      onPressed: () {
                        _removeWrongQuestion(currentQuestion.id);
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('已掌握，移除'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: isLast
                          ? const LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (isLast ? Colors.green : theme.primaryColor).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isLast ? Icons.check : Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: isLast ? 26 : 22,
                      ),
                      onPressed: isLast
                          ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已到最后一题'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                          : _goToNext,
                      style: IconButton.styleFrom(
                        backgroundColor: isLast ? Colors.green : theme.primaryColor,
                        fixedSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _isReviewMode
                  ? '🔄 复习模式：答对自动移除，答错不显示答案'
                  : '📖 背题模式：点击"显示答案"查看正确答案',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAnswerText(Question question) {
    if (question.options.length == 2 &&
        question.options.contains('正确') &&
        question.options.contains('错误')) {
      return question.correctIndex == 0 ? '正确' : '错误';
    }
    if (question.answer != null && question.answer!.isNotEmpty) {
      return question.answer!;
    }
    if (question.options.isNotEmpty && question.correctIndex < question.options.length) {
      return question.options[question.correctIndex];
    }
    return '已设置';
  }

  Widget _buildQuestionCard(
      BuildContext context, {
        required Question question,
        required bool isAnswered,
        required int? selectedOption,
        required bool? isCorrect,
        required bool isFill,
        required bool isJudge,
        required Function(int) onChoiceSelected,
        required VoidCallback onFillSubmitted,
        required VoidCallback onShowAnswer,
      }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isJudge
                        ? Colors.purple.shade100
                        : (isFill ? Colors.orange.shade100 : Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isJudge ? '判断题' : (isFill ? '填空题' : '选择题'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isJudge
                          ? Colors.purple.shade700
                          : (isFill ? Colors.orange.shade700 : Colors.green.shade700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isReviewMode ? Colors.green.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isReviewMode ? '🔄 复习' : '📖 背题',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _isReviewMode ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
                if (isAnswered && isCorrect != null)
                  const SizedBox(width: 8),
                if (isAnswered && isCorrect != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCorrect ? '✅ 正确' : '❌ 错误',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                if (isAnswered && isCorrect == null)
                  const SizedBox(width: 8),
                if (isAnswered && isCorrect == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '📖 查看答案',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              question.content.isNotEmpty ? question.content : '（题目内容为空）',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            if (isFill) ...[
              if (isAnswered && isCorrect == true) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        '✅ 答对了！已移除错题 🎉',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isAnswered && isCorrect == false) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        '❌ 答错了，重新作答！💪',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isAnswered && isCorrect == null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '📖 正确答案：${question.answer ?? "（未设置答案）"}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '请输入答案...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        onChanged: (value) {
                          setState(() {
                            _fillAnswers[question.id] = value;
                          });
                        },
                        onSubmitted: (_) => onFillSubmitted(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onFillSubmitted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Text('确认'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isReviewMode
                      ? '提示：答错不会显示答案，请自己回忆'
                      : '提示：点击"显示答案"查看正确答案',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],

            if (!isFill) ...[
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = selectedOption == index;
                final isOptionCorrect = index == question.correctIndex;

                Color? tileColor;
                if (isAnswered && isCorrect != null) {
                  if (isCorrect && isOptionCorrect) {
                    tileColor = Colors.green.shade100;
                  } else if (!isCorrect && isSelected && !isOptionCorrect) {
                    tileColor = Colors.red.shade100;
                  }
                } else if (isSelected) {
                  tileColor = theme.primaryColor.withValues(alpha: 0.1);
                }
                if (isAnswered && isCorrect == null && isOptionCorrect) {
                  tileColor = Colors.blue.shade50;
                }

                final letter = isJudge
                    ? (index == 0 ? 'T' : 'F')
                    : String.fromCharCode(65 + index);

                String displayOption = option;
                if (isJudge && index == 0 && option == '正确') {
                  displayOption = '✅ 正确';
                } else if (isJudge && index == 1 && option == '错误') {
                  displayOption = '❌ 错误';
                }

                Color textColor;
                if (isAnswered && isCorrect == true && isOptionCorrect) {
                  textColor = Colors.green.shade700;
                } else if (isAnswered && isCorrect == false && isSelected && !isOptionCorrect) {
                  textColor = Colors.red.shade700;
                } else if (isAnswered && isCorrect == null && isOptionCorrect) {
                  textColor = Colors.blue.shade700;
                } else {
                  textColor = theme.colorScheme.onSurface;
                }

                final bool isEnabled = !isAnswered || (isCorrect == null);

                return Material(
                  borderRadius: BorderRadius.circular(8),
                  color: tileColor,
                  child: ListTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected && isEnabled
                            ? theme.primaryColor
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isSelected && isEnabled
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      displayOption,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    onTap: isEnabled ? () => onChoiceSelected(index) : null,
                    enabled: isEnabled,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}