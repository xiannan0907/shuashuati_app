import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../bloc/quiz_bloc.dart';
import 'favorite_quiz_page.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => FavoritePageState();
}

class FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String _selectedSet = '全部';
  String _filterType = '全部';
  List<String> _setNames = [];

  final Map<String, bool> _expandedMap = {};

  void reload() => _loadData();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = QuestionRepository();
      _favorites = await repo.getFavoriteQuestionsWithSource();

      final sets = _favorites.map((item) => item['setName'] as String).toSet();
      _setNames = ['全部', ...sets];

      if (!_setNames.contains(_selectedSet)) {
        _selectedSet = '全部';
      }

      for (var name in _setNames) {
        if (name != '全部') {
          _expandedMap.putIfAbsent(name, () => true);
        }
      }
    } catch (e) {
      print('加载收藏失败: $e');
    }
    setState(() => _isLoading = false);
  }

  bool _isJudge(Question q) =>
      q.options.length == 2 &&
          q.options.contains('正确') &&
          q.options.contains('错误');

  bool _isFill(Question q) =>
      q.options.length == 1 &&
          q.options.first.contains('填空');

  List<Map<String, dynamic>> get _filteredItems {
    var result = _favorites;

    if (_selectedSet != '全部') {
      result = result.where((item) => item['setName'] == _selectedSet).toList();
    }

    if (_filterType != '全部') {
      result = result.where((item) {
        final q = item['question'] as Question;
        final isJudge = _isJudge(q);
        final isFill = _isFill(q);
        if (_filterType == '选择题') return !isJudge && !isFill;
        if (_filterType == '判断题') return isJudge;
        if (_filterType == '填空题') return isFill;
        return true;
      }).toList();
    }

    return result;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedItems {
    final map = <String, List<Map<String, dynamic>>>{};
    final filtered = _filteredItems;

    for (var item in filtered) {
      final setName = item['setName'] as String;
      map.putIfAbsent(setName, () => []);
      map[setName]!.add(item);
    }

    return map;
  }

  // ✅ 移出单题
  Future<void> _showRemoveConfirm(Question q) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '移出笔记',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要把这条笔记移出笔记本吗？',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                ),
                child: Text(
                  q.content.length > 40 ? '${q.content.substring(0, 40)}...' : q.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '移出',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final repo = QuestionRepository();
      await repo.toggleFavorite(q.id);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📖 已移出笔记本',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          backgroundColor: theme.cardColor,
          elevation: 2,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
          ),
        ),
      );
    }
  }

  // ✅ 清空单个笔记本
  Future<void> _clearSetFavorites(String setName) async {
    final items = _groupedItems[setName] ?? [];
    if (items.isEmpty) return;

    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '清空笔记本：$setName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要清空「$setName」中的所有收藏吗？\n共 ${items.length} 条笔记将被移除。',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withOpacity(0.1),
                        border: Border.all(color: Colors.red.shade200.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final repo = QuestionRepository();
      for (var item in items) {
        await repo.toggleFavorite(item['question'].id);
      }
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📖 已清空「$setName」',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          backgroundColor: theme.cardColor,
          elevation: 2,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
          ),
        ),
      );
    }
  }

  // ✅ 清空所有收藏
  Future<void> _clearAllFavorites() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '清空笔记本',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要清空所有收藏笔记吗？\n此操作不可撤销。',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withOpacity(0.1),
                        border: Border.all(color: Colors.red.shade200.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) {
      final repo = QuestionRepository();
      for (var item in _favorites) {
        await repo.toggleFavorite(item['question'].id);
      }
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📖 已清空笔记本',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          backgroundColor: theme.cardColor,
          elevation: 2,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      );
    }

    final total = _favorites.length;
    final grouped = _groupedItems;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _favorites.isEmpty
          ? _buildEmptyState(context)
          : Column(
        children: [
          // 封面标题
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(isDark ? 0.05 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '收藏笔记本 ($total)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _clearAllFavorites,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '清空',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 筛选
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(isDark ? 0.02 : 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _setNames.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final name = _setNames[index];
                      final isSelected = _selectedSet == name;
                      final count = name == '全部'
                          ? _favorites.length
                          : _favorites.where((item) => item['setName'] == name).length;

                      return _buildPaperTag(
                        context,
                        label: name == '全部' ? '📚 全部' : name,
                        count: count,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedSet = name;
                            _filterType = '全部';
                          });
                        },
                      );
                    },
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: theme.dividerColor.withOpacity(0.15),
                ),
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ['全部', '选择题', '判断题', '填空题'].length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final label = ['全部', '选择题', '判断题', '填空题'][index];
                      final isSelected = _filterType == label;

                      final baseList = _selectedSet == '全部'
                          ? _favorites
                          : _favorites.where((item) => item['setName'] == _selectedSet).toList();

                      final count = label == '全部'
                          ? baseList.length
                          : baseList.where((item) {
                        final q = item['question'] as Question;
                        final isJudge = _isJudge(q);
                        final isFill = _isFill(q);
                        if (label == '选择题') return !isJudge && !isFill;
                        if (label == '判断题') return isJudge;
                        if (label == '填空题') return isFill;
                        return false;
                      }).length;

                      return _buildPaperTag(
                        context,
                        label: count > 0 ? '$label ($count)' : label,
                        count: count,
                        isSelected: isSelected,
                        onTap: count > 0 ? () => setState(() => _filterType = label) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 笔记本列表
          Expanded(
            child: grouped.isEmpty
                ? Center(
              child: Text(
                '当前筛选条件下没有收藏',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: grouped.keys.length,
              itemBuilder: (context, index) {
                final setName = grouped.keys.elementAt(index);
                final items = grouped[setName]!;
                final questions = items.map((item) => item['question'] as Question).toList();
                final answered = questions.where((q) => q.isAnsweredValue).length;
                final totalQ = questions.length;
                final progress = totalQ > 0 ? answered / totalQ : 0.0;

                final isExpanded = _expandedMap[setName] ?? true;

                return _buildNotebookCard(
                  context,
                  setName: setName,
                  questions: questions,
                  totalQ: totalQ,
                  answered: answered,
                  progress: progress,
                  isExpanded: isExpanded,
                  onToggle: () {
                    setState(() {
                      _expandedMap[setName] = !isExpanded;
                    });
                  },
                  onClear: () => _clearSetFavorites(setName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 纸标签 ====================
  Widget _buildPaperTag(
      BuildContext context, {
        required String label,
        required int count,
        required bool isSelected,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? theme.dividerColor.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.dividerColor.withOpacity(0.2) : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected
                ? theme.textTheme.bodyLarge?.color
                : theme.textTheme.bodySmall?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ==================== 笔记本卡片 ====================
  Widget _buildNotebookCard(
      BuildContext context, {
        required String setName,
        required List<Question> questions,
        required int totalQ,
        required int answered,
        required double progress,
        required bool isExpanded,
        required VoidCallback onToggle,
        required VoidCallback onClear,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ 进度条颜色（深色模式更柔和）
    Color progressColor;
    if (progress >= 0.8) {
      progressColor = isDark ? Colors.green.shade300 : Colors.green.shade600;
    } else if (progress >= 0.5) {
      progressColor = isDark ? Colors.orange.shade300 : Colors.orange.shade600;
    } else {
      progressColor = isDark ? Colors.blue.shade300 : Colors.blue.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(isDark ? 0.03 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: theme.shadowColor.withOpacity(isDark ? 0.02 : 0.04),
            blurRadius: 2,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面标题行
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.cardColor,
                    theme.cardColor.withOpacity(isDark ? 0.5 : 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // 装订孔
                    Row(
                      children: List.generate(5, (_) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    const Text('📒', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        setName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalQ题 · 已掌握$answered · ${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // ✅ 进度条（深色模式更柔和）
                    SizedBox(
                      width: 30,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: theme.dividerColor.withOpacity(0.15),
                          color: progressColor.withOpacity(isDark ? 0.8 : 1.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpanded ? '收起' : '展开',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final quizBloc = context.read<QuizBloc>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: quizBloc,
                              child: FavoriteQuizPage(questions: questions),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        '刷全部',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.dividerColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClear,
                      child: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                          decoration: TextDecoration.underline,
                          decorationColor: isDark ? Colors.red.shade200.withOpacity(0.3) : Colors.red.shade200,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 内页
            if (isExpanded && questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  children: questions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    return _buildNotebookPageItem(context, q, idx);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 笔记本内页条目 ====================
  Widget _buildNotebookPageItem(BuildContext context, Question q, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isJudge = _isJudge(q);
    final isFill = _isFill(q);
    final isAnswered = q.isAnsweredValue;

    final typeLabel = isJudge ? '判断题' : (isFill ? '填空题' : '选择题');
    final typeColor = isJudge
        ? Colors.purple.shade700
        : (isFill ? Colors.orange.shade700 : Colors.green.shade700);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        children: [
          // ✅ 分割线更淡
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(bottom: 3),
            color: theme.dividerColor.withOpacity(0.12),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAnswered
                        ? (isDark ? Colors.green.shade300 : Colors.green.shade600)
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    final quizBloc = context.read<QuizBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: quizBloc,
                          child: FavoriteQuizPage(questions: [q]),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.content,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isAnswered
                                ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                : theme.textTheme.bodyLarge?.color,
                            decoration: isAnswered ? TextDecoration.lineThrough : null,
                            decorationThickness: 1.5,
                            decorationColor: isDark
                                ? Colors.green.shade200.withOpacity(0.3)
                                : Colors.green.shade300,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (!isFill) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 1,
                            children: q.options.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final opt = entry.value;
                              final letter = String.fromCharCode(65 + idx);
                              final isCorrect = idx == q.correctIndex;
                              return Text(
                                '$letter. $opt',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCorrect
                                      ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                      : theme.textTheme.bodySmall?.color,
                                  fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          Text(
                            '📝 答案：${q.answer ?? "（未设置）"}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '─ $typeLabel',
                              style: TextStyle(
                                fontSize: 9,
                                color: typeColor.withOpacity(isDark ? 0.5 : 0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAnswered ? '✓ 已掌握' : '✦ 待复习',
                              style: TextStyle(
                                fontSize: 9,
                                color: isAnswered
                                    ? (isDark ? Colors.green.shade300 : Colors.green.shade500)
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showRemoveConfirm(q),
                              child: Text(
                                '移出',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme.textTheme.bodySmall?.color,
                                  decoration: TextDecoration.underline,
                                  decorationColor: theme.dividerColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 空状态 ====================
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.note_alt,
              size: 60,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '📖 笔记本空空如也',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在刷题时点击 ⭐ 收藏题目\n它们会自动记录在这里',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}