import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../bloc/quiz_bloc.dart';
import '../pages/quiz_page.dart';

class SearchWidget extends StatefulWidget {
  final Widget child;

  const SearchWidget({
    super.key,
    required this.child,
  });

  @override
  SearchWidgetState createState() => SearchWidgetState();
}

class SearchWidgetState extends State<SearchWidget> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchLoading = false;
  String _searchFilterSet = '全部';
  String _searchFilterType = '全部';
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void toggle() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults.clear();
        _searchFilterSet = '全部';
        _searchFilterType = '全部';
      }
    });
  }

  void clear() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _isSearching = false;
      _searchFilterSet = '全部';
      _searchFilterType = '全部';
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearchLoading = false;
      });
      return;
    }

    setState(() => _isSearchLoading = true);

    try {
      final repo = QuestionRepository();
      final results = await repo.searchQuestions(
        query: query,
        setName: _searchFilterSet == '全部' ? null : _searchFilterSet,
        questionType: _searchFilterType == '全部' ? null : _searchFilterType,
      );
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    } catch (e) {
      print('搜索失败: $e');
      setState(() => _isSearchLoading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
    });
    _performSearch('');
  }

  List<String> _getSearchSetNames() {
    final sets = _searchResults.map((item) => item['setName'] as String).toSet().toList();
    return ['全部', ...sets];
  }

  void _showFilterDialog() {
    final setNames = _getSearchSetNames();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '筛选搜索结果',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('题库', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: setNames.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, idx) {
                        final name = setNames[idx];
                        final isSelected = _searchFilterSet == name;
                        return FilterChip(
                          label: Text(name, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) {
                            setStateModal(() { _searchFilterSet = name; });
                            _performSearch(_searchController.text);
                          },
                          selectedColor: Colors.blue.shade100,
                          backgroundColor: Colors.grey.shade100,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('题型', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ['全部', '选择题', '判断题', '填空题'].length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, idx) {
                        final label = ['全部', '选择题', '判断题', '填空题'][idx];
                        final isSelected = _searchFilterType == label;
                        return FilterChip(
                          label: Text(label, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) {
                            setStateModal(() { _searchFilterType = label; });
                            _performSearch(_searchController.text);
                          },
                          selectedColor: Colors.blue.shade100,
                          backgroundColor: Colors.grey.shade100,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isSearching) {
      return Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
                  onPressed: toggle,
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '搜索题目...',
                      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: theme.textTheme.bodySmall?.color),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, size: 20, color: theme.textTheme.bodySmall?.color),
                        onPressed: _clearSearch,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list, color: theme.textTheme.bodyLarge?.color, size: 22),
                  onPressed: _showFilterDialog,
                  tooltip: '筛选',
                ),
              ],
            ),
          ),
          // 搜索结果
          Expanded(
            child: _buildSearchResults(context),
          ),
        ],
      );
    }

    return widget.child;
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);

    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text('输入关键词搜索题目', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text('未找到相关题目', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16)),
            const SizedBox(height: 4),
            Text('试试其他关键词', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
          ],
        ),
      );
    }

    // 按题库分组
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in _searchResults) {
      final setName = item['setName'] as String;
      if (!grouped.containsKey(setName)) grouped[setName] = [];
      grouped[setName]!.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final setName = grouped.keys.elementAt(index);
        final items = grouped[setName]!;
        final firstItem = items.first;
        final progress = firstItem['setProgress'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 题库标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text('📚 $setName', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(width: 8),
                    Text('(${items.length}题)', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                    const Spacer(),
                    Text('进度 ${(progress * 100).round()}%', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: theme.dividerColor.withOpacity(0.15),
                          color: progress >= 0.8 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 14, endIndent: 14),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final q = item['question'] as Question;

                final isJudge = q.options.length == 2 &&
                    q.options.contains('正确') &&
                    q.options.contains('错误');
                final isFill = q.options.length == 1 &&
                    q.options.first.contains('填空');
                final typeLabel = isJudge ? '判断题' : (isFill ? '填空题' : '选择题');

                final contentPreview = q.content.length > 50 ? '${q.content.substring(0, 50)}...' : q.content;

                return GestureDetector(
                  onTap: () {
                    final quizBloc = context.read<QuizBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: quizBloc,
                          child: QuizPage(setName: setName),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: idx % 2 == 0 ? theme.cardColor : theme.cardColor.withOpacity(0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          alignment: Alignment.center,
                          child: Text('${idx + 1}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contentPreview, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(typeLabel, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
                            ],
                          ),
                        ),
                        Text('刷题 ▶', style: TextStyle(fontSize: 12, color: theme.primaryColor)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}