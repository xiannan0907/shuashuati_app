import 'package:flutter/material.dart';

import '../../data/models/realm_model.dart';

/// 可互动物件列表
class PortalbornObjectList extends StatelessWidget {
  final List<InteractableObject> objects;
  final Function(String objectId, String action) onObjectTap;

  const PortalbornObjectList({
    super.key,
    required this.objects,
    required this.onObjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0d0d1a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📦 可互动物件',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8888aa),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: objects.map((obj) {
              return _ObjectChip(
                object: obj,
                onTap: (action) {
                  onObjectTap(obj.id, action);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 物件标签
class _ObjectChip extends StatelessWidget {
  final InteractableObject object;
  final Function(String action) onTap;

  const _ObjectChip({
    required this.object,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 主要操作（第一个动作）
    final primaryAction = object.actions.isNotEmpty ? object.actions.first : 'examine';

    return ActionChip(
      label: Text(
        object.name,
        style: const TextStyle(fontSize: 13),
      ),
      onPressed: () => onTap(primaryAction),
      backgroundColor: const Color(0xFF141425),
      side: BorderSide(color: Colors.grey[800]!),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      avatar: _getActionIcon(primaryAction),
    );
  }

  Widget _getActionIcon(String action) {
    IconData icon;
    switch (action) {
      case 'open':
        icon = Icons.open_in_new;
        break;
      case 'search':
        icon = Icons.search;
        break;
      case 'examine':
        icon = Icons.visibility;
        break;
      case 'take':
        icon = Icons.handshake;
        break;
      case 'drink':
        icon = Icons.local_drink;
        break;
      case 'pray':
        icon = Icons.church;
        break;
      default:
        icon = Icons.touch_app;
    }
    return Icon(icon, size: 16, color: const Color(0xFF8888aa));
  }
}