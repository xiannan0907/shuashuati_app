import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/bloc/theme_bloc.dart';
import '../bloc/quiz_bloc.dart';
import '../tabs/list_tab.dart';
import '../tabs/profile_tab.dart';
import 'favorite_page.dart';
import 'wrong_center_page.dart';
import 'share_center_page.dart';
import '../widgets/search_widget.dart';
import '../widgets/dialogs.dart';
import '../widgets/tools_drawer.dart';
import '../../data/repositories/question_repository.dart';

class QuizSetListPage extends StatefulWidget {
  const QuizSetListPage({super.key});

  @override
  State<QuizSetListPage> createState() => _QuizSetListPageState();
}

class _QuizSetListPageState extends State<QuizSetListPage> {
  int _currentTab = 0;
  final GlobalKey<FavoritePageState> _favoriteKey = GlobalKey();
  final GlobalKey<SearchWidgetState> _searchKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ========== 数据 ==========
  int _wrongCount = 0;
  Map<String, double> _progressMap = {};
  Map<String, int> _totalMap = {};
  Map<String, int> _answeredMap = {};
  bool _hasLoaded = false;

  // ========== 打卡 ==========
  List<DateTime> _checkinDates = [];
  int _continuousDays = 0;
  bool _todayChecked = false;

  static const List<String> _quotes = [
    '今天的努力是明天的基石。',
    '学习不是填满水桶，而是点燃火焰。',
    '每一次刷题，都在靠近目标一步。',
    '坚持比天赋更可贵。',
    '知识就是力量，刷题就是积蓄。',
    '不要等待机会，而要创造机会。',
    '成功的秘诀在于持之以恒。',
    '学习是唯一稳赚不赔的投资。',
    '今天的你，比昨天更优秀。',
    '每一道错题都是进步的阶梯。',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCheckinData();
  }

  // ============================================================
  // 数据加载
  // ============================================================
  Future<void> _loadData() async {
    final repo = QuestionRepository();
    _wrongCount = await repo.getWrongQuestionCount();
    final setNames = await repo.getAllSetNames();

    _progressMap = {};
    _totalMap = {};
    _answeredMap = {};

    final futures = setNames.map((name) async {
      final questions = await repo.getQuestions(setName: name);
      final total = questions.length;
      final answered = questions.where((q) => q.isAnsweredValue).length;
      final progress = total > 0 ? answered / total : 0.0;
      return {
        'name': name,
        'total': total,
        'answered': answered,
        'progress': progress,
      };
    }).toList();

    final results = await Future.wait(futures);
    for (var result in results) {
      final name = result['name'] as String;
      _progressMap[name] = result['progress'] as double;
      _totalMap[name] = result['total'] as int;
      _answeredMap[name] = result['answered'] as int;
    }

    setState(() => _hasLoaded = true);
  }

  // ============================================================
  // 打卡
  // ============================================================
  Future<void> _loadCheckinData() async {
    try {
      final box = await Hive.openBox<String>('quizSetsBox');
      final data = box.get('checkin_dates');
      if (data != null && data.isNotEmpty) {
        final dateStrings = data.split(',');
        _checkinDates = dateStrings
            .map((s) => DateTime.tryParse(s))
            .where((d) => d != null)
            .cast<DateTime>()
            .toList();
        _calculateContinuousDays();
      }
    } catch (e) {}
  }

  void _calculateContinuousDays() {
    if (_checkinDates.isEmpty) {
      _continuousDays = 0;
      _todayChecked = false;
      return;
    }
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final sortedDates = List<DateTime>.from(_checkinDates)..sort((a, b) => b.compareTo(a));
    final latestDate = DateTime(sortedDates.first.year, sortedDates.first.month, sortedDates.first.day);
    _todayChecked = latestDate == todayDate;
    _continuousDays = _todayChecked ? _checkinDates.length : 0;
  }

  Future<void> _doCheckin() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (var date in _checkinDates) {
      final d = DateTime(date.year, date.month, date.day);
      if (d == todayDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('今天已经打卡了！继续加油 💪'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    bool isContinuous = true;
    if (_checkinDates.isNotEmpty) {
      final sortedDates = List<DateTime>.from(_checkinDates)..sort((a, b) => b.compareTo(a));
      final latest = DateTime(sortedDates.first.year, sortedDates.first.month, sortedDates.first.day);
      final yesterday = todayDate.subtract(const Duration(days: 1));
      if (latest != todayDate && latest != yesterday) {
        isContinuous = false;
      }
    }

    _checkinDates.add(todayDate);
    try {
      final box = await Hive.openBox<String>('quizSetsBox');
      final dateStrings = _checkinDates.map((d) => d.toIso8601String().split('T')[0]).join(',');
      await box.put('checkin_dates', dateStrings);
    } catch (e) {}

    setState(() {
      _todayChecked = true;
      if (isContinuous) {
        _continuousDays++;
      } else {
        _continuousDays = 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isContinuous
              ? '🎉 连续学习 $_continuousDays 天！继续加油！'
              : '👍 打卡成功！',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // 统计
  // ============================================================
  Map<String, dynamic> _getStudyStats() {
    int totalAnswered = 0;
    int totalQuestions = 0;
    int totalCorrect = 0;

    for (var name in _totalMap.keys) {
      final total = _totalMap[name] ?? 0;
      final answered = _answeredMap[name] ?? 0;
      totalQuestions += total;
      totalAnswered += answered;
    }
    totalCorrect = (totalAnswered - _wrongCount).clamp(0, totalAnswered);
    final correctRate = totalAnswered > 0 ? (totalCorrect / totalAnswered * 100).round() : 0;

    return {
      'totalQuestions': totalQuestions,
      'totalAnswered': totalAnswered,
      'totalCorrect': totalCorrect,
      'correctRate': correctRate,
      'wrongCount': _wrongCount,
    };
  }

  String _getDailyQuote() {
    final day = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[day % _quotes.length];
  }

  // ============================================================
  // 刷新
  // ============================================================
  Future<void> _forceRefresh() async {
    _hasLoaded = false;
    await _loadData();
    context.read<QuizBloc>().add(LoadQuizSetList());
    _searchKey.currentState?.clear();
  }

  // ============================================================
  // 创建/重命名/删除
  // ============================================================
  void _showCreateSetDialog(BuildContext context) {
    QuizDialogs.showCreateSetDialog(context, onCreated: _loadData);
  }

  void _showRenameDialog(BuildContext context, String name) {
    QuizDialogs.showRenameDialog(context, oldName: name, onRenamed: _loadData);
  }

  void _showDeleteConfirm(BuildContext context, String name) {
    QuizDialogs.showDeleteConfirm(context, name: name, onDeleted: _loadData);
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<QuizBloc>().state;

    if (state is QuizSetListLoaded && !_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: ToolsDrawer(
        onRefresh: _loadData,
      ),
      appBar: AppBar(

        actions: [
          // 搜索
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _searchKey.currentState?.toggle(),
            tooltip: '搜索',
          ),
          // 分享
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShareCenterPage()),
              );
            },
          ),


          // 刷新
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _forceRefresh,
          ),
          // 创建
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreateSetDialog(context),
          ),
          // 更多工具
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: '更多工具',
          ),
        ],
      ),
      body: SearchWidget(
        key: _searchKey,
        child: _hasLoaded
            ? IndexedStack(
          index: _currentTab,
          children: [
            ListTab(
              progressMap: _progressMap,
              totalMap: _totalMap,
              answeredMap: _answeredMap,
              wrongCount: _wrongCount,
              onRefresh: _loadData,
            ),
            FavoritePage(key: _favoriteKey),
            WrongCenterPage(
              wrongCount: _wrongCount,
              onRefresh: _loadData,
            ),
            ProfileTab(
              totalAnswered: _getStudyStats()['totalAnswered'],
              correctRate: _getStudyStats()['correctRate'],
              wrongCount: _wrongCount,
              continuousDays: _continuousDays,
              todayChecked: _todayChecked,
              dailyQuote: _getDailyQuote(),
              onCheckin: _doCheckin,
            ),
          ],
        )
            : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() { _currentTab = index; });
          if (index == 1) _favoriteKey.currentState?.reload();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: '题库'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '收藏'),
          BottomNavigationBarItem(icon: Icon(Icons.error_outline), label: '错题'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}