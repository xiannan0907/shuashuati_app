import 'package:flutter/material.dart';

import '../../data/models/monster_model.dart';

/// 战斗怪物信息卡片
class PortalbornBattleMonster extends StatelessWidget {
  final MonsterInstance monster;
  final bool isPlayerTurn;

  const PortalbornBattleMonster({
    super.key,
    required this.monster,
    required this.isPlayerTurn,
  });

  @override
  Widget build(BuildContext context) {
    final hpPercent = monster.hpPercent;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0d0d1a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 怪物名称 + Boss标签
          Row(
            children: [
              Text(
                monster.emoji,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          monster.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (monster.isBoss) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFffaa33), Color(0xFFff6600)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BOSS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        // 回合状态
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPlayerTurn
                                ? const Color(0xFF00ff88).withValues(alpha: 0.2)
                                : const Color(0xFFffaa33).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isPlayerTurn
                                  ? const Color(0xFF00ff88).withValues(alpha: 0.3)
                                  : const Color(0xFFffaa33).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isPlayerTurn ? '你的回合' : '等待中...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isPlayerTurn
                                  ? const Color(0xFF00ff88)
                                  : const Color(0xFFffaa33),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 怪物描述
                    Text(
                      monster.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8888aa),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // HP条
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'HP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8888aa),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2a2a3a),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: hpPercent,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: hpPercent > 0.5
                                    ? const [
                                  Color(0xFF00ff88),
                                  Color(0xFF44ffaa)
                                ]
                                    : hpPercent > 0.25
                                    ? const [
                                  Color(0xFFffaa33),
                                  Color(0xFFff8800)
                                ]
                                    : const [
                                  Color(0xFFff3355),
                                  Color(0xFFcc0033)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${monster.currentHp}/${monster.template.baseHp}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8888aa),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 怪物标签
          if (monster.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: monster.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTagColor(tag).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getTagColor(tag).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getTagDisplay(tag),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getTagColor(tag),
                    ),
                  ),
                );
              }).toList(),
            ),

          // 特殊技能提示
          if (monster.specialAbility != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.flash_on,
                  size: 14,
                  color: Color(0xFFffaa33),
                ),
                const SizedBox(width: 4),
                Text(
                  '⚡ ${monster.specialAbility} (CD: ${monster.abilityTimer})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFffaa33),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'boss':
        return const Color(0xFFff3355);
      case 'undead':
        return const Color(0xFFaa55ff);
      case 'beast':
        return const Color(0xFF44aaff);
      case 'magical':
        return const Color(0xFFaa55ff);
      case 'elite':
        return const Color(0xFFffaa33);
      case 'dragon':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF8888aa);
    }
  }

  String _getTagDisplay(String tag) {
    const map = {
      'boss': '👑 Boss',
      'undead': '💀 亡灵',
      'beast': '🐾 野兽',
      'magical': '🔮 魔法',
      'elite': '⭐ 精英',
      'dragon': '🐉 龙族',
    };
    return map[tag] ?? tag;
  }
}