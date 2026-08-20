import 'package:flutter/material.dart';
import '../../data/models/tower_model.dart';

class TowerNodeDetailDialog extends StatelessWidget {
  final TowerNodeType type;
  final String nodeName;
  final String description;
  final VoidCallback onConfirm;

  const TowerNodeDetailDialog({
    super.key,
    required this.type,
    required this.nodeName,
    required this.description,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return AlertDialog(
      backgroundColor: Colors.deepPurple.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5), width: 2),
      ),
      title: Row(
        children: [
          Text(_getIcon(), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Text(
            nodeName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      content: Text(
        description,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white70,
          height: 1.6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
          child: const Text('跳过'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          child: const Text('进入'),
        ),
      ],
    );
  }

  String _getIcon() {
    switch (type) {
      case TowerNodeType.normal: return '⚔️';
      case TowerNodeType.elite: return '💀';
      case TowerNodeType.boss: return '👑';
      case TowerNodeType.rest: return '⛺';
      case TowerNodeType.event: return '❓';
      case TowerNodeType.treasure: return '🎁';
      case TowerNodeType.trap: return '⚠️';
      case TowerNodeType.shop: return '🏪';
    }
  }

  Color _getColor() {
    switch (type) {
      case TowerNodeType.normal: return Colors.blue;
      case TowerNodeType.elite: return Colors.deepPurple;
      case TowerNodeType.boss: return Colors.red;
      case TowerNodeType.rest: return Colors.green;
      case TowerNodeType.event: return Colors.orange;
      case TowerNodeType.treasure: return Colors.amber;
      case TowerNodeType.trap: return Colors.redAccent;
      case TowerNodeType.shop: return Colors.cyan;
    }
  }
}