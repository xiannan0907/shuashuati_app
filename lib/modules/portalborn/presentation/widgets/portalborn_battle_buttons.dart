import 'package:flutter/material.dart';

/// 战斗快捷按钮
class PortalbornBattleButtons extends StatelessWidget {
  final VoidCallback onAttack;
  final VoidCallback onCastSpell;
  final VoidCallback onUsePotion;
  final VoidCallback onDefend;
  final VoidCallback onFlee;
  final bool isPlayerTurn;

  const PortalbornBattleButtons({
    super.key,
    required this.onAttack,
    required this.onCastSpell,
    required this.onUsePotion,
    required this.onDefend,
    required this.onFlee,
    required this.isPlayerTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF0d0d1a),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BattleButton(
            icon: Icons.sports_martial_arts,
            label: '攻击',
            onTap: isPlayerTurn ? onAttack : null,
            color: const Color(0xFFff3355),
          ),
          _BattleButton(
            icon: Icons.auto_awesome,
            label: '法术',
            onTap: isPlayerTurn ? onCastSpell : null,
            color: const Color(0xFFaa55ff),
          ),
          _BattleButton(
            icon: Icons.medication,
            label: '药水',
            onTap: isPlayerTurn ? onUsePotion : null,
            color: const Color(0xFF00ff88),
          ),
          _BattleButton(
            icon: Icons.shield,
            label: '防御',
            onTap: isPlayerTurn ? onDefend : null,
            color: const Color(0xFF44aaff),
          ),
          _BattleButton(
            icon: Icons.run_circle,
            label: '逃跑',
            onTap: isPlayerTurn ? onFlee : null,
            color: const Color(0xFFffaa33),
          ),
        ],
      ),
    );
  }
}

/// 战斗按钮
class _BattleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _BattleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isEnabled
              ? color.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? color.withOpacity(0.3)
                : Colors.grey[800]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey[600],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isEnabled ? color : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}