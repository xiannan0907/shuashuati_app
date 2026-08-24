import 'package:flutter/material.dart';

import '../../../../core/services/app_info.dart';
import '../../../../data/repositories/notification_repository.dart'; // ✅ 新增

class ProfileTab extends StatefulWidget {
  final int totalAnswered;
  final int correctRate;
  final int wrongCount;
  final int continuousDays;
  final bool todayChecked;
  final String dailyQuote;
  final VoidCallback onCheckin;

  const ProfileTab({
    super.key,
    required this.totalAnswered,
    required this.correctRate,
    required this.wrongCount,
    required this.continuousDays,
    required this.todayChecked,
    required this.dailyQuote,
    required this.onCheckin,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'name': '入门学者', 'target': 10, 'icon': '🌟'},
      {'name': '勤奋学习者', 'target': 50, 'icon': '📚'},
      {'name': '刷题达人', 'target': 100, 'icon': '💪'},
      {'name': '知识探索者', 'target': 500, 'icon': '🔍'},
      {'name': '学霸', 'target': 1000, 'icon': '🎓'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 32, color: Colors.blue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '用户',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '已学习 ${widget.totalAnswered} 题',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '连续学习 ${widget.continuousDays} 天',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _doCheckin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    widget.todayChecked ? '已打卡 ✅' : '📌 打卡',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 学习日报
          const Text(
            '📊 学习日报',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniStatCard('总答题', '${widget.totalAnswered}', Icons.quiz, Colors.blue.shade600),
              const SizedBox(width: 8),
              _buildMiniStatCard('正确率', '${widget.correctRate}%', Icons.percent, Colors.green.shade600),
              const SizedBox(width: 8),
              _buildMiniStatCard('错题数', '${widget.wrongCount}', Icons.error_outline, Colors.red.shade600),
            ],
          ),
          const SizedBox(height: 16),

          // 成就进度
          const Text(
            '🏆 成就进度',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...achievements.map((achievement) {
            final target = achievement['target'] as int;
            final progress = (widget.totalAnswered / target).clamp(0.0, 1.0);
            final isCompleted = widget.totalAnswered >= target;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(achievement['icon'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      achievement['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted ? Colors.green.shade700 : Colors.black87,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: isCompleted ? Colors.green : Colors.blue.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // 每日一句
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖 每日一句',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${widget.dailyQuote}"',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '版本 ${AppInfo.version}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 修改：打卡逻辑（添加成就通知）
  Future<void> _doCheckin() async {
    // 先调用父组件传入的打卡方法（更新数据）
    widget.onCheckin();

    // ✅ 新增：检查连续天数成就，生成通知
    final count = widget.continuousDays + 1; // 打卡后+1

    if (count == 7) {
      await notificationRepo.create(
        title: '🔥 连续学习 7 天！',
        content: '你已经连续学习 7 天了，继续保持这个好习惯！',
        type: 'achievement',
        actionRoute: '/profile',
        icon: 'emoji_events',
        sourceId: 'achievement_7days',
      );
    } else if (count == 30) {
      await notificationRepo.create(
        title: '🏆 坚持学习 30 天！',
        content: '恭喜你连续学习 30 天，这是巨大的成就！',
        type: 'achievement',
        actionRoute: '/profile',
        icon: 'emoji_events',
        sourceId: 'achievement_30days',
      );
    } else if (count == 100) {
      await notificationRepo.create(
        title: '👑 连续学习 100 天！',
        content: '你已成为传说中的「持之以恒」大师！',
        type: 'achievement',
        actionRoute: '/profile',
        icon: 'emoji_events',
        sourceId: 'achievement_100days',
      );
    }
  }
}