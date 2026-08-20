import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/bloc/portalborn_bloc.dart';
import '../../presentation/bloc/portalborn_event.dart';
import '../../presentation/bloc/portalborn_state.dart';
import '../../data/models/item_model.dart';
import '../widgets/portalborn_status_bar.dart';

/// Portalborn 背包页面
class PortalbornInventoryPage extends StatelessWidget {
  const PortalbornInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      appBar: AppBar(
        title: const Text('📦 背包'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '关闭',
              style: TextStyle(color: Color(0xFF8888aa)),
            ),
          ),
        ],
      ),
      body: BlocBuilder<PortalbornBloc, PortalbornState>(
        builder: (context, state) {
          if (state is PortalbornHub) {
            return _InventoryContent(
              character: state.character,
              inventory: state.inventory,
            );
          }

          if (state is PortalbornExploring) {
            return _InventoryContent(
              character: state.character,
              inventory: state.inventory,
            );
          }

          return const Center(
            child: Text(
              '背包不可用',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

/// 背包内容
class _InventoryContent extends StatefulWidget {
  final dynamic character;
  final List<GameItem> inventory;

  const _InventoryContent({
    required this.character,
    required this.inventory,
  });

  @override
  State<_InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<_InventoryContent> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return Column(
      children: [
        PortalbornStatusBar(
          character: widget.character,
          showStats: true,
        ),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),

        // 筛选栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: '全部',
                  isSelected: _filterType == 'all',
                  onTap: () => setState(() => _filterType = 'all'),
                ),
                _FilterChip(
                  label: '⚔️ 武器',
                  isSelected: _filterType == 'weapon',
                  onTap: () => setState(() => _filterType = 'weapon'),
                ),
                _FilterChip(
                  label: '🛡️ 护甲',
                  isSelected: _filterType == 'armor',
                  onTap: () => setState(() => _filterType = 'armor'),
                ),
                _FilterChip(
                  label: '💍 饰品',
                  isSelected: _filterType == 'accessory',
                  onTap: () => setState(() => _filterType = 'accessory'),
                ),
                _FilterChip(
                  label: '🧪 药水',
                  isSelected: _filterType == 'potion',
                  onTap: () => setState(() => _filterType = 'potion'),
                ),
                _FilterChip(
                  label: '🔧 材料',
                  isSelected: _filterType == 'material',
                  onTap: () => setState(() => _filterType = 'material'),
                ),
                _FilterChip(
                  label: '📜 任务',
                  isSelected: _filterType == 'quest',
                  onTap: () => setState(() => _filterType = 'quest'),
                ),
              ],
            ),
          ),
        ),

        // 物品数量
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '📦 ${filteredItems.length}/${widget.inventory.length} 件物品',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8888aa),
                ),
              ),
              const Spacer(),
              if (widget.inventory.length >= 20)
                const Text(
                  '⚠️ 背包已满',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFff3355),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 物品列表
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
            child: Text(
              _filterType == 'all' ? '背包为空' : '没有此类物品',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _InventoryItemCard(
                item: item,
                onUse: () => _useItem(context, item),
                onEquip: () => _equipItem(context, item),
                onDrop: () => _dropItem(context, item),
              );
            },
          ),
        ),
      ],
    );
  }

  List<GameItem> _getFilteredItems() {
    var items = widget.inventory;
    if (_filterType != 'all') {
      items = items.where((item) => item.type == _filterType).toList();
    }
    return items;
  }

  void _useItem(BuildContext context, GameItem item) {
    if (item.type == 'potion') {
      context.read<PortalbornBloc>().add(
        PortalbornUsePotion(item.id),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('使用了 ${item.name}'),
          backgroundColor: const Color(0xFF00ff88),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} 无法直接使用'),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  void _equipItem(BuildContext context, GameItem item) {
    if (!item.isEquippable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该物品无法装备'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    context.read<PortalbornBloc>().add(
      PortalbornEquipItem(item.id),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('装备了 ${item.name}'),
        backgroundColor: const Color(0xFF00ff88),
      ),
    );
  }

  void _dropItem(BuildContext context, GameItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认丢弃'),
        content: Text('确定要丢弃 ${item.name} 吗？'),
        backgroundColor: const Color(0xFF141425),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<PortalbornBloc>().add(
                PortalbornDropItem(item.id),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('丢弃了 ${item.name}'),
                  backgroundColor: Colors.grey[800],
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFff3355),
            ),
            child: const Text('丢弃'),
          ),
        ],
      ),
    );
  }
}

/// 筛选标签
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00ff88).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF00ff88) : Colors.grey[800]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF00ff88) : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}

/// 物品卡片
class _InventoryItemCard extends StatelessWidget {
  final GameItem item;
  final VoidCallback onUse;
  final VoidCallback onEquip;
  final VoidCallback onDrop;

  const _InventoryItemCard({
    required this.item,
    required this.onUse,
    required this.onEquip,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final isEquipped = item.isEquipped;
    final isEquippable = item.isEquippable;
    final isConsumable = item.isConsumable;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEquipped
            ? const Color(0xFF00ff88).withValues(alpha: 0.1)
            : const Color(0xFF141425),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEquipped
              ? const Color(0xFF00ff88).withValues(alpha: 0.3)
              : Colors.grey[800]!,
        ),
      ),
      child: Row(
        children: [
          Text(
            item.emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                        color: isEquipped ? const Color(0xFF00ff88) : Colors.white,
                      ),
                    ),
                    if (isEquipped) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00ff88).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '已装备',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF00ff88),
                          ),
                        ),
                      ),
                    ],
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFffaa33).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '×${item.quantity}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFffaa33),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8888aa),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.atkBonus > 0 || item.defBonus > 0)
                  Text(
                    '⚔️ +${item.atkBonus}  🛡️ +${item.defBonus}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF44aaff),
                    ),
                  ),
                if (item.healAmount > 0)
                  Text(
                    '💚 恢复 ${item.healAmount} HP',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00ff88),
                    ),
                  ),
              ],
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConsumable)
                _ActionButton(
                  label: '使用',
                  onTap: onUse,
                  color: const Color(0xFF00ff88),
                ),
              if (isEquippable && !isEquipped)
                _ActionButton(
                  label: '装备',
                  onTap: onEquip,
                  color: const Color(0xFF44aaff),
                ),
              if (isEquippable && isEquipped)
                _ActionButton(
                  label: '卸下',
                  onTap: () {
                    context.read<PortalbornBloc>().add(
                      PortalbornUnequipItem(item.type),
                    );
                  },
                  color: const Color(0xFFffaa33),
                ),
              _ActionButton(
                label: '丢弃',
                onTap: onDrop,
                color: const Color(0xFFff3355),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}