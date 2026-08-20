import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/bloc/theme_bloc.dart';
import '../../modules/quiz/data/models/question_model.dart';
import '../../modules/quiz/data/repositories/question_repository.dart';

/// 搜索结果项基类（未来可扩展）
class SearchResultItem {
  final String moduleId;
  final String moduleName;
  final String title;
  final String subtitle;
  final String? actionRoute;
  final IconData icon;

  SearchResultItem({
    required this.moduleId,
    required this.moduleName,
    required this.title,
    required this.subtitle,
    this.actionRoute,
    required this.icon,
  });
}

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResultItem> _results = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // 分组结果
  Map<String, List<SearchResultItem>> get _groupedResults {
    final map = <String, List<SearchResultItem>>{};
    for (var item in _results) {
      map.putIfAbsent(item.moduleName, () => []);
      map[item.moduleName]!.add(item);
    }
    return map;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final allResults = <SearchResultItem>[];

      // ====== 1. 搜索题目（刷题模块） ======
      final repo = QuestionRepository();
      final questionResults = await repo.searchQuestions(
        query: query,
      );

      for (var item in questionResults) {
        final q = item['question'] as Question;
        final setName = item['setName'] as String;

        final isJudge = q.options.length == 2 &&
            q.options.contains('正确') &&
            q.options.contains('错误');
        final isFill = q.options.length == 1 &&
            q.options.first.contains('填空');
        final typeLabel = isJudge ? '判断题' : (isFill ? '填空题' : '选择题');

        allResults.add(
          SearchResultItem(
            moduleId: 'quiz',
            moduleName: '刷题',
            title: q.content,
            subtitle: '📚 $setName · $typeLabel',
            actionRoute: '/quiz/question/${q.id}',
            icon: Icons.quiz,
          ),
        );
      }

      // ====== 2. 搜索题库名称 ======
      final setNames = await repo.getAllSetNames();
      for (var name in setNames) {
        if (name.toLowerCase().contains(query.toLowerCase())) {
          allResults.add(
            SearchResultItem(
              moduleId: 'quiz',
              moduleName: '刷题',
              title: '📚 题库：$name',
              subtitle: '点击进入刷题',
              actionRoute: '/quiz/set/$name',
              icon: Icons.library_books,
            ),
          );
        }
      }

      // ====== 3. 搜索模块（未来扩展） ======
      // 这里可以搜索已安装模块的名称
      // final modules = ModuleRegistry.modules;
      // for (var module in modules) {
      //   if (module.title.contains(query)) {
      //     allResults.add(...);
      //   }
      // }

      setState(() {
        _results = allResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grouped = _groupedResults;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.grey.shade700,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: '搜索题目、题库、模块...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                onPressed: () {
                  _controller.clear();
                  setState(() => _results = []);
                },
              )
                  : null,
            ),
            onChanged: _search,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? _buildEmptyState(context, isDark)
          : _buildResults(context, isDark, grouped),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _controller.text.isEmpty ? '输入关键词搜索' : '未找到相关内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          if (_controller.text.isNotEmpty)
            Text(
              '试试其他关键词',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            )
          else
            Text(
              '可搜索题目、题库名称、模块',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(
      BuildContext context,
      bool isDark,
      Map<String, List<SearchResultItem>> grouped,
      ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        final moduleName = entry.key;
        final items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模块标题
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      moduleName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length}个结果',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((item) => _buildResultItem(context, item, isDark)),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildResultItem(
      BuildContext context,
      SearchResultItem item,
      bool isDark,
      ) {
    return GestureDetector(
      onTap: () {
        // 处理点击跳转
        if (item.actionRoute != null && item.actionRoute!.startsWith('/quiz/')) {
          Navigator.pop(context);
          // 实际应用中根据路由跳转
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('跳转到: ${item.title}'),
              duration: const Duration(seconds: 1),
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                item.icon,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}