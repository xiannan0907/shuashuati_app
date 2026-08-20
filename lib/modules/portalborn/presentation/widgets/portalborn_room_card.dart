import 'package:flutter/material.dart';

import '../../data/models/realm_model.dart';
import '../../data/models/monster_model.dart';

/// 房间信息卡片
class PortalbornRoomCard extends StatelessWidget {
  final Room room;
  final bool isInBattle;
  final MonsterInstance? monster;

  const PortalbornRoomCard({
    super.key,
    required this.room,
    required this.isInBattle,
    this.monster,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark
          ? const Color(0xFF0d0d1a)
          : const Color(0xFFf0eee8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 房间名 + 标签
          Row(
            children: [
              Text(
                '📍 ${room.name}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              if (room.isSafe)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ff88).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '安全区',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00ff88),
                    ),
                  ),
                ),
              if (room.isDark)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFaa55ff).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🌑 黑暗',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFaa55ff),
                    ),
                  ),
                ),
              if (room.tags.contains('treasure'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFffaa33).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '💰 宝藏',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFffaa33),
                    ),
                  ),
                ),
              if (room.tags.contains('boss_room'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFff3355).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '👑 Boss',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFff3355),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 房间描述
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                room.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? const Color(0xFFc8d0d8) : const Color(0xFF333344),
                ),
              ),
            ),
          ),

          // 怪物信息（如果有）
          if (isInBattle && monster != null) ...[
            const Divider(height: 16, color: Color(0xFF2a2a4a)),
            _MonsterInfo(
              monster: monster!,
              isInBattle: isInBattle,
            ),
          ],
        ],
      ),
    );
  }
}

/// 怪物信息
class _MonsterInfo extends StatelessWidget {
  final MonsterInstance monster;
  final bool isInBattle;

  const _MonsterInfo({
    required this.monster,
    required this.isInBattle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFff3355).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFff3355).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            monster.emoji,
            style: const TextStyle(fontSize: 32),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (monster.isBoss)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFffaa33),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BOSS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  monster.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8888aa),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // HP条
                Row(
                  children: [
                    const Text(
                      'HP ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8888aa),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2a2a3a),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: monster.hpPercent,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: monster.hpPercent > 0.3
                                    ? const Color(0xFF00ff88)
                                    : const Color(0xFFff3355),
                                borderRadius: BorderRadius.circular(4),
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
                        fontSize: 11,
                        color: Color(0xFF8888aa),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}