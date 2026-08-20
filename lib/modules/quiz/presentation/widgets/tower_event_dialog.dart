import 'package:flutter/material.dart';
import '../../data/models/tower_model.dart';

class TowerEventDialog extends StatelessWidget {
  final TowerProgress progress;
  final VoidCallback onComplete;

  const TowerEventDialog({
    super.key,
    required this.progress,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final events = [
      {'icon': '🧙', 'title': '神秘商人', 'desc': '你遇到一位神秘商人，他愿意用一瓶生命药水换取你的一件道具。', 'reward': '🧪 +1 生命药水'},
      {'icon': '🏛️', 'title': '古老神殿', 'desc': '你发现了一座古老的神殿，在里面休息可以恢复生命值。', 'reward': '❤️ +2 生命值'},
      {'icon': '🐉', 'title': '龙之试炼', 'desc': '你挑战了龙的试炼，成功通过获得了强大祝福。', 'reward': '🛡️ +1 护盾'},
      {'icon': '📜', 'title': '智慧卷轴', 'desc': '你捡到一张智慧卷轴，学习后攻击力翻倍。', 'reward': '💥 +1 双倍攻击'},
      {'icon': '🍀', 'title': '幸运之泉', 'desc': '你找到一眼幸运之泉，饮下后全身充满力量。', 'reward': '❤️‍🔥 生命值全满'},
    ];

    final event = events[DateTime.now().millisecondsSinceEpoch % events.length];

    return AlertDialog(
      backgroundColor: Colors.deepPurple.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.deepPurple[400]!, width: 2),
      ),
      title: Row(
        children: [
          Text(event['icon']!, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Text(
            event['title']!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event['desc']!,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '🎁 获得：${event['reward']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // ✅ 应用奖励
            _applyReward(event['reward']!, context);
            // ✅ 调用回调
            onComplete();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade500,
            foregroundColor: Colors.white,
          ),
          child: const Text('⚔️ 接受'),
        ),
      ],
    );
  }

  void _applyReward(String reward, BuildContext context) {
    if (reward.contains('生命药水')) {
      progress.appleCount++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🧪 获得一瓶生命药水！'), backgroundColor: Colors.green),
      );
    } else if (reward.contains('生命值')) {
      progress.hp = (progress.hp + 2).clamp(0, progress.maxHp);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❤️ 恢复 2 点生命值！'), backgroundColor: Colors.green),
      );
    } else if (reward.contains('护盾')) {
      progress.shieldCount++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🛡️ 获得一个护盾！'), backgroundColor: Colors.blue),
      );
    } else if (reward.contains('双倍攻击')) {
      progress.doubleExpCount++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💥 获得双倍攻击！'), backgroundColor: Colors.amber),
      );
    } else if (reward.contains('生命值全满')) {
      progress.hp = progress.maxHp;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❤️‍🔥 生命值完全恢复！'), backgroundColor: Colors.red),
      );
    }
  }
}