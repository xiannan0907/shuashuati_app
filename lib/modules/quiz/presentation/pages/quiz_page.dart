import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../bloc/quiz_bloc.dart';
import '../widgets/question_card.dart';
import 'result_page.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/question_jump_dialog.dart';
import 'manual_import_page.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';

class QuizPage extends StatefulWidget {
  final String setName;
  final int initialIndex;

  const QuizPage({
    super.key,
    required this.setName,
    this.initialIndex = 0,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Timer? _feedbackTimer;
  final TextEditingController _jumpController = TextEditingController();
  bool _importMessageCleared = false;

  String _filterType = '全部';
  int _displayIndex = 0;
  int _previousIndex = -1;
  List<Question> _filteredQuestions = [];
  Map<int, int> _filterToOriginalIndex = {};
  final Map<String, String> _fillAnswers = {};

  bool _isFirstLoad = true;
  String _savedFilterType = '全部';
  int _savedDisplayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizBloc>().add(LoadQuizSet(widget.setName));
    });
  }

  Future<void> _loadSavedState() async {
    try {
      final repository = QuestionRepository();
      final savedFilter = await repository.getFilterType(widget.setName);
      int savedIndex;
      if (widget.initialIndex > 0) {
        savedIndex = widget.initialIndex;
      } else {
        savedIndex = await repository.getDisplayIndex(widget.setName);
      }
      setState(() {
        _savedFilterType = savedFilter;
        _savedDisplayIndex = savedIndex;
      });
      debugPrint('📂 读取保存的状态: 筛选=$savedFilter, 显示索引=$savedIndex');
    } catch (e) {
      debugPrint('❌ 读取保存状态失败: $e');
    }
  }

  // ============================================================
  // 筛选逻辑（修复：默认跳转到第一题）
  // ============================================================
  void _updateFilter(QuizLoaded state, {int? savedDisplayIndex}) {
    final allQuestions = state.questions;
    List<Question> filtered;
    if (_filterType == '全部') {
      filtered = List.from(allQuestions);
    } else {
      filtered = allQuestions.where((q) {
        if (_filterType == '选择题') {
          return q.options.length >= 2 &&
              !q.options.contains('正确') &&
              !q.options.first.contains('填空');
        } else if (_filterType == '判断题') {
          return q.options.length == 2 &&
              q.options.contains('正确') &&
              q.options.contains('错误');
        } else if (_filterType == '填空题') {
          return q.options.length == 1 &&
              q.options.first.contains('填空');
        }
        return false;
      }).toList();
    }
    _filteredQuestions = filtered;
    _filterToOriginalIndex = {};
    for (int i = 0; i < filtered.length; i++) {
      _filterToOriginalIndex[i] = allQuestions.indexOf(filtered[i]);
    }

    // 确定显示索引
    if (savedDisplayIndex != null &&
        savedDisplayIndex >= 0 &&
        savedDisplayIndex < _filteredQuestions.length) {
      _displayIndex = savedDisplayIndex;
    } else if (state.currentIndex >= 0 &&
        state.currentIndex < _filteredQuestions.length) {
      _displayIndex = state.currentIndex;
    } else {
      _displayIndex = _filteredQuestions.isEmpty ? 0 : 0;
    }

    _clampDisplayIndex();
  }

  void _clampDisplayIndex() {
    if (_filteredQuestions.isEmpty) {
      _displayIndex = 0;
      return;
    }
    if (_displayIndex < 0) {
      _displayIndex = 0;
    }
    if (_displayIndex >= _filteredQuestions.length) {
      _displayIndex = _filteredQuestions.length - 1;
    }
  }

  Future<void> _saveCurrentState() async {
    if (_filteredQuestions.isEmpty || _displayIndex >= _filteredQuestions.length) {
      debugPrint('❌ 无法保存，无效的显示索引');
      return;
    }
    try {
      final repository = QuestionRepository();
      await repository.saveFilterType(widget.setName, _filterType);
      await repository.saveDisplayIndex(widget.setName, _displayIndex);
      debugPrint('📌 保存状态: 筛选=$_filterType, 显示索引=$_displayIndex');
    } catch (e) {
      debugPrint('❌ 保存状态失败: $e');
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizBloc>();
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveCurrentState();
        if (mounted) Navigator.pop(this.context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('📚 ${widget.setName}'),
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitConfirm(context, bloc),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, color: theme.appBarTheme.foregroundColor),
              onSelected: (value) {
                setState(() {
                  _filterType = value;
                  _displayIndex = 0;
                  final state = bloc.state;
                  if (state is QuizLoaded) {
                    _updateFilter(state);
                  }
                  _saveCurrentState();
                });
              },
              itemBuilder: (context) {
                final state = context.read<QuizBloc>().state;
                int total = 0, choiceCount = 0, judgeCount = 0, fillCount = 0;
                if (state is QuizLoaded) {
                  final questions = state.questions;
                  total = questions.length;
                  for (var q in questions) {
                    if (q.options.length == 2 &&
                        q.options.contains('正确') &&
                        q.options.contains('错误')) {
                      judgeCount++;
                    } else if (q.options.length == 1 &&
                        q.options.first.contains('填空')) {
                      fillCount++;
                    } else {
                      choiceCount++;
                    }
                  }
                }
                return [
                  PopupMenuItem(value: '全部', child: Text('📚 全部 ($total)')),
                  PopupMenuItem(value: '选择题', child: Text('✅ 选择题 ($choiceCount)')),
                  PopupMenuItem(value: '判断题', child: Text('⚖️ 判断题 ($judgeCount)')),
                  PopupMenuItem(value: '填空题', child: Text('✏️ 填空题 ($fillCount)')),
                ];
              },
            ),
            BlocBuilder<QuizBloc, QuizState>(
              builder: (context, state) {
                bool isStudyMode = state is QuizLoaded && state.isStudyMode;
                return IconButton(
                  icon: Icon(isStudyMode ? Icons.visibility : Icons.edit,
                      color: theme.appBarTheme.foregroundColor),
                  onPressed: () {
                    bloc.add(ToggleStudyMode());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isStudyMode ? '已切换为做题模式' : '已切换为背题模式'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: isStudyMode ? '切换到做题模式' : '切换到背题模式',
                );
              },
            ),
            BlocBuilder<QuizBloc, QuizState>(
              builder: (context, state) {
                bool isShuffled = state is QuizLoaded && state.isShuffled;
                return IconButton(
                  icon: Icon(isShuffled ? Icons.shuffle_on : Icons.shuffle,
                      color: theme.appBarTheme.foregroundColor),
                  onPressed: () {
                    bloc.add(ToggleShuffle());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isShuffled ? '已切换为正序' : '已切换为乱序'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: '切换题目顺序',
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.restore, color: theme.appBarTheme.foregroundColor),
              onPressed: () => _showResetConfirm(context, bloc),
              tooltip: '重置进度',
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.file_upload, color: theme.appBarTheme.foregroundColor),
              onSelected: (value) => _handleImport(context, bloc, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'word', child: Text('📄 导入Word')),
                const PopupMenuItem(value: 'json', child: Text('📋 导入JSON')),
                const PopupMenuItem(value: 'append', child: Text('➕ 追加导入')),
                const PopupMenuItem(value: 'manual', child: Text('📝 手动导入')),
                const PopupMenuItem(value: 'clear', child: Text('🗑️ 清空当前题库')),
              ],
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: theme.appBarTheme.foregroundColor),
              onPressed: () {
                bloc.add(LoadQuizSet(widget.setName));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('刷新中...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: '刷新题库',
            ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<QuizBloc, QuizState>(
            listener: (context, state) {
              if (state is QuizError) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              if (state is QuizLoaded) {
                if (_isFirstLoad) {
                  _isFirstLoad = false;
                  if (_savedFilterType != '全部') {
                    _filterType = _savedFilterType;
                  }
                  _updateFilter(state, savedDisplayIndex: _savedDisplayIndex);
                  _saveCurrentState();
                } else {
                  _updateFilter(state);
                }

                if (state.currentIndex == 0 && _previousIndex != 0) {
                  _fillAnswers.clear();
                }
                _previousIndex = state.currentIndex;

                if (state.importMessage != null && !_importMessageCleared) {
                  _importMessageCleared = true;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.importMessage!),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (context.mounted) {
                      bloc.add(ClearImportMessage());
                    }
                  });
                }
                if (state.importMessage == null) {
                  _importMessageCleared = false;
                }
                if (state.feedback != null && !state.isStudyMode) {
                  final isCorrect = state.feedback!.startsWith('✅');
                  if (isCorrect) {
                    _feedbackTimer?.cancel();
                    _feedbackTimer = Timer(const Duration(seconds: 2), () {
                      if (context.mounted) {
                        bloc.add(ClearFeedback());
                      }
                    });
                  }
                }
              }
            },
            builder: (context, state) {
              if (state is QuizLoaded) {
                return _buildQuizContent(context, state, bloc);
              }
              if (state is QuizLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is QuizImporting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: state.progress / 100,
                          strokeWidth: 6,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        state.message,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.progress}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (state is QuizEmpty) {
                return const EmptyStateWidget();
              }
              if (state is QuizCompleted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultPage(
                        correctCount: state.correctCount,
                        totalCount: state.totalCount,
                        wrongQuestions: state.wrongQuestions,
                        onRetry: () {
                          Navigator.pop(context);
                          bloc.add(ResetQuiz());
                        },
                        onClearFill: () {
                          setState(() {
                            _fillAnswers.clear();
                          });
                        },
                      ),
                    ),
                  );
                });
                return const SizedBox.shrink();
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ 修复后的答题内容构建（不再触发 GoToQuestion）
  // ============================================================
  Widget _buildQuizContent(BuildContext context, QuizLoaded state, QuizBloc bloc) {
    final theme = Theme.of(context);

    // 1. 如果筛选结果为空，重新筛选
    if (_filteredQuestions.isEmpty && state.questions.isNotEmpty) {
      _updateFilter(state);
    }

    // 2. 边界检查
    _clampDisplayIndex();

    // 3. 空状态
    if (_filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 60, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              '当前筛选条件下没有题目',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterType = '全部';
                });
                final currentState = bloc.state;
                if (currentState is QuizLoaded) {
                  _updateFilter(currentState);
                }
                _saveCurrentState();
              },
              child: const Text('显示全部'),
            ),
          ],
        ),
      );
    }

    // 4. 边界检查
    if (_displayIndex >= _filteredQuestions.length) {
      _displayIndex = _filteredQuestions.length - 1;
    }
    if (_displayIndex < 0) {
      _displayIndex = 0;
    }

    // 5. 获取当前题目
    final originalIndex = _filterToOriginalIndex[_displayIndex] ?? 0;
    final currentQuestion = state.questions[originalIndex];
    final total = _filteredQuestions.length;
    final isFirst = _displayIndex == 0;
    final isLast = _displayIndex == total - 1;
    final feedback = state.feedback;
    final isCorrect = feedback?.startsWith('✅') ?? false;
    final unansweredCount = state.questions.where((q) => !q.isAnsweredValue).length;

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final appBarHeight = AppBar().preferredSize.height;
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
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '📚 ${state.questions.length} 道',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '筛选: $_filterType',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_displayIndex + 1) / total,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.primaryColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${_displayIndex + 1} / $total',
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: availableHeight * 0.48,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  if (_displayIndex < total - 1) {
                    _feedbackTimer?.cancel();
                    setState(() {
                      _displayIndex++;
                    });
                    _saveCurrentState();
                  } else {
                    _handleComplete(context, bloc, state);
                  }
                  return;
                }
                if (details.primaryVelocity! > 300) {
                  if (_displayIndex > 0) {
                    _feedbackTimer?.cancel();
                    setState(() {
                      _displayIndex--;
                    });
                    _saveCurrentState();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('已经是第一题了'),
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
              child: SingleChildScrollView(
                child: QuestionCard(
                  key: ValueKey('${currentQuestion.id}_$_displayIndex'),
                  question: currentQuestion,
                  currentIndex: _displayIndex,
                  total: total,
                  isShuffled: state.isShuffled,
                  isStudyMode: state.isStudyMode,
                  fillAnswer: _fillAnswers[currentQuestion.id] ?? '',
                  onFillChanged: (value) {
                    setState(() {
                      _fillAnswers[currentQuestion.id] = value;
                    });
                  },
                ),
              ),
            ),
          ),
          if (feedback != null && !state.isStudyMode)
            GestureDetector(
              onTap: () {
                _feedbackTimer?.cancel();
                bloc.add(ClearFeedback());
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.error,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        feedback,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.close,
                      size: 16,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('跳转到第', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _jumpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 2),
                    ),
                    onSubmitted: (value) => _handleJump(context, bloc, total, value),
                  ),
                ),
                Text('题', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () {
                    _handleJump(context, bloc, total, _jumpController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('跳转'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.list, size: 22, color: theme.primaryColor),
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => QuestionJumpDialog(
                        questions: _filteredQuestions,
                        currentIndex: _displayIndex,
                        onJump: (index) {
                          _feedbackTimer?.cancel();
                          setState(() {
                            _displayIndex = index;
                          });
                          _saveCurrentState();
                        },
                      ),
                    );
                  },
                  tooltip: '题目列表',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    fixedSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
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
                    icon: Icon(Icons.arrow_back_ios, color: isFirst ? theme.colorScheme.onSurface.withValues(alpha: 0.3) : Colors.white, size: 22),
                    onPressed: isFirst
                        ? null
                        : () {
                      if (_displayIndex > 0) {
                        _feedbackTimer?.cancel();
                        setState(() {
                          _displayIndex--;
                        });
                        _saveCurrentState();
                      }
                    },
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
                const SizedBox(width: 30),
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
                        ? () => _handleComplete(context, bloc, state)
                        : () {
                      if (_displayIndex < total - 1) {
                        _feedbackTimer?.cancel();
                        setState(() {
                          _displayIndex++;
                        });
                        _saveCurrentState();
                      }
                    },
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
          ),
        ],
      ),
    );
  }

  void _handleJump(BuildContext context, QuizBloc bloc, int total, String text) {
    final raw = text.trim();
    if (raw.isEmpty) return;
    final number = int.tryParse(raw);
    if (number == null || number < 1 || number > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入 1 ~ $total 之间的数字'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _feedbackTimer?.cancel();
    final targetDisplayIndex = number - 1;
    if (targetDisplayIndex >= 0 && targetDisplayIndex < _filteredQuestions.length) {
      setState(() {
        _displayIndex = targetDisplayIndex;
      });
      _jumpController.clear();
      _saveCurrentState();
    }
  }

  void _handleComplete(BuildContext context, QuizBloc bloc, QuizLoaded state) {
    final theme = Theme.of(context);
    if (state.isStudyMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('背题模式下无法提交，请切换到做题模式'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final unansweredCount = state.questions.where((q) => !q.isAnsweredValue).length;
    if (unansweredCount == 0) {
      final correct = state.questions.where((q) => q.selectedOption == q.correctIndex).length;
      bloc.add(QuizCompletedEvent(correct, state.questions.length));
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('⚠️ 还有题目未作答'),
        content: Text(
          '还有 $unansweredCount 道题未作答。\n\n'
              '点击「继续答题」返回完成所有题目，\n'
              '点击「强制提交」跳过未答题目，直接查看结果。',
          style: TextStyle(
            height: 1.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('继续答题'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final correct = state.questions.where((q) => q.selectedOption == q.correctIndex).length;
              bloc.add(QuizCompletedEvent(correct, state.questions.length));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('强制提交'),
          ),
        ],
      ),
    );
  }

  void _handleImport(BuildContext context, QuizBloc bloc, String value) async {
    if (value == 'clear') {
      _showClearConfirm(context, bloc);
      return;
    }
    if (value == 'manual') {
      final quizBloc = context.read<QuizBloc>();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: quizBloc,
            child: ManualImportPage(currentSetName: widget.setName),
          ),
        ),
      );
      if (result == true && mounted) {
        bloc.add(LoadQuizSet(widget.setName));
      }
      return;
    }
    if (value == 'append') {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'json'],
      );
      if (files.isNotEmpty) {
        final filePaths = files.map((f) => f.path!).toList();
        final ext = files.first.path!.split('.').last.toLowerCase();
        String type = 'json';
        if (ext == 'docx') type = 'word';
        bloc.add(AppendFiles(filePaths, type));
      }
      return;
    }

    final extensions = value == 'word' ? ['docx'] : ['json'];
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (files.isEmpty) return;
    final filePaths = files.map((f) => f.path!).toList();
    bloc.add(ImportFiles(filePaths, value));
  }

  void _showClearConfirm(BuildContext context, QuizBloc bloc) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🗑️ 清空当前题库？'),
        content: Text(
          '此操作将删除当前题库中所有题目，且不可恢复。确定要继续吗？',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(ClearAllQuestions());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirm(BuildContext context, QuizBloc bloc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出刷题吗？\n当前进度将自动保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('继续刷题'),
          ),
          TextButton(
            onPressed: () async {
              await _saveCurrentState();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirm(BuildContext context, QuizBloc bloc) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🔄 重置进度'),
        content: Text(
          '确定要重置当前题库的所有答题进度吗？\n\n'
              '此操作将：\n'
              '• 清空所有题目的答题记录\n'
              '• 回到第一题重新开始\n\n'
              '此操作不可撤销！',
          style: TextStyle(
            height: 1.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(ResetProgress());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }
}