import 'package:flutter/material.dart';

/// 快捷操作按钮
class PortalbornQuickButtons extends StatelessWidget {
  final VoidCallback onAttack;
  final VoidCallback onSearch;
  final VoidCallback onInventory;
  final VoidCallback onHelp;

  const PortalbornQuickButtons({
    super.key,
    required this.onAttack,
    required this.onSearch,
    required this.onInventory,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0d0d1a),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickButton(
            icon: Icons.sports_martial_arts,
            label: '攻击',
            onTap: onAttack,
            color: const Color(0xFFff3355),
          ),
          _QuickButton(
            icon: Icons.search,
            label: '搜索',
            onTap: onSearch,
            color: const Color(0xFF44aaff),
          ),
          _QuickButton(
            icon: Icons.backpack,
            label: '背包',
            onTap: onInventory,
            color: const Color(0xFFffaa33),
          ),
          _QuickButton(
            icon: Icons.help_outline,
            label: '帮助',
            onTap: onHelp,
            color: const Color(0xFF8888aa),
          ),
        ],
      ),
    );
  }
}

/// 快捷按钮
class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}