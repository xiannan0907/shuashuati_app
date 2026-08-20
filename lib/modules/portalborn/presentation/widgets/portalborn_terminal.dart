import 'package:flutter/material.dart';

/// 终端日志显示
class PortalbornTerminal extends StatelessWidget {
  final List<String> messages;
  final String? placeholder;
  final int maxLines;

  const PortalbornTerminal({
    super.key,
    required this.messages,
    this.placeholder,
    this.maxLines = 100,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isDark
          ? const Color(0xFF0a0a0f)
          : const Color(0xFFf5f3f0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 终端头部
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFff3355),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFffaa33),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF00ff88),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '终端',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                '📟 ${messages.length}条日志',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFF2a2a4a)),

          // 消息列表
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Text(
                placeholder ??
                    '🏰 欢迎来到传送门大厅\n输入 "help" 查看可用命令',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[messages.length - 1 - index];
                return _TerminalLine(
                  message: msg,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 终端单行
class _TerminalLine extends StatelessWidget {
  final String message;
  final bool isDark;

  const _TerminalLine({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 解析特殊前缀
    Color? textColor;
    String displayText = message;

    if (message.startsWith('❌')) {
      textColor = const Color(0xFFff3355);
    } else if (message.startsWith('✅') ||
        message.startsWith('🎉') ||
        message.startsWith('💚')) {
      textColor = const Color(0xFF00ff88);
    } else if (message.startsWith('⚔️') ||
        message.startsWith('💥') ||
        message.startsWith('💀')) {
      textColor = const Color(0xFFffaa33);
    } else if (message.startsWith('📖') || message.startsWith('💡')) {
      textColor = const Color(0xFF44aaff);
    } else if (message.startsWith('🪙') ||
        message.startsWith('🎁') ||
        message.startsWith('✨')) {
      textColor = const Color(0xFFaa55ff);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行号或提示符
          SizedBox(
            width: 20,
            child: Text(
              '>',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF00ff88) : const Color(0xFF008844),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 消息内容
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: textColor ?? (isDark ? const Color(0xFFc8d0d8) : const Color(0xFF1a1a2e)),
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}