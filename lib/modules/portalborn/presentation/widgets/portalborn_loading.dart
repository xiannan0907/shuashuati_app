import 'package:flutter/material.dart';

/// 加载动画组件
class PortalbornLoadingWidget extends StatelessWidget {
  final String? message;

  const PortalbornLoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ff88)),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8888aa),
              ),
            ),
          ],
        ],
      ),
    );
  }
}