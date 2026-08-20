import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/bloc/portalborn_bloc.dart';
import '../../presentation/bloc/portalborn_event.dart';
import '../../presentation/bloc/portalborn_state.dart';
import '../../data/seed_data/recipes.dart';
import '../widgets/portalborn_status_bar.dart';

/// Portalborn 制作页面
class PortalbornCraftingPage extends StatelessWidget {
  const PortalbornCraftingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      appBar: AppBar(
        title: const Text('⚒️ 制作'),
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
            return _CraftingContent(
              character: state.character,
              materials: state.character.materials,
            );
          }

          return const Center(
            child: Text(
              '制作不可用',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

/// 制作内容
class _CraftingContent extends StatelessWidget {
  final dynamic character;
  final Map<String, int> materials;

  const _CraftingContent({
    required this.character,
    required this.materials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 状态栏
        PortalbornStatusBar(
          character: character,
          showStats: true,
        ),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),

        // 材料显示
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2,
                size: 16,
                color: Color(0xFFffaa33),
              ),
              const SizedBox(width: 8),
              const Text(
                '可用材料',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${materials.length} 种',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8888aa),
                ),
              ),
            ],
          ),
        ),

        // 材料标签
        if (materials.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: materials.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141425),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8888aa),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),

        // 配方列表
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '📜 可用配方',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: recipes.isEmpty
              ? Center(
            child: Text(
              '没有可用的配方',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final canCraft = _canCraft(recipe);
              return _RecipeCard(
                recipe: recipe,
                canCraft: canCraft,
                onCraft: () {
                  if (canCraft) {
                    context.read<PortalbornBloc>().add(
                      PortalbornCraftItem(recipe.id),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('制作中...'),
                        backgroundColor: Color(0xFF00ff88),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _canCraft(Recipe recipe) {
    for (final entry in recipe.materials.entries) {
      final available = materials[entry.key] ?? 0;
      if (available < entry.value) {
        return false;
      }
    }
    return true;
  }
}

/// 配方卡片
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool canCraft;
  final VoidCallback onCraft;

  const _RecipeCard({
    required this.recipe,
    required this.canCraft,
    required this.onCraft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canCraft
            ? const Color(0xFF00ff88).withValues(alpha: 0.05)
            : const Color(0xFF141425),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canCraft
              ? const Color(0xFF00ff88).withValues(alpha: 0.3)
              : Colors.grey[800]!,
        ),
      ),
      child: Row(
        children: [
          // 图标
          Text(
            recipe.emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: canCraft ? const Color(0xFF00ff88) : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recipe.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8888aa),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 材料需求
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: recipe.materials.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141425),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.grey[800]!,
                        ),
                      ),
                      child: Text(
                        '${entry.key} ×${entry.value}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 2),
                Text(
                  '🔧 需要: ${recipe.skillRequired}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8888aa),
                  ),
                ),
              ],
            ),
          ),

          // 制作按钮
          ElevatedButton(
            onPressed: canCraft ? onCraft : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canCraft
                  ? const Color(0xFF00ff88)
                  : Colors.grey[800],
              foregroundColor: canCraft ? Colors.black : Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[800],
            ),
            child: Text(
              canCraft ? '制作' : '材料不足',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: canCraft ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}