import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../bloc/quiz_bloc.dart';
import 'quiz_page.dart';

enum SaveActionType { overwrite, append, newSet, cancel }

class SaveAction {
  final SaveActionType type;
  final String? newName;
  SaveAction(this.type, {this.newName});
}

enum _CardDensity { compact, normal, spacious }

class ManualImportPage extends StatefulWidget {
  final String? currentSetName;
  const ManualImportPage({super.key, this.currentSetName});

  @override
  State<ManualImportPage> createState() => _ManualImportPageState();
}

class _ManualImportPageState extends State<ManualImportPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  List<Question> _parsedQuestions = [];
  bool _isParsing = false;

  // 可调参数
  _CardDensity _density = _CardDensity.normal;
  double _textScale = 1.0;
  int _inputLines = 15;

  // 持久化键名
  static const String _keyDensity = 'manual_import_density';
  static const String _keyTextScale = 'manual_import_text_scale';
  static const String _keyInputLines = 'manual_import_input_lines';

  @override
  void initState() {
    super.initState();
    // 延迟加载确保 context 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  // ---------- 加载保存的设置 ----------
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final densityStr = prefs.getString(_keyDensity) ?? 'normal';
      final scale = prefs.getDouble(_keyTextScale) ?? 1.0;
      final lines = prefs.getInt(_keyInputLines) ?? 15;

      if (mounted) {
        setState(() {
          _density = _fromString(densityStr);
          _textScale = scale.clamp(0.8, 1.4);
          _inputLines = lines.clamp(5, 25);
        });
      }
    } catch (e) {
      // 保持默认
    }
  }

  _CardDensity _fromString(String s) {
    switch (s) {
      case 'compact':
        return _CardDensity.compact;
      case 'spacious':
        return _CardDensity.spacious;
      default:
        return _CardDensity.normal;
    }
  }

  // ---------- 保存设置 ----------
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDensity, _density.name);
      await prefs.setDouble(_keyTextScale, _textScale);
      await prefs.setInt(_keyInputLines, _inputLines);
    } catch (e) {
      // 忽略
    }
  }

  // ============================================================
  // 样式计算
  // ============================================================
  double get _cardMargin =>
      (_density == _CardDensity.compact ? 2.0 : (_density == _CardDensity.normal ? 4.0 : 8.0)) * _textScale;
  double get _listTilePaddingVertical =>
      (_density == _CardDensity.compact ? 2.0 : (_density == _CardDensity.normal ? 4.0 : 8.0)) * _textScale;
  double get _listTilePaddingHorizontal =>
      (_density == _CardDensity.compact ? 8.0 : (_density == _CardDensity.normal ? 12.0 : 16.0)) * _textScale;
  double get _titleFontSize =>
      (_density == _CardDensity.compact ? 12.0 : (_density == _CardDensity.normal ? 14.0 : 16.0)) * _textScale;
  double get _subtitleFontSize =>
      (_density == _CardDensity.compact ? 10.0 : (_density == _CardDensity.normal ? 12.0 : 14.0)) * _textScale;
  double get _circleRadius =>
      (_density == _CardDensity.compact ? 12.0 : (_density == _CardDensity.normal ? 15.0 : 18.0)) * _textScale;
  double get _circleFontSize =>
      (_density == _CardDensity.compact ? 10.0 : (_density == _CardDensity.normal ? 12.0 : 14.0)) * _textScale;
  double get _deleteIconSize =>
      (_density == _CardDensity.compact ? 16.0 : (_density == _CardDensity.normal ? 20.0 : 24.0)) * _textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 手动添加题目'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDisplaySettings,
            tooltip: '显示设置',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _parsedQuestions.isEmpty ? null : _saveQuestions,
            tooltip: '保存到题库',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final basePadding = isWide ? 24.0 : 16.0;
          final cardPadding = isWide ? 16.0 : 12.0;

          return Padding(
            padding: EdgeInsets.all(basePadding),
            child: Column(
              children: [
                // ========== 输入卡片 ==========
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding * _textScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋 粘贴题目内容',
                          style: TextStyle(
                            fontSize: 16 * _textScale,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 6 * _textScale),
                        Text(
                          '支持格式：1. 题目\n答案：xxx\n或直接粘贴带“答案：”的文本',
                          style: TextStyle(
                            fontSize: 12 * _textScale,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8 * _textScale),
                        TextField(
                          controller: _inputController,
                          maxLines: _inputLines,
                          decoration: InputDecoration(
                            hintText: '粘贴题目内容...\n\n示例：\n1. 金属的三种晶体结构？\n答案：体心立方、面心立方、密排六方\n\n2. 晶体缺陷分为？\n答案：点缺陷、线缺陷、面缺陷',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant,
                            hintStyle: TextStyle(fontSize: 14 * _textScale),
                          ),
                          style: TextStyle(fontSize: 14 * _textScale),
                        ),
                        SizedBox(height: 10 * _textScale),
                        Wrap(
                          spacing: 8 * _textScale,
                          runSpacing: 8 * _textScale,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isParsing ? null : _parseInput,
                              icon: _isParsing
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(_isParsing ? '解析中...' : '解析并预览'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _inputController.clear();
                                setState(() => _parsedQuestions.clear());
                              },
                              child: Text('清空', style: TextStyle(fontSize: 14 * _textScale)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_paste),
                              onPressed: _pasteFromClipboard,
                              tooltip: '从剪贴板粘贴',
                              iconSize: 24 * _textScale,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12 * _textScale),

                // ========== 快速控制条（修复溢出：改用 Wrap） ==========
                Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Text('密度：', style: TextStyle(fontSize: 13)),
                      SegmentedButton<_CardDensity>(
                        segments: const [
                          ButtonSegment(
                            value: _CardDensity.compact,
                            label: Text('紧凑'),
                            icon: Icon(Icons.compress, size: 16),
                          ),
                          ButtonSegment(
                            value: _CardDensity.normal,
                            label: Text('正常'),
                            icon: Icon(Icons.rectangle, size: 16),
                          ),
                          ButtonSegment(
                            value: _CardDensity.spacious,
                            label: Text('宽松'),
                            icon: Icon(Icons.open_in_full, size: 16),
                          ),
                        ],
                        selected: {_density},
                        onSelectionChanged: (set) => setState(() => _density = set.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const Text('缩放', style: TextStyle(fontSize: 13)),
                      SizedBox(
                        width: 80,
                        child: Slider(
                          value: _textScale,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          label: _textScale.toStringAsFixed(1),
                          onChanged: (v) => setState(() => _textScale = v),
                          onChangeEnd: (_) => _saveSettings(),
                        ),
                      ),
                      Text('${(_textScale * 100).round()}%', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ========== 解析结果列表 ==========
                Expanded(
                  child: _parsedQuestions.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 60 * _textScale,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16 * _textScale),
                        Text(
                          '解析后的题目将显示在这里',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14 * _textScale,
                          ),
                        ),
                        Text(
                          '共 ${_parsedQuestions.length} 道题',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12 * _textScale,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========== 题目计数 + 清空按钮（修复溢出） ==========
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '✅ 已解析 ${_parsedQuestions.length} 道题',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * _textScale,
                                color: theme.colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _parsedQuestions.clear();
                                _inputController.clear();
                              });
                            },
                            icon: Icon(Icons.clear_all, size: 16 * _textScale),
                            label: Text('清空全部', style: TextStyle(fontSize: 14 * _textScale)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _parsedQuestions.length,
                          itemBuilder: (context, index) {
                            final q = _parsedQuestions[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: _cardMargin),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                dense: _density != _CardDensity.spacious,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: _listTilePaddingHorizontal,
                                  vertical: _listTilePaddingVertical,
                                ),
                                leading: CircleAvatar(
                                  radius: _circleRadius,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: _circleFontSize,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  q.content.length > 50
                                      ? '${q.content.substring(0, 50)}...'
                                      : q.content,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: _titleFontSize,
                                  ),
                                ),
                                subtitle: Text(
                                  '📚 ${_getTypeName(q)}  |  答案：${_getAnswerText(q)}',
                                  style: TextStyle(
                                    fontSize: _subtitleFontSize,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: _deleteIconSize,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _parsedQuestions.removeAt(index);
                                    });
                                  },
                                ),
                                onTap: () => _editQuestion(index),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 显示设置对话框（适配屏幕）
  // ============================================================
  void _showDisplaySettings() {
    int tempLines = _inputLines;
    double tempScale = _textScale;
    _CardDensity tempDensity = _density;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('显示设置'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 密度
                  Row(
                    children: [
                      const Text('密度：'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<_CardDensity>(
                          segments: const [
                            ButtonSegment(value: _CardDensity.compact, label: Text('紧凑')),
                            ButtonSegment(value: _CardDensity.normal, label: Text('正常')),
                            ButtonSegment(value: _CardDensity.spacious, label: Text('宽松')),
                          ],
                          selected: {tempDensity},
                          onSelectionChanged: (set) => setDialogState(() => tempDensity = set.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 字体缩放
                  Row(
                    children: [
                      const Text('字体缩放：'),
                      Expanded(
                        child: Slider(
                          value: tempScale,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          label: tempScale.toStringAsFixed(1),
                          onChanged: (v) => setDialogState(() => tempScale = v),
                        ),
                      ),
                      Text('${(tempScale * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 输入框行数
                  Row(
                    children: [
                      const Text('输入框行数：'),
                      Expanded(
                        child: Slider(
                          value: tempLines.toDouble(),
                          min: 5,
                          max: 25,
                          divisions: 20,
                          label: tempLines.toString(),
                          onChanged: (v) => setDialogState(() => tempLines = v.round()),
                        ),
                      ),
                      Text('$tempLines'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _inputLines = tempLines;
                _textScale = tempScale;
                _density = tempDensity;
              });
              await _saveSettings();
              Navigator.pop(ctx);
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 粘贴剪贴板
  // ============================================================
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _inputController.text = data.text!;
      });
    }
  }

  // ============================================================
  // 解析输入（与之前相同）
  // ============================================================
  void _parseInput() {
    setState(() => _isParsing = true);

    final text = _inputController.text;
    if (text.trim().isEmpty) {
      _showSnackBar('请先粘贴题目内容', isError: true);
      setState(() => _isParsing = false);
      return;
    }

    final blocks = _splitIntoBlocks(text);
    final questions = <Question>[];
    int index = 1;

    for (var block in blocks) {
      final q = _parseSingleBlock(block, index);
      if (q != null) {
        questions.add(q);
        index++;
      }
    }

    setState(() {
      _parsedQuestions = questions;
      _isParsing = false;
    });

    if (questions.isEmpty) {
      _showSnackBar('未解析到任何题目，请检查格式', isError: true);
    } else {
      _showSnackBar('✅ 成功解析 ${questions.length} 道题');
    }
  }

  // ============================================================
  // 以下辅助方法（保持不变）
  // ============================================================
  List<String> _splitIntoBlocks(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final hasNumber = lines.any((l) => RegExp(r'^\d+[、. )）]').hasMatch(l));
    if (hasNumber) {
      final blocks = <String>[];
      String current = '';
      for (var line in lines) {
        if (RegExp(r'^\d+[、. )）]').hasMatch(line)) {
          if (current.isNotEmpty) blocks.add(current);
          current = line;
        } else {
          current += '\n$line';
        }
      }
      if (current.isNotEmpty) blocks.add(current);
      return blocks;
    } else {
      return text.split(RegExp(r'\n\s*\n')).where((b) => b.trim().isNotEmpty).toList();
    }
  }

  Question? _parseSingleBlock(String block, int index) {
    final answerRegex = RegExp(r'(?:答案|正确答案|参考答案|解析|Answer|answer)[：:]\s*(.+)', caseSensitive: false);
    final answerMatch = answerRegex.firstMatch(block);
    if (answerMatch == null) return null;

    String answerText = answerMatch.group(1)?.trim() ?? '';
    String questionPart = block.replaceFirst(answerRegex, '').trim();
    questionPart = questionPart.replaceFirst(RegExp(r'^\d+[、. )）]\s*'), '');

    final hasOptions = RegExp(r'[A-D][、. )）]').hasMatch(questionPart);
    if (hasOptions) {
      final options = _extractOptions(questionPart);
      final cleanContent = _removeOptionsFromText(questionPart);
      if (options.isEmpty) return null;

      int correctIndex = 0;
      final trimmedAns = answerText.toUpperCase().replaceAll(RegExp(r'\s+'), '');
      if (RegExp(r'^[A-D]+$').hasMatch(trimmedAns)) {
        final indices = trimmedAns.split('').map((c) => 'ABCD'.indexOf(c)).where((i) => i >= 0).toList();
        if (indices.isNotEmpty) correctIndex = indices.first;
      } else {
        final matchedIndex = options.indexWhere((opt) => opt.contains(answerText));
        correctIndex = matchedIndex != -1 ? matchedIndex : 0;
      }

      return Question(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}_$index',
        content: cleanContent,
        options: options,
        correctIndex: correctIndex,
        source: 'manual',
      );
    } else {
      final judgeKeywords = ['对', '错', '正确', '错误', '√', '×'];
      if (judgeKeywords.any((k) => answerText.contains(k))) {
        final isCorrect = ['对', '正确', '√'].contains(answerText.trim());
        return Question(
          id: 'manual_${DateTime.now().millisecondsSinceEpoch}_$index',
          content: questionPart,
          options: ['正确', '错误'],
          correctIndex: isCorrect ? 0 : 1,
          source: 'manual',
        );
      }
      return Question(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}_$index',
        content: questionPart,
        options: ['（填空题）'],
        correctIndex: 0,
        source: 'manual',
        answer: answerText,
      );
    }
  }

  List<String> _extractOptions(String text) {
    final lines = text.split('\n');
    final optionLines = <String>[];
    for (var line in lines) {
      final trimmed = line.trim();
      if (RegExp(r'^[A-D][、. )）]').hasMatch(trimmed)) {
        optionLines.add(trimmed);
      } else if (optionLines.isNotEmpty) {
        optionLines[optionLines.length - 1] += ' ' + trimmed;
      }
    }
    final combined = optionLines.join('\n');
    final matches = RegExp(r'([A-D])[、. )）]\s*([^A-D]*?)(?=\s*[A-D][、. )）]|$)')
        .allMatches(combined);
    return matches.map((m) => m.group(2)?.trim() ?? '').where((s) => s.isNotEmpty).toList();
  }

  String _removeOptionsFromText(String text) {
    return text.replaceAll(RegExp(r'[A-D][、. )）]\s*[^A-D]*'), '').trim();
  }

  // ============================================================
  // 编辑题目（增强版）
  // ============================================================
  void _editQuestion(int index) async {
    final q = _parsedQuestions[index];

    final isJudge = q.options.length == 2 && q.options.contains('正确') && q.options.contains('错误');
    final isFill = q.options.length == 1 && q.options.first.contains('填空');
    final isChoice = !isJudge && !isFill && q.options.length >= 2;

    String content = q.content;
    List<String> options = List.from(q.options);
    int correctIndex = q.correctIndex;
    String? answer = q.answer;

    if (isChoice && (correctIndex < 0 || correctIndex >= options.length)) {
      correctIndex = 0;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Widget buildContent() {
              if (isJudge) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: content,
                      decoration: const InputDecoration(labelText: '题目内容'),
                      onChanged: (value) => content = value,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const Text('正确答案：'),
                    ToggleButtons(
                      isSelected: [correctIndex == 0, correctIndex == 1],
                      onPressed: (int newIndex) {
                        setDialogState(() {
                          correctIndex = newIndex;
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('正确'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('错误'),
                        ),
                      ],
                    ),
                  ],
                );
              } else if (isFill) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: content,
                      decoration: const InputDecoration(labelText: '题目内容'),
                      onChanged: (value) => content = value,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: answer ?? '',
                      decoration: const InputDecoration(labelText: '答案'),
                      onChanged: (value) => answer = value,
                    ),
                  ],
                );
              } else if (isChoice) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: content,
                      decoration: const InputDecoration(labelText: '题目内容'),
                      onChanged: (value) => content = value,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const Text('选项（点击圆圈选择正确答案）：'),
                    ...List.generate(options.length, (optIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: optIndex,
                              groupValue: correctIndex,
                              onChanged: (value) {
                                setDialogState(() {
                                  correctIndex = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: options[optIndex],
                                decoration: InputDecoration(
                                  hintText: '选项 ${String.fromCharCode(65 + optIndex)}',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onChanged: (value) {
                                  options[optIndex] = value;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (options.length <= 2) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(content: Text('至少保留两个选项')),
                                  );
                                  return;
                                }
                                setDialogState(() {
                                  options.removeAt(optIndex);
                                  if (correctIndex >= options.length) {
                                    correctIndex = options.length - 1;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          options.add('新选项');
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('添加选项'),
                    ),
                  ],
                );
              } else {
                return const Text('未知题型');
              }
            }

            return AlertDialog(
              title: Text('编辑${isJudge ? '判断' : isFill ? '填空' : '选择'}题'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [buildContent()],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, {
                      'content': content,
                      'options': options,
                      'correctIndex': correctIndex,
                      'answer': answer,
                    });
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        final newQ = Question(
          id: q.id,
          content: result['content'] as String,
          options: result['options'] as List<String>,
          correctIndex: result['correctIndex'] as int,
          source: q.source,
          answer: result['answer'] as String?,
        );
        _parsedQuestions[index] = newQ;
      });
    }
  }

  // ============================================================
  // 保存逻辑（含四个选项）
  // ============================================================
  Future<void> _saveQuestions() async {
    if (_parsedQuestions.isEmpty) return;

    if (widget.currentSetName != null && widget.currentSetName!.isNotEmpty) {
      final action = await _showSaveOptionsDialog(
        context,
        currentName: widget.currentSetName!,
      );
      if (action == null) return;

      switch (action.type) {
        case SaveActionType.overwrite:
          await _doSave(widget.currentSetName!, overwrite: true);
          break;
        case SaveActionType.append:
          await _doSave(widget.currentSetName!, overwrite: false);
          break;
        case SaveActionType.newSet:
          final newName = action.newName;
          if (newName == null || newName.isEmpty) return;
          await _doSave(newName, overwrite: true);
          break;
        case SaveActionType.cancel:
          return;
      }
    } else {
      final name = await _showSetNameDialog(context);
      if (name == null || name.isEmpty) return;
      await _doSave(name, overwrite: false);
    }
  }

  Future<void> _doSave(String setName, {bool overwrite = false}) async {
    try {
      final repository = QuestionRepository();
      List<Question> finalQuestions;

      if (overwrite) {
        finalQuestions = List.from(_parsedQuestions);
      } else {
        final existing = await repository.getQuestions(setName: setName);
        finalQuestions = [...existing, ..._parsedQuestions];
      }

      await repository.saveQuestions(finalQuestions, setName: setName);
      context.read<QuizBloc>().add(LoadQuizSetList());

      if (mounted) {
        _showSnackBar('✅ 成功保存 ${_parsedQuestions.length} 道题到 "$setName"');

        setState(() {
          _parsedQuestions.clear();
          _inputController.clear();
          _titleController.clear();
        });

        if (widget.currentSetName == setName) {
          Navigator.pop(context, true);
        } else {
          final goToQuiz = await _showGoToQuizDialog(context, setName);
          if (goToQuiz == true) {
            // ✅ 修复：传递 QuizBloc
            final quizBloc = context.read<QuizBloc>();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: quizBloc,
                  child: QuizPage(setName: setName),
                ),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      _showSnackBar('保存失败: $e', isError: true);
    }
  }

  // ============================================================
  // 各种对话框
  // ============================================================
  Future<SaveAction?> _showSaveOptionsDialog(BuildContext context, {required String currentName}) {
    String newSetName = '';
    bool isCreatingNew = false;
    return showDialog<SaveAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('保存选项'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCreatingNew) ...[
                      const Text('当前题库：', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(currentName, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      const Text('请选择操作：'),
                    ],
                    if (!isCreatingNew)
                      Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.add, color: Colors.green),
                            title: const Text('追加到当前题库'),
                            onTap: () => Navigator.pop(ctx, SaveAction(SaveActionType.append)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.refresh, color: Colors.orange),
                            title: const Text('覆盖当前题库'),
                            onTap: () => Navigator.pop(ctx, SaveAction(SaveActionType.overwrite)),
                          ),
                        ],
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.create_new_folder, color: Colors.blue),
                      title: const Text('创建新题库'),
                      onTap: () {
                        setDialogState(() {
                          isCreatingNew = true;
                        });
                      },
                    ),
                    if (isCreatingNew) ...[
                      const SizedBox(height: 8),
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: '新题库名称',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => newSetName = value,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                isCreatingNew = false;
                                newSetName = '';
                              });
                            },
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (newSetName.trim().isNotEmpty) {
                                Navigator.pop(ctx, SaveAction(SaveActionType.newSet, newName: newSetName.trim()));
                              }
                            },
                            child: const Text('创建'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, SaveAction(SaveActionType.cancel)),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showGoToQuizDialog(BuildContext context, String setName) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('导入成功 🎉'),
        content: Text('已保存到 "$setName"，是否立即开始刷题？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('稍后'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('立即刷题'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showSetNameDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保存到哪个题库？'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入题库名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 辅助方法
  // ============================================================
  String _getTypeName(Question q) {
    if (q.options.length == 2 && q.options.contains('正确') && q.options.contains('错误')) {
      return '判断题';
    } else if (q.options.length == 1 && q.options.first.contains('填空')) {
      return '填空题';
    } else {
      return '选择题';
    }
  }

  String _getAnswerText(Question q) {
    if (q.options.length == 2 && q.options.contains('正确') && q.options.contains('错误')) {
      return q.correctIndex == 0 ? '正确' : '错误';
    }
    if (q.answer != null && q.answer!.isNotEmpty) {
      return q.answer!;
    }
    if (q.options.isNotEmpty && q.correctIndex < q.options.length) {
      return q.options[q.correctIndex];
    }
    return '已设置';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}