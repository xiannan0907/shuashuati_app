import 'package:flutter/material.dart';

/// 战斗日志
class PortalbornBattleLog extends StatelessWidget {
  final List<String> logs;

  const PortalbornBattleLog({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF0a0a0f),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 16,
                color: Color(0xFF8888aa),
              ),
              const SizedBox(width: 8),
              const Text(
                '战斗日志',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8888aa),
                ),
              ),
              const Spacer(),
              Text(
                '${logs.length} 条记录',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFF2a2a4a)),
          Expanded(
            child: logs.isEmpty
                ? Center(
              child: Text(
                '⚔️ 战斗开始！',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            )
                : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final msg = logs[logs.length - 1 - index];
                return _BattleLogLine(message: msg);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 战斗日志单行
class _BattleLogLine extends StatelessWidget {
  final String message;

  const _BattleLogLine({required this.message});

  @override
  Widget build(BuildContext context) {
    Color? textColor;
    String displayText = message;

    if (message.contains('暴击') || message.contains('💥')) {
      textColor = const Color(0xFFffaa33);
    } else if (message.contains('伤害') && message.contains('你')) {
      textColor = const Color(0xFFff3355);
    } else if (message.contains('伤害') && message.contains('造成')) {
      textColor = const Color(0xFF00ff88);
    } else if (message.contains('闪避') || message.contains('格挡')) {
      textColor = const Color(0xFF44aaff);
    } else if (message.contains('击败') || message.contains('胜利')) {
      textColor = const Color(0xFF00ff88);
    } else if (message.contains('死亡') || message.contains('击败了')) {
      textColor = const Color(0xFFff3355);
    } else if (message.contains('逃跑')) {
      textColor = const Color(0xFFffaa33);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '>',
              style: TextStyle(
                fontSize: 12,
                color: textColor ?? Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: textColor ?? Colors.grey[400],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}