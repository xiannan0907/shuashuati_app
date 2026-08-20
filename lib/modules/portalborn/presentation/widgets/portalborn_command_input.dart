import 'package:flutter/material.dart';

/// 命令输入框
class PortalbornCommandInput extends StatefulWidget {
  final ValueChanged<String> onCommand;

  const PortalbornCommandInput({
    super.key,
    required this.onCommand,
  });

  @override
  State<PortalbornCommandInput> createState() =>
      _PortalbornCommandInputState();
}

class _PortalbornCommandInputState extends State<PortalbornCommandInput> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _history = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0a0a0f),
      child: Row(
        children: [
          // 提示符
          const Text(
            '> ',
            style: TextStyle(
              color: Color(0xFF00ff88),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                color: Color(0xFFc8d0d8),
                fontSize: 16,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: '输入命令...',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: _submitCommand,
              onTap: () {
                // 点击输入框时自动聚焦
                FocusScope.of(context).requestFocus();
              },
            ),
          ),
          // 发送按钮
          IconButton(
            onPressed: () => _submitCommand(_controller.text),
            icon: const Icon(
              Icons.send,
              color: Color(0xFF00ff88),
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
          ),
        ],
      ),
    );
  }

  void _submitCommand(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 添加到历史
    if (_history.isEmpty || _history.last != trimmed) {
      _history.add(trimmed);
    }

    // 清空输入
    _controller.clear();

    // 提交命令
    widget.onCommand(trimmed);
  }
}