import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final VoidCallback onRetry; // 无参回调，由外部处理关闭

  const ResultDialog({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (correctCount / totalCount * 100).toInt();
    final isPass = percentage >= 60;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            isPass ? Icons.celebration : Icons.sentiment_dissatisfied,
            color: isPass ? Colors.green : Colors.orange,
            size: 30,
          ),
          const SizedBox(width: 8),
          Text(isPass ? '🎉 太棒了！' : '💪 继续加油！'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: correctCount / totalCount,
                  backgroundColor: Colors.grey.shade200,
                  color: isPass ? Colors.green : Colors.orange,
                  strokeWidth: 10,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '正确：$correctCount 题',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '错误：${totalCount - correctCount} 题',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '共 $totalCount 题',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        ElevatedButton(
          onPressed: () {
            // 先关闭对话框，再执行重试
            Navigator.pop(context);
            onRetry();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('🔄 重新挑战'),
        ),
      ],
    );
  }
}