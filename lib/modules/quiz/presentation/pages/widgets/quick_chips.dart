import 'package:flutter/material.dart';

class QuickChips extends StatelessWidget {
  final int wrongCount;
  final VoidCallback onRefresh;

  const QuickChips({
    super.key,
    required this.wrongCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildChip(
            icon: Icons.auto_awesome,
            label: '示例',
            color: Colors.blue,
            onTap: () {
              // TODO: 跳转到示例导入
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            icon: Icons.architecture,
            label: '爬塔',
            color: Colors.deepPurple,
            onTap: () {
              // TODO: 跳转爬塔
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            icon: Icons.autorenew,
            label: '强化',
            color: Colors.purple,
            onTap: () {
              // TODO: 跳转强化练习
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            icon: Icons.error_outline,
            label: '错题集',
            color: Colors.red,
            badgeCount: wrongCount > 0 ? wrongCount : null,
            onTap: () {
              // TODO: 跳转错题集
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}