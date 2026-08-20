import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/quiz_bloc.dart';
import '../pages/quiz_page.dart';
import '../pages/example_import_page.dart';

class ListTab extends StatelessWidget {
  final Map<String, double> progressMap;
  final Map<String, int> totalMap;
  final Map<String, int> answeredMap;
  final int wrongCount;
  final VoidCallback onRefresh;

  const ListTab({
    super.key,
    required this.progressMap,
    required this.totalMap,
    required this.answeredMap,
    required this.wrongCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<QuizBloc>();
    final state = bloc.state;
    final setNames = state is QuizSetListLoaded ? state.setNames : progressMap.keys.toList();
    final currentSet = state is QuizSetListLoaded ? state.currentSet : (setNames.isNotEmpty ? setNames.first : '');

    final displayNames = setNames.toList();

    int totalAnswered = 0;
    int totalQuestions = 0;
    for (var name in setNames) {
      totalAnswered += answeredMap[name] ?? 0;
      totalQuestions += totalMap[name] ?? 0;
    }
    final overallProgress = totalQuestions > 0
        ? (totalAnswered / totalQuestions * 100).round()
        : 0;

    if (setNames.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return Column(
      children: [
        // ✅ 统计条（保留）
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('${setNames.length}', '总题库', Colors.white),
              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem('$totalAnswered', '已答题', Colors.white),
              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem('$overallProgress%', '总进度', Colors.white),
            ],
          ),
        ),

        // ❌ 删除整个快捷入口行（示例/爬塔/强化/错题集）

        const SizedBox(height: 4),

        // ✅ 题库列表（保留）
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            itemCount: displayNames.length,
            itemBuilder: (context, index) {
              final name = displayNames[index];
              final isCurrent = name == currentSet;
              final progress = progressMap[name] ?? 0.0;
              final total = totalMap[name] ?? 0;
              final answered = answeredMap[name] ?? 0;
              final progressPercent = (progress * 100).round();

              final progressColor = progress == 1.0
                  ? Colors.green
                  : theme.primaryColor;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Stack(
                  children: [
                    // 背景进度条
                    Container(
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerHighest,
                        border: isCurrent
                            ? Border.all(color: theme.primaryColor, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (progress * 100).toInt(),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isCurrent ? 10 : 12),
                                  bottomLeft: Radius.circular(isCurrent ? 10 : 12),
                                ),
                                color: progressColor.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: ((1 - progress) * 100).toInt(),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(isCurrent ? 10 : 12),
                                  bottomRight: Radius.circular(isCurrent ? 10 : 12),
                                ),
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 可点击的内容层
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final quizBloc = context.read<QuizBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                  value: quizBloc,
                                  child: QuizPage(setName: name),
                                ),
                              ),
                            ).then((result) {
                              if (result == true) onRefresh();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isCurrent ? Icons.check_circle : Icons.library_books,
                                  color: isCurrent ? Colors.green : theme.primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isCurrent)
                                        Text(
                                          '当前使用',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$answered/$total 题',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: progressColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$progressPercent%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: progressColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: theme.primaryColor),
                                  onPressed: () => _showRenameDialog(context, name),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  onPressed: () => _showDeleteConfirm(context, name),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, String oldName) {
    final TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('📝 重命名题库'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入新名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (controller.text.isNotEmpty && controller.text != oldName) {
              Navigator.pop(dialogContext);
              context.read<QuizBloc>().add(RenameQuizSet(oldName, controller.text));
              Future.delayed(const Duration(milliseconds: 300), () {
                // onRefresh 在外部
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                Navigator.pop(dialogContext);
                context.read<QuizBloc>().add(RenameQuizSet(oldName, controller.text));
                Future.delayed(const Duration(milliseconds: 300), () {
                  // onRefresh 在外部
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🗑️ 删除题库'),
        content: Text('确定要删除题库 "$name" 吗？所有题目将丢失！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<QuizBloc>().add(DeleteQuizSet(name));
              Future.delayed(const Duration(milliseconds: 300), () {
                // onRefresh 在外部
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '📚 暂无题库',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角「+」创建题库\n或从菜单导入示例题库',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // 通过菜单进入示例导入
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExampleImportPage()),
                ).then((result) {
                  if (result == true) {
                    // onRefresh 在外部
                  }
                });
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('导入示例题库'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}