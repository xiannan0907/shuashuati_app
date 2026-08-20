import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/question_model.dart';

class FavoriteQuizPage extends StatefulWidget {
  final List<Question> questions;

  const FavoriteQuizPage({super.key, required this.questions});

  @override
  State<FavoriteQuizPage> createState() => _FavoriteQuizPageState();
}

class _FavoriteQuizPageState extends State<FavoriteQuizPage> {
  late List<Question> _questions;
  int _currentIndex = 0;
  bool _isStudyMode = false;

  final Map<String, String> _fillAnswers = {};
  final Map<String, bool> _answeredState = {};
  final Map<String, int?> _selectedState = {};

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
    _resetAllStates();
  }

  void _resetAllStates() {
    for (var q in _questions) {
      _answeredState[q.id] = false;
      _selectedState[q.id] = null;
      _fillAnswers[q.id] = '';
    }
  }

  void _resetCurrentQuestion() {
    final q = _questions[_currentIndex];
    setState(() {
      _answeredState[q.id] = false;
      _selectedState[q.id] = null;
      _fillAnswers[q.id] = '';
    });
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _currentIndex = index);
  }

  bool _isJudge(Question q) =>
      q.options.length == 2 &&
          q.options.contains('正确') &&
          q.options.contains('错误');

  bool _isFill(Question q) =>
      q.options.length == 1 &&
          q.options.first.contains('填空');

  void _handleSelect(Question q, int selectedIndex) {
    if (_isStudyMode) return;
    if (_answeredState[q.id] == true) return;
    setState(() {
      _selectedState[q.id] = selectedIndex;
      _answeredState[q.id] = true;
    });
  }

  void _handleFillSubmit(Question q) {
    final answer = _fillAnswers[q.id] ?? '';
    if (answer.trim().isEmpty) {
      _showSnackBar('请先输入答案');
      return;
    }
    setState(() => _answeredState[q.id] = true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.red.shade400 : Colors.grey.shade600,
          ),
        ),
        backgroundColor: const Color(0xFFFEFCF3),
        elevation: 2,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isError ? Colors.red.shade200 : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;

    final topPadding = media.padding.top;
    final bottomPadding = media.padding.bottom;

    // ✅ 基于屏幕宽高计算尺寸
    final isSmall = screenWidth < 380;
    final isLarge = screenWidth > 600;
    final fontSizeBase = isSmall ? 12.0 : (isLarge ? 17.0 : 14.0);
    final paddingBase = isSmall ? 8.0 : (isLarge ? 20.0 : 12.0);

    // ✅ 状态栏样式
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0EDE8),
        body: SafeArea(
          child: Center(
            child: Text(
              '📖 笔记本里没有题目',
              style: TextStyle(
                fontSize: fontSizeBase + 2,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final total = _questions.length;
    final isJudge = _isJudge(q);
    final isFill = _isFill(q);
    final typeLabel = isJudge ? '判断题' : (isFill ? '填空题' : '选择题');
    final isAnswered = _answeredState[q.id] ?? false;
    final selected = _selectedState[q.id];
    final isCorrect = isAnswered && selected == q.correctIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE8),
      extendBodyBehindAppBar: false,
      appBar: _buildNotebookAppBar(
        '📖 刷题笔记',
        '${_currentIndex + 1} / $total',
        fontSizeBase,
        topPadding,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingBase),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ✅ 实际可用高度 = 屏幕高度 - AppBar - 底部导航 - 内边距
            final bottomNavHeight = 44.0 + bottomPadding;
            final availableHeight = constraints.maxHeight - bottomNavHeight - paddingBase * 2 - 40;

            return Column(
              children: [
                // ========== 内页卡片（动态高度） ==========
                SizedBox(
                  height: availableHeight.clamp(200, 600),
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -80 && _currentIndex < total - 1) {
                        _goToQuestion(_currentIndex + 1);
                      } else if (details.primaryVelocity! > 80 && _currentIndex > 0) {
                        _goToQuestion(_currentIndex - 1);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingBase,
                        vertical: paddingBase * 0.6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCF3),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 2,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ====== 顶部信息行 ======
                          Container(
                            padding: const EdgeInsets.only(bottom: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey, width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '第 ${_currentIndex + 1} 题',
                                  style: TextStyle(
                                    fontSize: fontSizeBase + 2,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: fontSizeBase - 1,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const Spacer(),
                                if (isAnswered)
                                  Text(
                                    isCorrect ? '✓ 正确' : '✗ 错误',
                                    style: TextStyle(
                                      fontSize: fontSizeBase - 2,
                                      color: isCorrect
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isStudyMode = !_isStudyMode;
                                      _resetCurrentQuestion();
                                    });
                                  },
                                  child: Text(
                                    _isStudyMode ? '📖 背题' : '✍️ 做题',
                                    style: TextStyle(
                                      fontSize: fontSizeBase - 2,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ====== 题目内容（自适应剩余空间） ======
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.content,
                                    style: TextStyle(
                                      fontSize: fontSizeBase + 2,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                      height: 1.6,
                                    ),
                                  ),
                                  SizedBox(height: paddingBase),

                                  // ====== 选项 ======
                                  if (isFill) ...[
                                    _buildFillInput(
                                      q,
                                      fontSizeBase,
                                      paddingBase,
                                      isAnswered,
                                    ),
                                  ] else ...[
                                    ...q.options.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final opt = entry.value;
                                      final isSelected = selected == idx;
                                      final isOptCorrect = idx == q.correctIndex;
                                      final letter = isJudge
                                          ? (idx == 0 ? 'T' : 'F')
                                          : String.fromCharCode(65 + idx);

                                      Color? borderColor = Colors.grey.shade200;
                                      Color? bgColor = Colors.transparent;
                                      Color? textColor = Colors.grey.shade700;

                                      if (_isStudyMode) {
                                        if (isOptCorrect) {
                                          borderColor = Colors.green.shade300;
                                          bgColor = Colors.green.shade50;
                                          textColor = Colors.green.shade700;
                                        }
                                      } else if (isAnswered) {
                                        if (isSelected && isOptCorrect) {
                                          borderColor = Colors.green.shade300;
                                          bgColor = Colors.green.shade50;
                                          textColor = Colors.green.shade700;
                                        } else if (isSelected && !isOptCorrect) {
                                          borderColor = Colors.red.shade300;
                                          bgColor = Colors.red.shade50;
                                          textColor = Colors.red.shade700;
                                        } else if (isOptCorrect) {
                                          borderColor = Colors.green.shade200;
                                          bgColor = Colors.green.shade50;
                                          textColor = Colors.green.shade600;
                                        }
                                      }

                                      final bool isDisabled = _isStudyMode || isAnswered;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: GestureDetector(
                                          onTap: isDisabled
                                              ? null
                                              : () => _handleSelect(q, idx),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: paddingBase * 0.7,
                                              vertical: paddingBase * 0.5,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: borderColor,
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(2),
                                              color: bgColor,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isDisabled
                                                          ? (isOptCorrect
                                                          ? Colors.green.shade300
                                                          : Colors.grey.shade300)
                                                          : (isSelected
                                                          ? Colors.grey.shade700
                                                          : Colors.grey.shade300),
                                                      width: 1.5,
                                                    ),
                                                    color: isDisabled
                                                        ? (isOptCorrect
                                                        ? Colors.green.shade100
                                                        : Colors.transparent)
                                                        : (isSelected
                                                        ? Colors.grey.shade700
                                                        : Colors.transparent),
                                                  ),
                                                  child: (isDisabled && isOptCorrect)
                                                      ? const Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color: Colors.green,
                                                  )
                                                      : (isSelected &&
                                                      !_isStudyMode &&
                                                      !isAnswered)
                                                      ? const Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color: Colors.white,
                                                  )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '$letter. $opt',
                                                    style: TextStyle(
                                                      fontSize: fontSizeBase + 1,
                                                      color: textColor,
                                                      decoration: _isStudyMode &&
                                                          isOptCorrect
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                      decorationColor: Colors.green.shade300,
                                                    ),
                                                  ),
                                                ),
                                                if (_isStudyMode && isOptCorrect)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade100,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                    child: Text(
                                                      '答案',
                                                      style: TextStyle(
                                                        fontSize: fontSizeBase - 4,
                                                        color: Colors.green.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],

                                  if (isAnswered && !_isStudyMode)
                                    Padding(
                                      padding: EdgeInsets.only(top: paddingBase * 0.4),
                                      child: GestureDetector(
                                        onTap: _resetCurrentQuestion,
                                        child: Text(
                                          '🔄 重做此题',
                                          style: TextStyle(
                                            fontSize: fontSizeBase - 2,
                                            color: Colors.grey.shade500,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // ====== 底部进度条 ======
                          Container(
                            padding: const EdgeInsets.only(top: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey, width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '进度',
                                  style: TextStyle(
                                    fontSize: fontSizeBase - 2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: (_currentIndex + 1) / total,
                                      minHeight: 3,
                                      backgroundColor: Colors.grey.shade200,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_currentIndex + 1}/$total',
                                  style: TextStyle(
                                    fontSize: fontSizeBase - 2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: paddingBase * 0.6),

                // ========== 底部导航 ==========
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingBase,
                    vertical: paddingBase * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFCF3),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _currentIndex > 0
                            ? () => _goToQuestion(_currentIndex - 1)
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.chevron_left,
                              size: fontSizeBase + 4,
                              color: _currentIndex > 0
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                            Text(
                              '上一题',
                              style: TextStyle(
                                fontSize: fontSizeBase,
                                color: _currentIndex > 0
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                decoration: _currentIndex > 0
                                    ? TextDecoration.underline
                                    : null,
                                decorationColor: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (isAnswered && !_isStudyMode) {
                            _showSnackBar(
                              isCorrect ? '✓ 已掌握！' : '✗ 再练练吧',
                              isError: !isCorrect,
                            );
                          } else if (_isStudyMode) {
                            _showSnackBar('📖 已复习');
                          } else {
                            _showSnackBar('请先作答再标记');
                          }
                        },
                        child: Text(
                          '✓ 标记掌握',
                          style: TextStyle(
                            fontSize: fontSizeBase - 1,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _currentIndex < total - 1
                            ? () => _goToQuestion(_currentIndex + 1)
                            : null,
                        child: Row(
                          children: [
                            Text(
                              '下一题',
                              style: TextStyle(
                                fontSize: fontSizeBase,
                                color: _currentIndex < total - 1
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                decoration: _currentIndex < total - 1
                                    ? TextDecoration.underline
                                    : null,
                                decorationColor: Colors.grey.shade400,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: fontSizeBase + 4,
                              color: _currentIndex < total - 1
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 滑动提示
                Padding(
                  padding: EdgeInsets.only(top: 4, bottom: bottomPadding > 10 ? bottomPadding * 0.5 : 4),
                  child: Text(
                    '← 左右滑动 →',
                    style: TextStyle(
                      fontSize: fontSizeBase - 4,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== 填空输入 ====================
  Widget _buildFillInput(
      Question q,
      double fontSizeBase,
      double paddingBase,
      bool isAnswered,
      ) {
    final userAnswer = _fillAnswers[q.id] ?? '';
    final correctAnswer = q.answer ?? '';
    final isCorrect = isAnswered && userAnswer.trim() == correctAnswer.trim();

    if (isAnswered) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: paddingBase * 0.6, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
          color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        ),
        child: Row(
          children: [
            Text(
              isCorrect ? '✓' : '✗',
              style: TextStyle(
                fontSize: fontSizeBase + 4,
                color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isCorrect
                    ? '回答正确'
                    : '正确答案：$correctAnswer',
                style: TextStyle(
                  fontSize: fontSizeBase + 1,
                  color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: '输入答案...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade500),
                borderRadius: BorderRadius.circular(2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: paddingBase * 0.5,
                vertical: paddingBase * 0.5,
              ),
            ),
            style: TextStyle(fontSize: fontSizeBase + 1),
            onChanged: (value) {
              setState(() => _fillAnswers[q.id] = value);
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) _handleFillSubmit(q);
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _handleFillSubmit(q),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: paddingBase * 0.6,
              vertical: paddingBase * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '确认',
              style: TextStyle(
                fontSize: fontSizeBase,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== AppBar ====================
  PreferredSizeWidget _buildNotebookAppBar(
      String title,
      String subtitle,
      double fontSizeBase,
      double topPadding,
      ) {
    return PreferredSize(
      preferredSize: Size.fromHeight(56 + topPadding),
      child: SafeArea(
        top: true,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: fontSizeBase > 14 ? 14 : 10),
          padding: EdgeInsets.symmetric(
            horizontal: fontSizeBase > 14 ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCF3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  '◀ 返回',
                  style: TextStyle(
                    fontSize: fontSizeBase + 1,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.grey.shade300,
                  ),
                ),
              ),
              SizedBox(width: fontSizeBase + 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: fontSizeBase + 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: fontSizeBase,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}