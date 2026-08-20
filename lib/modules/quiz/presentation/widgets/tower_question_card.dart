import 'package:flutter/material.dart';

import '../../data/models/question_model.dart';

class TowerQuestionCard extends StatefulWidget {
  final Question question;
  final int currentIndex;
  final int total;
  final String fillAnswer;
  final ValueChanged<String> onFillChanged;
  final Function(Question, bool) onAnswerSelected;

  // ✅ 新增：独立状态，不依赖 question 对象
  final bool isAnswered;
  final int? selectedOption;

  const TowerQuestionCard({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.total,
    required this.fillAnswer,
    required this.onFillChanged,
    required this.onAnswerSelected,
    this.isAnswered = false,
    this.selectedOption,
  });

  @override
  State<TowerQuestionCard> createState() => _TowerQuestionCardState();
}

class _TowerQuestionCardState extends State<TowerQuestionCard> {
  late TextEditingController _fillController;
  late UniqueKey _textFieldKey;

  final List<String> _monsterIcons = ['👹', '🐉', '🧛', '👾', '🐺', '🦅', '🐗', '🦁', '🐙', '🦇'];
  final List<String> _monsterHps = ['❤️❤️❤️', '❤️❤️', '❤️❤️❤️❤️', '❤️', '❤️❤️❤️❤️❤️'];
  final List<String> _optionIcons = ['🗡️', '⚔️', '🛡️', '💎'];

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _fillController = TextEditingController(text: widget.fillAnswer);
    _textFieldKey = UniqueKey();
  }

  @override
  void didUpdateWidget(TowerQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _fillController.dispose();
      _initController();
      setState(() {});
    } else {
      if (_fillController.text != widget.fillAnswer) {
        _fillController.text = widget.fillAnswer;
      }
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final theme = Theme.of(context);

    final isFill = q.options.length == 1 && q.options.first.contains('填空');
    final displayContent = q.content.isNotEmpty ? q.content : '（题目内容为空）';
    final monsterIcon = _monsterIcons[widget.currentIndex % _monsterIcons.length];
    final monsterHp = _monsterHps[widget.currentIndex % _monsterHps.length];

    // ✅ 使用父组件传入的状态，而不是从 question 读取


    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade200, width: 1),
      ),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(monsterIcon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 10),
                Text(
                  '⚔️ 战斗！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monsterHp,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Text(
              displayContent,
              style: TextStyle(
                fontSize: 17,
                height: 1.6,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            if (isFill) ...[
              _buildFillInput(context),
            ],

            if (!isFill) ...[
              ..._buildChoiceOptions(context),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChoiceOptions(BuildContext context) {
    final q = widget.question;
    final isJudge = q.options.length == 2 &&
        q.options.contains('正确') &&
        q.options.contains('错误');
    final theme = Theme.of(context);

    // ✅ 使用父组件传入的状态
    final isAnswered = widget.isAnswered;
    final selectedOption = widget.selectedOption;

    return q.options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final isSelected = selectedOption == index;
      final isCorrect = index == q.correctIndex;

      Color? tileColor;
      if (isAnswered) {
        if (isCorrect) {
          tileColor = Colors.green.shade100;
        } else if (isSelected && !isCorrect) {
          tileColor = Colors.red.shade100;
        }
      } else if (isSelected) {
        tileColor = Colors.deepPurple.withValues(alpha: 0.1);
      }

      String displayOption = option;
      if (isJudge && index == 0 && option == '正确') {
        displayOption = '✅ 正确';
      } else if (isJudge && index == 1 && option == '错误') {
        displayOption = '❌ 错误';
      }

      final optionIcon = _optionIcons[index % _optionIcons.length];

      return Material(
        borderRadius: BorderRadius.circular(8),
        color: tileColor,
        child: ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.deepPurple : Colors.deepPurple.shade100,
            ),
            child: Center(
              child: Text(
                optionIcon,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.deepPurple.shade700,
                ),
              ),
            ),
          ),
          title: Text(
            displayOption,
            style: TextStyle(
              fontSize: 15,
              color: isAnswered
                  ? (isCorrect
                  ? Colors.green.shade700
                  : (isSelected
                  ? Colors.red.shade700
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7)))
                  : theme.colorScheme.onSurface,
              fontWeight: isCorrect && isAnswered ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            if (isAnswered) return;
            // ✅ 传入当前选项索引，父组件会保存到独立状态
            widget.onAnswerSelected(q, index == q.correctIndex);
          },
          enabled: !isAnswered,
        ),
      );
    }).toList();
  }

  Widget _buildFillInput(BuildContext context) {
    final q = widget.question;
    final isAnswered = widget.isAnswered;
    final isCorrect = widget.selectedOption == 0;
    final correctAnswer = q.answer ?? '';
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
                  '⚔️ 你的攻击：',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fillAnswer.isEmpty ? '（未攻击）' : widget.fillAnswer,
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
                        ? '💥 击败了怪物！'
                        : '💔 被怪物击中了！\n🗡️ 正确答案：$correctAnswer',
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
                  hintText: '⚔️ 输入攻击...',
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
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('⚔️ 攻击'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '💡 输入答案后点击"攻击"',
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
          content: Text('请输入答案再攻击！'),
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

    widget.onAnswerSelected(q, isCorrect);
  }
}