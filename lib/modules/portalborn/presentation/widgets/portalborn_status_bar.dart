import 'package:flutter/material.dart';

import '../../data/models/character_model.dart';

/// 角色状态栏
class PortalbornStatusBar extends StatelessWidget {
  final GameCharacter character;
  final bool showStats;

  const PortalbornStatusBar({
    super.key,
    required this.character,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF0d0d1a) : const Color(0xFFf0eee8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：名称 + 等级 + 职业 + 金币
          Row(
            children: [
              // 职业Emoji
              Text(
                _getClassEmoji(character.mainClass),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),

              // 名称
              Text(
                character.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),

              // 等级
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ff88).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv.${character.level}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00ff88),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 职业
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFaa55ff).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  character.mainClass,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFaa55ff),
                  ),
                ),
              ),
              const Spacer(),

              // 金币
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 18,
                    color: Color(0xFFffaa33),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${character.gold}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 第二行：HP + EXP 进度条
          Row(
            children: [
              // HP
              Expanded(
                flex: 4,
                child: _ProgressBar(
                  label: 'HP',
                  current: character.currentHp,
                  max: character.maxHp,
                  color: character.hpPercent > 0.3
                      ? const Color(0xFF00ff88)
                      : const Color(0xFFff3355),
                ),
              ),
              const SizedBox(width: 12),

              // EXP
              Expanded(
                flex: 4,
                child: _ProgressBar(
                  label: 'EXP',
                  current: character.exp,
                  max: character.level * 15 + 10,
                  color: const Color(0xFF44aaff),
                ),
              ),
            ],
          ),

          // 第三行：属性
          if (showStats) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                _StatChip(label: 'STR', value: character.strength),
                _StatChip(label: 'DEX', value: character.dexterity),
                _StatChip(label: 'INT', value: character.intelligence),
                _StatChip(label: 'CON', value: character.constitution),
                const Spacer(),
                if (character.availablePoints > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFffaa33).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFffaa33).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '⭐ +${character.availablePoints}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFffaa33),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getClassEmoji(String className) {
    const map = {
      'warrior': '⚔️',
      'mage': '🧙',
      'rogue': '🗡️',
      'priest': '✨',
      'ranger': '🏹',
    };
    return map[className] ?? '🎮';
  }
}

/// 进度条组件
class _ProgressBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              // 背景
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2a2a3a)
                      : const Color(0xFFe0dcd8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // 前景
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 50,
          child: Text(
            '$current/$max',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}

/// 属性标签
// 当前显示 STR/DEX/INT/CON
class _StatChip extends StatelessWidget {
  final String label;   // 接收 "STR"、"DEX" 等
  final int value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 把英文缩写映射成中文
    final displayName = {
      'STR': '力量',
      'DEX': '敏捷',
      'INT': '智力',
      'CON': '体质',
    }[label] ?? label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141425),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2a2a4a)),
      ),
      child: Text(
        '$displayName $value',  // ✅ 显示 "力量 8" 而不是 "STR 8"
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF8888aa),
        ),
      ),
    );
  }
}