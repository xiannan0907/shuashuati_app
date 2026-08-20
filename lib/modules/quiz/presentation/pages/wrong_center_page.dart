import 'package:flutter/material.dart';
// ✅ 删除了未使用的 'package:flutter_bloc/flutter_bloc.dart'

import '../../data/models/question_model.dart';
import 'wrong_questions_page.dart';
import 'wrong_reinforce_page.dart';
import 'review_page.dart';
import '../../data/repositories/question_repository.dart';

class WrongCenterPage extends StatefulWidget {
  final int wrongCount;
  final VoidCallback onRefresh;

  const WrongCenterPage({
    super.key,
    required this.wrongCount,
    required this.onRefresh,
  });

  @override
  State<WrongCenterPage> createState() => _WrongCenterPageState();
}

class _WrongCenterPageState extends State<WrongCenterPage> {
  List<Question> _wrongQuestions = [];
  bool _isLoading = true;
  // ✅ 删除了未使用的 _masteredCount
  int _todayNew = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = QuestionRepository();
      _wrongQuestions = await repo.getWrongQuestions();
      final stats = await repo.getWrongStatsSummary();
      // ✅ _masteredCount 已删除，这里只取 todayNew
      _todayNew = stats['todayNew'] ?? 0;
    } catch (e) {
      print('加载错题中心数据失败: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 删除了未使用的 final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = widget.wrongCount;
    final remaining = _wrongQuestions.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❌ 错题中心',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '管理你的错题，针对性复习',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // 统计卡片
          Row(
            children: [
              _buildStatCard('总计', '$total', Icons.error_outline, Colors.red.shade600),
              const SizedBox(width: 10),
              _buildStatCard('待复习', '$remaining', Icons.pending, Colors.orange.shade600),
              const SizedBox(width: 10),
              _buildStatCard('今日新增', '$_todayNew', Icons.today, Colors.blue.shade600),
            ],
          ),
          const SizedBox(height: 16),

          // 三个功能入口
          const Text(
            '📌 功能入口',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildEntryCard(
                icon: Icons.list_alt,
                label: '错题集',
                subtitle: '$total 道题',
                color: Colors.red.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WrongQuestionsPage(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(width: 10),
              _buildEntryCard(
                icon: Icons.autorenew,
                label: '强化练习',
                subtitle: '循环刷题',
                color: Colors.purple.shade600,
                onTap: () {
                  if (_wrongQuestions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 暂无错题，继续保持！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WrongReinforcePage(
                        wrongQuestions: _wrongQuestions,
                      ),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildEntryCard(
                icon: Icons.psychology,
                label: '智能复习',
                subtitle: '间隔重复',
                color: Colors.blue.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReviewPage(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(width: 10),
              _buildEntryCard(
                icon: Icons.cleaning_services,
                label: '清空错题',
                subtitle: '全部移除',
                color: Colors.grey.shade600,
                onTap: () => _showClearConfirm(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 最新错题预览
          if (_wrongQuestions.isNotEmpty) ...[
            const Text(
              '📝 最新错题',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _wrongQuestions.length > 5 ? 5 : _wrongQuestions.length,
                itemBuilder: (context, index) {
                  final q = _wrongQuestions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red, size: 18),
                      title: Text(
                        q.content.length > 40
                            ? '${q.content.substring(0, 40)}...'
                            : q.content,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WrongQuestionsPage(),
                          ),
                        ).then((_) => _loadData());
                      },
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.celebration, size: 64, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text(
                      '🎊 没有错题！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '继续保持，再接再厉',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.12), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.12), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🗑️ 清空所有错题？'),
        content: const Text(
          '此操作将删除所有错题记录，且不可恢复。\n\n确定要继续吗？',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final repo = QuestionRepository();
              await repo.clearAllWrongQuestions();
              _loadData();
              widget.onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已清空所有错题'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }
}