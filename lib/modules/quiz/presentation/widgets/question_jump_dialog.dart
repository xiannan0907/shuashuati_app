import 'package:flutter/material.dart';
import '../../data/models/question_model.dart';

class QuestionJumpDialog extends StatelessWidget {
  final List<Question> questions;
  final int currentIndex;
  final Function(int) onJump;

  const QuestionJumpDialog({
    super.key,
    required this.questions,
    required this.currentIndex,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final answeredCount = questions.where((q) => q.isAnsweredValue).length;
    final correctCount = questions
        .where((q) => q.isAnsweredValue && q.selectedOption == q.correctIndex)
        .length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📖 跳转题目 (${questions.length} 题)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip('已答', answeredCount, Colors.green),
                const SizedBox(width: 8),
                _buildStatChip('未答', questions.length - answeredCount, Colors.orange),
                const SizedBox(width: 8),
                _buildStatChip('正确', correctCount, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final isCurrent = index == currentIndex;
                  final isAnswered = q.isAnsweredValue;
                  final isCorrect = isAnswered && q.selectedOption == q.correctIndex;

                  final isJudge = q.options.length == 2 &&
                      q.options.contains('正确') &&
                      q.options.contains('错误');
                  final isFill = q.options.length == 1 &&
                      q.options.first.contains('填空');

                  return _buildQuestionItem(
                    context,
                    index: index,
                    question: q,
                    isCurrent: isCurrent,
                    isAnswered: isAnswered,
                    isCorrect: isCorrect,
                    isJudge: isJudge,
                    isFill: isFill,
                    onTap: () {
                      Navigator.pop(context);
                      onJump(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuestionItem(
      BuildContext context, {
        required int index,
        required Question question,
        required bool isCurrent,
        required bool isAnswered,
        required bool isCorrect,
        required bool isJudge,
        required bool isFill,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 增加预览长度到50字符
    String contentPreview = question.content;
    if (contentPreview.length > 50) {
      contentPreview = '${contentPreview.substring(0, 50)}...';
    }

    // 构建选项/答案预览
    String optionsPreview = '';
    if (isFill) {
      // 填空题：显示正确答案
      if (question.answer != null && question.answer!.isNotEmpty) {
        optionsPreview = '📝 答案：${question.answer}';
      } else {
        optionsPreview = '📝 （填空题）';
      }
    } else if (isJudge) {
      optionsPreview = '⚖️ 正确 / 错误';
    } else {
      // 选择题：显示前两个选项
      final List<String> previews = [];
      for (int i = 0; i < question.options.length && i < 2; i++) {
        final opt = question.options[i];
        final letter = String.fromCharCode(65 + i);
        final text = opt.length > 12 ? '${opt.substring(0, 12)}...' : opt;
        previews.add('$letter.$text');
      }
      if (question.options.length > 2) {
        previews.add('...');
      }
      optionsPreview = previews.join('  ');
    }

    // 状态图标
    IconData? statusIcon;
    Color? statusColor;
    if (isCurrent) {
      statusIcon = Icons.arrow_forward_ios;
      statusColor = Colors.blue;
    } else if (isAnswered) {
      statusIcon = isCorrect ? Icons.check_circle : Icons.cancel;
      statusColor = isCorrect ? Colors.green : Colors.red;
    } else {
      statusIcon = Icons.circle_outlined;
      statusColor = Colors.grey.shade400;
    }

    String typeLabel = isJudge ? '判断' : (isFill ? '填空' : '选择');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isCurrent
            ? (isDark ? Colors.blue.withValues(alpha: 0.12) : Colors.blue.shade50)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 题号
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.blue
                        : isAnswered
                        ? (isCorrect
                              ? (isDark
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.green.shade100)
                              : (isDark
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.red.shade100))
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? Colors.white
                          : isAnswered
                          ? (isCorrect
                                ? (isDark
                                      ? Colors.green.shade300
                                      : Colors.green.shade700)
                                : (isDark ? Colors.red.shade300 : Colors.red.shade700))
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 题目信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contentPreview,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                color: isCurrent
                                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade800)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isJudge
                                  ? (isDark
                                        ? Colors.purple.withValues(alpha: 0.18)
                                        : Colors.purple.shade100)
                                  : (isFill
                                        ? (isDark
                                              ? Colors.orange.withValues(alpha: 0.18)
                                              : Colors.orange.shade100)
                                        : (isDark
                                              ? Colors.green.withValues(alpha: 0.18)
                                              : Colors.green.shade100)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isJudge
                                    ? (isDark
                                          ? Colors.purple.shade300
                                          : Colors.purple.shade700)
                                    : (isFill
                                          ? (isDark
                                                ? Colors.orange.shade300
                                                : Colors.orange.shade700)
                                          : (isDark
                                                ? Colors.green.shade300
                                                : Colors.green.shade700)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        optionsPreview,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 状态图标
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 4),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '当前',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}