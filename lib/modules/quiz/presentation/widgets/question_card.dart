import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/quiz_bloc.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final int currentIndex;
  final int total;
  final bool isShuffled;
  final bool isStudyMode;
  final String fillAnswer;
  final ValueChanged<String> onFillChanged;
  final Function(Question, bool)? onAnswerSelected;
  final Function(bool)? onFavoriteChanged;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.total,
    this.isShuffled = false,
    this.isStudyMode = false,
    required this.fillAnswer,
    required this.onFillChanged,
    this.onAnswerSelected,
    this.onFavoriteChanged,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _fillController;
  late UniqueKey _textFieldKey;

  // ✅ 本地收藏状态，用于立即 UI 反馈
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.question.isFavorite;
    _initController();
  }

  void _initController() {
    _fillController = TextEditingController(text: widget.fillAnswer);
    _textFieldKey = UniqueKey();
  }

  @override
  void didUpdateWidget(QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换题目时同步收藏状态
    if (oldWidget.question.id != widget.question.id) {
      _isFavorite = widget.question.isFavorite;
      _fillController.dispose();
      _initController();
      setState(() {});
    } else {
      if (_fillController.text != widget.fillAnswer) {
        _fillController.text = widget.fillAnswer;
      }
      // 如果外部数据变化（比如从其它地方修改），同步本地状态
      if (_isFavorite != widget.question.isFavorite) {
        _isFavorite = widget.question.isFavorite;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  // ==================== 收藏切换（立即反馈） ====================
  Future<void> _toggleFavorite() async {
    // 1. 立即更新 UI（乐观更新）
    final newState = !_isFavorite;
    setState(() {
      _isFavorite = newState;
    });

    // 2. 通知父组件（如果有）
    if (widget.onFavoriteChanged != null) {
      widget.onFavoriteChanged!(newState);
    }

    // 3. 异步保存到数据库，失败则回滚
    try {
      final repo = QuestionRepository();
      final result = await repo.toggleFavorite(widget.question.id);
      if (!mounted) return;
      if (result != newState) {
        // 保存结果与预期不符，回滚
        setState(() {
          _isFavorite = !newState;
        });
        if (widget.onFavoriteChanged != null) {
          widget.onFavoriteChanged!(_isFavorite);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('操作失败，请重试'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // 成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? '⭐ 已收藏' : '已取消收藏'),
            duration: const Duration(seconds: 1),
            backgroundColor: result ? Colors.amber : Colors.grey,
          ),
        );
      }
    } catch (e) {
      // 异常回滚
      if (!mounted) return;
      setState(() {
        _isFavorite = !newState;
      });
      if (widget.onFavoriteChanged != null) {
        widget.onFavoriteChanged!(_isFavorite);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('收藏失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== 构建 UI ====================
  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isShuffled = widget.isShuffled;
    final isStudyMode = widget.isStudyMode;
    final theme = Theme.of(context);

    final isJudge = q.options.length == 2 &&
        q.options.contains('正确') &&
        q.options.contains('错误');
    final isFill = q.options.length == 1 &&
        q.options.first.contains('填空');

    final displayContent = q.content.isNotEmpty ? q.content : '（题目内容为空）';

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
                if (!isShuffled)
                  Text(
                    '第 ${widget.currentIndex + 1} 题',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  )
                else
                  Text(
                    '📝 题目',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                const SizedBox(width: 8),
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
                    color: isStudyMode ? Colors.orange.shade100 : theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isStudyMode ? '📖 背题' : '✍️ 做题',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isStudyMode ? Colors.orange.shade700 : theme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                // ✅ 收藏按钮（使用本地状态 _isFavorite）
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    color: _isFavorite ? Colors.amber : Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: _toggleFavorite,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _isFavorite ? '取消收藏' : '收藏题目',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayContent,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            if (isFill) ...[
              if (isStudyMode) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '正确答案：${q.answer ?? "（未设置答案）"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildFillInput(context),
              ],
            ],

            if (!isFill) ...[
              ..._buildChoiceOptions(context),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== 构建选择题/判断题选项 ====================
  List<Widget> _buildChoiceOptions(BuildContext context) {
    final q = widget.question;
    final isJudge = q.options.length == 2 &&
        q.options.contains('正确') &&
        q.options.contains('错误');
    final isStudyMode = widget.isStudyMode;
    final theme = Theme.of(context);

    return q.options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final letter = isJudge
          ? (index == 0 ? 'T' : 'F')
          : String.fromCharCode(65 + index);
      final isSelected = q.selectedOption == index;
      final isAnswered = q.isAnsweredValue;
      final isCorrect = index == q.correctIndex;

      Color? tileColor;
      if (isStudyMode) {
        if (isCorrect) {
          tileColor = Colors.green.shade100;
        }
      } else {
        if (isAnswered) {
          if (isCorrect) {
            tileColor = Colors.green.shade100;
          } else if (isSelected && !isCorrect) {
            tileColor = Colors.red.shade100;
          }
        } else if (isSelected) {
          tileColor = theme.primaryColor.withValues(alpha: 0.1);
        }
      }

      String displayOption = option;
      if (isJudge && index == 0 && option == '正确') {
        displayOption = '✅ 正确';
      } else if (isJudge && index == 1 && option == '错误') {
        displayOption = '❌ 错误';
      }

      Widget titleWidget = Text(
        displayOption,
        style: TextStyle(
          fontSize: 15,
          color: isStudyMode
              ? (isCorrect ? Colors.green.shade700 : theme.colorScheme.onSurface.withValues(alpha: 0.6))
              : (isAnswered
              ? (isCorrect
              ? Colors.green.shade700
              : (isSelected
              ? Colors.red.shade700
              : theme.colorScheme.onSurface.withValues(alpha: 0.7)))
              : theme.colorScheme.onSurface),
          fontWeight: isStudyMode && isCorrect
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      );

      if (isStudyMode && isCorrect) {
        titleWidget = Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 4),
            Expanded(child: titleWidget),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '正确答案',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      }

      return Material(
        borderRadius: BorderRadius.circular(8),
        color: tileColor,
        child: ListTile(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isStudyMode
                  ? (isCorrect ? Colors.green : theme.colorScheme.surfaceContainerHighest)
                  : (isSelected ? theme.primaryColor : theme.colorScheme.surfaceContainerHighest),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: isStudyMode
                      ? (isCorrect ? Colors.white : theme.colorScheme.onSurfaceVariant)
                      : (isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          title: titleWidget,
          onTap: () {
            if (isStudyMode) return;
            if (isAnswered) return;

            if (widget.onAnswerSelected != null) {
              widget.onAnswerSelected!(q, isCorrect);
            } else {
              context.read<QuizBloc>().add(SelectAnswer(index));
            }
          },
          enabled: !isStudyMode && !isAnswered,
        ),
      );
    }).toList();
  }

  // ==================== 填空题输入框 ====================
  Widget _buildFillInput(BuildContext context) {
    final q = widget.question;
    final isAnswered = q.isAnsweredValue;
    final correctAnswer = q.answer ?? '';
    final isCorrect = q.selectedOption == 0;
    final theme = Theme.of(context);

    if (isAnswered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Text(
                  '你的答案：',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fillAnswer.isEmpty ? '（未作答）' : widget.fillAnswer,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.red,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.error,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCorrect
                        ? '✅ 回答正确！'
                        : '❌ 回答错误，正确答案：$correctAnswer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: _textFieldKey,
                controller: _fillController,
                decoration: const InputDecoration(
                  hintText: '请输入答案...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                onChanged: (value) {
                  widget.onFillChanged(value);
                },
                onSubmitted: (value) {
                  _submitFillAnswer(context);
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _submitFillAnswer(context),
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
          '提示：输入答案后点击"确认"',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _submitFillAnswer(BuildContext context) {
    if (_fillController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入答案'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final userAnswer = _fillController.text.trim();
    final q = widget.question;
    final correctAnswer = q.answer ?? '';
    final isCorrect = userAnswer == correctAnswer.trim();

    if (widget.onAnswerSelected != null) {
      widget.onAnswerSelected!(q, isCorrect);
    } else {
      context.read<QuizBloc>().add(SelectAnswer(isCorrect ? 0 : 1));
    }
  }
}