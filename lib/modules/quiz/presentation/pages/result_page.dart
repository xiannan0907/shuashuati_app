import 'package:flutter/material.dart';

import '../../data/models/question_model.dart';

class ResultPage extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final List<Question> wrongQuestions;
  final VoidCallback onRetry;
  final VoidCallback? onClearFill;

  const ResultPage({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.wrongQuestions,
    required this.onRetry,
    this.onClearFill,
  });

  @override
  Widget build(BuildContext context) {
    final wrongCount = wrongQuestions.length;
    final percentage = totalCount > 0 ? (correctCount / totalCount * 100).toInt() : 0;
    final isPass = percentage >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 答题结果'),
        backgroundColor: isPass ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('✅ 正确', correctCount, Colors.green),
                        _buildStatItem('❌ 错误', wrongCount, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: totalCount > 0 ? correctCount / totalCount : 0,
                            backgroundColor: Colors.grey.shade200,
                            color: isPass ? Colors.green : Colors.orange,
                            strokeWidth: 10,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '正确率',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPass ? '🎉 恭喜通过！' : '💪 继续加油！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPass ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '📖 错题列表',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: wrongCount > 0 ? Colors.red : Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  '共 $wrongCount 题',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: wrongCount == 0
                  ? Center(
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
                      '🎊 全部正确，太棒了！',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '没有错题需要复习',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: wrongQuestions.length,
                itemBuilder: (context, index) {
                  final q = wrongQuestions[index];
                  final userAnswer = q.selectedOption ?? -1;
                  final correctAnswer = q.correctIndex;

                  // 检测题型
                  final bool isJudge = q.options.length == 2 &&
                      q.options.contains('正确') &&
                      q.options.contains('错误');
                  final bool isFill = q.options.length == 1 &&
                      q.options.first.contains('填空');

                  String userDisplay;
                  String correctDisplay;

                  if (isFill) {
                    userDisplay = userAnswer == 0 ? (q.answer ?? '未作答') : '未作答';
                    correctDisplay = q.answer ?? '（未设置答案）';
                  } else if (isJudge) {
                    userDisplay = userAnswer == 0 ? '正确' : (userAnswer == 1 ? '错误' : '未作答');
                    correctDisplay = correctAnswer == 0 ? '正确' : '错误';
                  } else {
                    userDisplay = userAnswer >= 0 ? String.fromCharCode(65 + userAnswer) : '未作答';
                    correctDisplay = String.fromCharCode(65 + correctAnswer);
                  }

                  final questionNumber = index + 1;

                  // ✅ 直接使用 q.content，不再额外清理（避免过度过滤）
                  // 但为了安全，移除已知乱码
                  final displayContent = _cleanDisplayContent(q.content);

                  // 题型标签
                  String typeLabel = isJudge ? '判断题' : (isFill ? '填空题' : '选择题');
                  Color typeColor = isJudge
                      ? Colors.purple.shade700
                      : (isFill ? Colors.orange.shade700 : Colors.green.shade700);
                  Color typeBgColor = isJudge
                      ? Colors.purple.shade100
                      : (isFill ? Colors.orange.shade100 : Colors.green.shade100);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '第 $questionNumber 题',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: typeColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Flexible(
                                child: Text(
                                  '你的答案：$userDisplay',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '正确：$correctDisplay',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // ✅ 显示题目内容
                          if (displayContent.isNotEmpty)
                            Text(
                              displayContent,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              '（题目内容为空）',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          const SizedBox(height: 4),
                          // 显示选项
                          if (isFill) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '📝 填空题',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ] else ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: q.options.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final opt = entry.value;
                                final letter = String.fromCharCode(65 + idx);
                                final isUser = idx == userAnswer;
                                final isCorrectAnswer = idx == correctAnswer;

                                String displayOpt = opt;
                                if (isJudge && idx == 0 && opt == '正确') {
                                  displayOpt = '✅ 正确';
                                } else if (isJudge && idx == 1 && opt == '错误') {
                                  displayOpt = '❌ 错误';
                                }

                                Color? bgColor;
                                if (isUser && idx != correctAnswer) {
                                  bgColor = Colors.red.shade100;
                                } else if (isCorrectAnswer) {
                                  bgColor = Colors.green.shade100;
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isJudge ? displayOpt : '$letter. $opt',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUser && idx != correctAnswer
                                          ? Colors.red.shade700
                                          : (isCorrectAnswer
                                          ? Colors.green.shade700
                                          : Colors.grey),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('返回题库'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onClearFill?.call();
                        onRetry();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('🔄 重新挑战'),
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

  // ✅ 只移除已知乱码，保留正常内容
  String _cleanDisplayContent(String content) {
    if (content.isEmpty) return content;

    // 只移除已知的乱码模式
    final patternsToRemove = [
      RegExp(r'HIGH\s+COMFORTED\s+BY\s+[0-9.]+\s+PIXELS', caseSensitive: false),
      RegExp(r'RICH\s+TEXT\s+DIMENSION\s+BY\s+[0-9.]+\s+PIXELS', caseSensitive: false),
      RegExp(r'[0-9.]+\s+PIXELS', caseSensitive: false),
      RegExp(r'[A-Z]{2,}\s+[A-Z]{2,}\s+[A-Z]{2,}', caseSensitive: false),
      RegExp(r'[A-Z]{2,}\s+[0-9.]+', caseSensitive: false),
    ];

    String cleaned = content;
    for (var pattern in patternsToRemove) {
      cleaned = cleaned.replaceAll(pattern, '');
    }

    // 去除多余空格
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 如果清理后只剩短内容，返回原文（可能原文就是短的）
    if (cleaned.length < 2 && content.length > 2) {
      return content;
    }

    return cleaned;
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}