import 'package:flutter/material.dart';

import '../../data/models/realm_model.dart';

/// 出口快捷按钮
class PortalbornExitButtons extends StatelessWidget {
  final List<Exit> exits;
  final ValueChanged<String> onExitTap;

  const PortalbornExitButtons({
    super.key,
    required this.exits,
    required this.onExitTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0d0d1a),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: exits.map((exit) {
          return _ExitButton(
            exit: exit,
            onTap: () => onExitTap(exit.direction),
          );
        }).toList(),
      ),
    );
  }
}

/// 单个出口按钮
class _ExitButton extends StatelessWidget {
  final Exit exit;
  final VoidCallback onTap;

  const _ExitButton({
    required this.exit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 方向图标
    IconData directionIcon;
    switch (exit.direction) {
      case 'north':
        directionIcon = Icons.arrow_upward;
        break;
      case 'south':
        directionIcon = Icons.arrow_downward;
        break;
      case 'east':
        directionIcon = Icons.arrow_forward;
        break;
      case 'west':
        directionIcon = Icons.arrow_back;
        break;
      case 'up':
        directionIcon = Icons.vertical_align_top;
        break;
      case 'down':
        directionIcon = Icons.vertical_align_bottom;
        break;
      case 'portal':
        directionIcon = Icons.launch;  // ✅ 改为存在的图标
        break;
      default:
        directionIcon = Icons.arrow_forward;
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(directionIcon, size: 16),
      label: Text(exit.displayName),
      style: ElevatedButton.styleFrom(
        backgroundColor: exit.direction == 'portal'
            ? const Color(0xFFaa55ff).withValues(alpha: 0.2)
            : const Color(0xFF141425),
        foregroundColor: exit.direction == 'portal'
            ? const Color(0xFFaa55ff)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: exit.direction == 'portal'
                ? const Color(0xFFaa55ff).withValues(alpha: 0.3)
                : Colors.grey[800]!,
          ),
        ),
        elevation: 0,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}