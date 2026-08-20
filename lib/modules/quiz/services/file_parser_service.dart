import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:doc_text_extractor/doc_text_extractor.dart' as docx;

import '../data/models/question_model.dart';

class FileParserService {
  // ============================================================
  // 主入口
  // ============================================================
  Future<List<Question>> parseFile(String filePath, String sourceType) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'docx':
        return await _parseWord(file);
      case 'json':
        return await _parseJson(file);
      default:
        throw Exception('不支持的文件格式: $extension（仅支持 .docx 和 .json）');
    }
  }

  // ============================================================
  // Word 解析
  // ============================================================
  Future<List<Question>> _parseWord(File file) async {
    try {
      final extractor = docx.TextExtractor();
      final result = await extractor.extractText(file.path, isUrl: false);
      final text = result.text;

      final rawLines = text
          .split('\n')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      debugPrint('📄 总共读取 ${rawLines.length} 行文本');

      final lines = _preprocessLines(rawLines);

      List<Question> questions = [];

      // 策略一：标准模式
      questions = await _parseStandardMode(lines);
      if (questions.isNotEmpty) {
        debugPrint('✅ 使用标准模式解析成功');
        return questions;
      }

      // 策略二：行内答案模式
      questions = _parseInlineMode(lines);
      if (questions.isNotEmpty) {
        debugPrint('✅ 使用行内答案模式解析成功');
        return questions;
      }

      // 策略三：纯选择题模式
      questions = _parseChoiceOnlyMode(lines);
      if (questions.isNotEmpty) {
        debugPrint('✅ 使用纯选择题模式解析成功');
        return questions;
      }

      // 策略四：紧邻答案模式（终极版）
      questions = _parseAdjacentAnswerModeUltimate(lines);
      if (questions.isNotEmpty) {
        debugPrint('✅ 使用紧邻答案模式解析成功');
        return questions;
      }

      // 策略五：无答案区模式（兜底）
      questions = _parseNoAnswerTagMode(lines);
      if (questions.isNotEmpty) {
        debugPrint('✅ 使用无答案区模式解析成功');
        return questions;
      }

      throw Exception('未识别到任何有效题目，请检查文档格式');
    } catch (e) {
      debugPrint('❌ Word解析异常: $e');
      throw Exception('Word解析失败: $e');
    }
  }

  // ============================================================
  // 预处理
  // ============================================================
  List<String> _preprocessLines(List<String> lines) {
    final filtered = <String>[];
    for (var line in lines) {
      if (RegExp(r'^第\s*\d+\s*页$|^\d+\s*/\s*\d+$').hasMatch(line)) continue;
      if (RegExp(r'^[\d\W]+$').hasMatch(line)) continue;
      if (line.contains('doc') || line.contains('Doc') || line.contains('Date')) continue;
      filtered.add(line);
    }
    return filtered;
  }

  // ============================================================
  // 策略一：标准模式
  // ============================================================
  Future<List<Question>> _parseStandardMode(List<String> lines) async {
    int answerStartIndex = _findAnswerStart(lines);
    if (answerStartIndex == -1) {
      debugPrint('⚠️ 未找到答案区，尝试其他模式');
      return [];
    }

    final questionMap = <int, String>{};
    final regex = _buildQuestionRegex();
    int i = 0;
    while (i < lines.length && (answerStartIndex == -1 || i < answerStartIndex)) {
      final line = lines[i];
      final match = regex.firstMatch(line);
      if (match != null) {
        final numStr = match.group(1) ?? match.group(2);
        if (numStr != null) {
          final qNum = int.parse(numStr);
          final blockLines = <String>[line];
          i++;
          while (i < lines.length &&
              (answerStartIndex == -1 || i < answerStartIndex) &&
              !regex.hasMatch(lines[i])) {
            final nextLine = lines[i];
            if (!_isHeaderLine(nextLine)) {
              blockLines.add(nextLine);
            }
            i++;
          }
          String blockText = blockLines.join(' ');
          blockText = blockText.replaceAll(RegExp(r'\s+'), ' ').trim();
          blockText = _stripQuestionNumber(blockText, regex);
          final extracted = _extractInlineAnswer(blockText);
          questionMap[qNum] = extracted['text']!;
        }
      } else {
        i++;
      }
    }

    if (questionMap.isEmpty) return [];

    final answerMap = <int, String>{};
    for (int j = answerStartIndex; j < lines.length; j++) {
      final line = lines[j];
      if (_isHeaderLine(line)) continue;
      final match = regex.firstMatch(line);
      if (match != null) {
        final numStr = match.group(1) ?? match.group(2);
        if (numStr != null) {
          final aNum = int.parse(numStr);
          String answerContent = line.replaceFirst(regex, '').trim();
          answerContent = _stripAnswerPrefix(answerContent);
          if (answerContent.isEmpty && j + 1 < lines.length) {
            final nextLine = lines[j + 1];
            if (!regex.hasMatch(nextLine) && nextLine.isNotEmpty) {
              answerContent = nextLine.trim();
            }
          }
          answerMap[aNum] = answerContent;
        }
      }
    }

    final questions = <Question>[];
    final sortedKeys = questionMap.keys.toList()..sort();
    for (var key in sortedKeys) {
      String questionText = questionMap[key] ?? '';
      if (questionText.isEmpty) continue;

      String? answerText = answerMap[key];
      if (answerText == null || answerText.isEmpty) {
        final extracted = _extractInlineAnswer(questionText);
        questionText = extracted['text']!;
        answerText = extracted['answer'];
      }

      if (answerText == null || answerText.isEmpty) {
        debugPrint('⚠️ 题目 $key 没有答案，跳过');
        continue;
      }

      final question = _createQuestion(questionText, answerText, key);
      if (question != null) questions.add(question);
    }

    return questions;
  }

  // ============================================================
  // 查找答案区起始
  // ============================================================
  int _findAnswerStart(List<String> lines) {
    final keywords = [
      '标准答案',
      '参考答案',
      '答案：',
      '答案:',
      '【答案】',
      '答案解析',
      '答案及解析',
      '参考答案及解析',
      '第1题答案',
      '1、答案',
      '1.答案',
    ];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (keywords.any((k) => line.contains(k))) {
        return i;
      }
      if (RegExp(r'^\d+[、. )）]\s*答案').hasMatch(line)) {
        return i;
      }
    }
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (RegExp(r'^\d+[、. )）]\s*[对错√×正确错误TtFf]').hasMatch(line)) {
        return i;
      }
    }
    return -1;
  }

  // ============================================================
  // 构建题号正则
  // ============================================================
  RegExp _buildQuestionRegex() {
    return RegExp(
      r'^(\d+)[、. )）．]\s*',
      caseSensitive: false,
    );
  }

  // ============================================================
  // 剥离题号
  // ============================================================
  String _stripQuestionNumber(String text, RegExp regex) {
    return text.replaceFirst(regex, '').trim();
  }

  // ============================================================
  // 剥离答案前缀
  // ============================================================
  String _stripAnswerPrefix(String text) {
    final prefixes = [
      r'^答案[：:]\s*',
      r'^【答案】\s*',
      r'^正确答案[：:]\s*',
      r'^标准答案[：:]\s*',
    ];
    for (var p in prefixes) {
      text = text.replaceFirst(RegExp(p, caseSensitive: false), '');
    }
    return text.trim();
  }

  // ============================================================
  // 提取行内答案（匹配到行尾）
  // ============================================================
  Map<String, String?> _extractInlineAnswer(String text) {
    final patterns = [
      r'[（(]?答案[：:]\s*(.+?)\s*$',
      r'【答案】\s*(.+?)\s*$',
      r'正确答案[：:]\s*(.+?)\s*$',
      r'标准答案[：:]\s*(.+?)\s*$',
    ];
    for (var p in patterns) {
      final match = RegExp(p, caseSensitive: false, multiLine: true).firstMatch(text);
      if (match != null) {
        var ans = match.group(1)?.trim() ?? '';
        ans = ans.replaceAll(RegExp(r'[，,。；;、]+$'), '').trim();
        if (ans.isNotEmpty) {
          final cleaned = text.replaceRange(match.start, match.end, '').trim();
          return {'text': cleaned, 'answer': ans};
        }
      }
    }
    return {'text': text, 'answer': null};
  }

  // ============================================================
  // 策略二：行内答案模式
  // ============================================================
  List<Question> _parseInlineMode(List<String> lines) {
    final questions = <Question>[];
    int index = 1;
    for (var line in lines) {
      if (line.length < 5) continue;
      if (_isHeaderLine(line)) continue;

      final extracted = _extractInlineAnswer(line);
      final answer = extracted['answer'];
      if (answer != null && answer.isNotEmpty) {
        String content = extracted['text']!;
        if (content.isEmpty) continue;
        final regex = _buildQuestionRegex();
        content = content.replaceFirst(regex, '').trim();
        final q = _createQuestion(content, answer, index);
        if (q != null) {
          questions.add(q);
          index++;
        }
      }
    }
    return questions;
  }

  // ============================================================
  // 策略三：纯选择题模式
  // ============================================================
  List<Question> _parseChoiceOnlyMode(List<String> lines) {
    final questions = <Question>[];
    int index = 1;
    String buffer = '';
    for (var line in lines) {
      if (_isHeaderLine(line)) continue;
      if (RegExp(r'^[A-D][、. )）]', caseSensitive: false).hasMatch(line)) {
        if (buffer.isNotEmpty && RegExp(r'[A-D][、. )）]', caseSensitive: false).hasMatch(buffer)) {
          final extracted = _extractInlineAnswer(buffer);
          final answer = extracted['answer'];
          final content = extracted['text']!;
          if (answer != null && answer.isNotEmpty) {
            final regex = _buildQuestionRegex();
            final cleanContent = content.replaceFirst(regex, '').trim();
            final q = _createQuestion(cleanContent, answer, index);
            if (q != null) {
              questions.add(q);
              index++;
            }
          }
          buffer = '';
        }
        buffer += '$line ';
      } else {
        buffer += '$line ';
      }
    }
    if (buffer.isNotEmpty) {
      final extracted = _extractInlineAnswer(buffer);
      final answer = extracted['answer'];
      final content = extracted['text']!;
      if (answer != null && answer.isNotEmpty) {
        final regex = _buildQuestionRegex();
        final cleanContent = content.replaceFirst(regex, '').trim();
        final q = _createQuestion(cleanContent, answer, index);
        if (q != null) questions.add(q);
      }
    }
    return questions;
  }

  // ============================================================
  // ✅ 策略四：紧邻答案模式（终极版，使用 contains 匹配答案行）
  // ============================================================
  List<Question> _parseAdjacentAnswerModeUltimate(List<String> lines) {
    final questions = <Question>[];
    final regex = _buildQuestionRegex();

    // 1. 提取所有题目块
    final questionBlocks = <int, String>{};
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final match = regex.firstMatch(line);
      if (match != null) {
        final numStr = match.group(1) ?? match.group(2);
        if (numStr != null) {
          final qNum = int.parse(numStr);
          final blockLines = <String>[line];
          i++;
          while (i < lines.length && !regex.hasMatch(lines[i]) && !_isHeaderLine(lines[i])) {
            blockLines.add(lines[i]);
            i++;
          }
          String blockText = blockLines.join(' ');
          blockText = _stripQuestionNumber(blockText, regex).trim();
          // 移除行内答案
          final extracted = _extractInlineAnswer(blockText);
          questionBlocks[qNum] = extracted['text']!;
          continue;
        }
      }
      i++;
    }

    if (questionBlocks.isEmpty) return [];

    // 2. 扫描所有行，用 contains 匹配 "答案："
    final answerMap = <int, String>{};
    for (var line in lines) {
      // 使用 contains 而不是正则，更宽松
      if (line.contains('答案：') || line.contains('答案:')) {
        // 提取答案内容
        final parts = line.split(RegExp(r'答案[：:]'));
        if (parts.length > 1) {
          var ans = parts[1].trim();
          ans = ans.replaceAll(RegExp(r'[，,。；;、]+$'), '').trim();
          if (ans.isNotEmpty) {
            // 尝试从该行提取题号
            final numMatch = regex.firstMatch(line);
            if (numMatch != null) {
              final numStr = numMatch.group(1) ?? numMatch.group(2);
              if (numStr != null) {
                final aNum = int.parse(numStr);
                answerMap[aNum] = ans;
              }
            } else {
              // 如果没有题号，按当前题目顺序匹配（但我们会用后续逻辑）
            }
          }
        }
      }
    }

    // 3. 匹配题目和答案
    for (var key in questionBlocks.keys.toList()..sort()) {
      final questionText = questionBlocks[key] ?? '';
      if (questionText.isEmpty) continue;

      String? answerText = answerMap[key];
      if (answerText == null || answerText.isEmpty) {
        final extracted = _extractInlineAnswer(questionText);
        answerText = extracted['answer'];
      }

      if (answerText == null || answerText.isEmpty) {
        debugPrint('⚠️ 题目 $key 没有找到答案');
        continue;
      }

      final q = _createQuestion(questionText, answerText, key);
      if (q != null) {
        questions.add(q);
      }
    }

    return questions;
  }

  // ============================================================
  // 策略五：无答案区模式（兜底）
  // ============================================================
  List<Question> _parseNoAnswerTagMode(List<String> lines) {
    final questions = <Question>[];
    final regex = _buildQuestionRegex();
    int questionIndex = 0;
    String? lastQuestionText;
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (regex.hasMatch(line)) {
        final match = regex.firstMatch(line)!;
        final numStr = match.group(1) ?? match.group(2);
        if (numStr != null) {
          if (lastQuestionText != null && questionIndex > 0) {
            String answer = '';
            int j = i + 1;
            while (j < lines.length && !regex.hasMatch(lines[j])) {
              final candidate = lines[j].trim();
              if (candidate.isNotEmpty && !_isHeaderLine(candidate)) {
                answer = candidate;
                break;
              }
              j++;
            }
            if (answer.isNotEmpty) {
              final q = _createQuestion(lastQuestionText, answer, questionIndex);
              if (q != null) questions.add(q);
            }
          }
          final blockLines = <String>[line];
          i++;
          while (i < lines.length && !regex.hasMatch(lines[i]) && !_isHeaderLine(lines[i])) {
            blockLines.add(lines[i]);
            i++;
          }
          lastQuestionText = blockLines.join(' ');
          lastQuestionText = _stripQuestionNumber(lastQuestionText, regex);
          questionIndex++;
          continue;
        }
      }
      i++;
    }
    if (lastQuestionText != null && questionIndex > 0) {
      for (int j = lines.length - 1; j >= 0; j--) {
        final line = lines[j];
        if (!regex.hasMatch(line) && line.trim().isNotEmpty && !_isHeaderLine(line)) {
          final ans = line.trim();
          final q = _createQuestion(lastQuestionText, ans, questionIndex);
          if (q != null) questions.add(q);
          break;
        }
      }
    }
    return questions;
  }

  // ============================================================
  // 判断标题行
  // ============================================================
  bool _isHeaderLine(String line) {
    final headers = [
      r'^第[一二三四五六七八九十百]+章',
      r'^第[0-9]+章',
      r'^[一二三四五六七八九十百]+[、. ]',
      r'^绪论',
      r'^前言',
      r'^引言',
      r'^一[、. ]选择题',
      r'^二[、. ]判断题',
      r'^三[、. ]填空题',
      r'^选择题[（(]',
      r'^判断题[（(]',
      r'^填空题[（(]',
    ];
    for (var h in headers) {
      if (RegExp(h, caseSensitive: false).hasMatch(line)) return true;
    }
    return false;
  }

  // ============================================================
  // 题型检测
  // ============================================================
  String _detectQuestionType(String content, String answer) {
    if (RegExp(r'[A-D][、. )）]', caseSensitive: false).hasMatch(content)) {
      return 'choice';
    }
    final judgeKeywords = ['对', '错', '正确', '错误', '√', '×', 't', 'f', 'true', 'false'];
    if (judgeKeywords.any((k) => answer.toLowerCase().contains(k))) {
      return 'judge';
    }
    if (RegExp(r'_{2,}|[（(]_{2,}[）)]').hasMatch(content)) {
      return 'fill';
    }
    return 'fill';
  }

  // ============================================================
  // 创建 Question
  // ============================================================
  Question? _createQuestion(String questionText, String answerText, int questionNumber) {
    final rawQuestion = questionText.trim();
    final rawAnswer = answerText.trim();
    if (rawQuestion.isEmpty || rawAnswer.isEmpty) return null;

    final type = _detectQuestionType(rawQuestion, rawAnswer);
    switch (type) {
      case 'choice':
        return _parseChoice(rawQuestion, rawAnswer, questionNumber);
      case 'judge':
        return _parseJudge(rawQuestion, rawAnswer, questionNumber);
      case 'fill':
        return _parseFill(rawQuestion, rawAnswer, questionNumber);
      default:
        return null;
    }
  }

  // ============================================================
  // 解析选择题
  // ============================================================
  Question? _parseChoice(String questionText, String answerText, int questionNumber) {
    final markerRegex = RegExp(r'([A-D])[、. )）]');
    final matches = markerRegex.allMatches(questionText);
    final Map<String, int> letterToPos = {};
    for (var match in matches) {
      final letter = match.group(1)!;
      final pos = match.start;
      if (!letterToPos.containsKey(letter)) {
        letterToPos[letter] = pos;
      }
    }

    final sortedLetters = ['A', 'B', 'C', 'D'];
    final List<int> positions = [];
    for (var letter in sortedLetters) {
      if (letterToPos.containsKey(letter)) {
        positions.add(letterToPos[letter]!);
      }
    }

    if (positions.length < 2) {
      return _parseFill(questionText, answerText, questionNumber);
    }

    List<String> options = [];
    for (int i = 0; i < positions.length; i++) {
      final start = positions[i];
      final end = (i + 1 < positions.length) ? positions[i + 1] : questionText.length;
      String opt = questionText.substring(start, end).trim();
      opt = opt.replaceFirst(RegExp(r'^[A-D][、. )）]\s*'), '').trim();
      final ansIdx = opt.indexOf('答案');
      if (ansIdx != -1) {
        opt = opt.substring(0, ansIdx).trim();
      }
      if (opt.isNotEmpty) {
        options.add(opt);
      }
    }

    if (options.isEmpty) return null;

    final firstPos = positions.first;
    String content = questionText.substring(0, firstPos).trim();

    int correctIndex = 0;
    final letter = answerText.trim().toUpperCase();
    final idx = 'ABCD'.indexOf(letter);
    if (idx != -1 && idx < options.length) {
      correctIndex = idx;
    }

    return Question(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
      content: content,
      options: options,
      correctIndex: correctIndex,
      source: 'word',
    );
  }

  // ============================================================
  // 解析判断题
  // ============================================================
  Question? _parseJudge(String questionText, String answerText, int questionNumber) {
    String content = questionText.trim();
    content = content.replaceFirst(RegExp(r'[（(]\s*[）)]\s*$'), '').trim();

    int correctIndex = 0;
    final ans = answerText.trim().toLowerCase();

    if (['对', '正确', '√', 't', 'true', '是'].contains(ans)) {
      correctIndex = 0;
    } else if (['错', '错误', '×', 'f', 'false', '否'].contains(ans)) {
      correctIndex = 1;
    }
    return Question(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
      content: content,
      options: ['正确', '错误'],
      correctIndex: correctIndex,
      source: 'word',
    );
  }

  // ============================================================
  // 解析填空题
  // ============================================================
  Question? _parseFill(String questionText, String answerText, int questionNumber) {
    String content = questionText.trim();

    if (!RegExp(r'_{2,}|[（(]_{2,}[）)]').hasMatch(content)) {
      content = '$content（____）';
    }

    return Question(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
      content: content,
      options: ['（填空题）'],
      correctIndex: 0,
      source: 'word',
      answer: answerText.trim(),
    );
  }

  // ============================================================
  // JSON 解析
  // ============================================================
  Future<List<Question>> _parseJson(File file) async {
    try {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);

      List<dynamic> questionsData;
      if (jsonData is List) {
        questionsData = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('questions')) {
        questionsData = jsonData['questions'] as List;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        questionsData = jsonData['data'] as List;
      } else if (jsonData is Map && jsonData.containsKey('list')) {
        questionsData = jsonData['list'] as List;
      } else {
        throw Exception('JSON格式不支持，请使用数组或包含questions/data字段的对象');
      }

      final questions = <Question>[];
      for (var item in questionsData) {
        try {
          String rawContent = item['content']?.toString() ??
              item['question']?.toString() ??
              item['title']?.toString() ??
              '';
          rawContent = rawContent.trim();

          final extracted = _extractInlineAnswer(rawContent);
          rawContent = extracted['text']!;
          String? answer = extracted['answer'] ??
              item['answer']?.toString() ??
              item['correct']?.toString() ??
              item['correctAnswer']?.toString() ??
              '';

          List<String> options = [];
          if (item['options'] != null && (item['options'] as List).isNotEmpty) {
            options = (item['options'] as List).map((e) => e.toString()).toList();
          } else if (item['option'] != null && (item['option'] as List).isNotEmpty) {
            options = (item['option'] as List).map((e) => e.toString()).toList();
          } else if (item['choices'] != null && (item['choices'] as List).isNotEmpty) {
            options = (item['choices'] as List).map((e) => e.toString()).toList();
          } else if (item['type'] == 'judge') {
            options = ['正确', '错误'];
          }

          if (options.isEmpty) {
            if (RegExp(r'[A-D][、. )）]').hasMatch(rawContent)) {
              final optMatches = RegExp(r'([A-D])[、. )）]\s*([^A-D]*?)(?=\s*[A-D][、. )）]|$)')
                  .allMatches(rawContent);
              if (optMatches.length >= 2) {
                options = optMatches
                    .map((m) => m.group(2)?.trim() ?? '')
                    .where((s) => s.isNotEmpty)
                    .toList();
              }
            } else if (RegExp(r'答案[：:]\s*[对错√×正确错误]', caseSensitive: false)
                .hasMatch(rawContent)) {
              options = ['正确', '错误'];
            } else {
              options = ['（填空题）'];
            }
          }

          int correctIndex = 0;
          if (item['correctIndex'] != null) {
            correctIndex = item['correctIndex'] as int;
          } else if (item['correct'] != null) {
            if (item['correct'] is int) {
              correctIndex = item['correct'];
            } else {
              final ansStr = item['correct'].toString();
              if (options.isNotEmpty) {
                if (['正确', '对', '√', 't', 'true'].contains(ansStr.toLowerCase())) {
                  correctIndex = 0;
                } else if (['错误', '错', '×', 'f', 'false'].contains(ansStr.toLowerCase())) {
                  correctIndex = options.length == 2 ? 1 : 0;
                } else {
                  final letter = ansStr.toUpperCase().trim();
                  final idx = 'ABCD'.indexOf(letter);
                  if (idx != -1 && idx < options.length) {
                    correctIndex = idx;
                  }
                }
              }
            }
          } else if (answer.isNotEmpty && options.isNotEmpty) {
            final ansStr = answer.toString();
            if (['正确', '对', '√', 't', 'true'].contains(ansStr.toLowerCase())) {
              correctIndex = 0;
            } else if (['错误', '错', '×', 'f', 'false'].contains(ansStr.toLowerCase())) {
              correctIndex = options.length == 2 ? 1 : 0;
            } else {
              final letter = ansStr.toUpperCase().trim();
              final idx = 'ABCD'.indexOf(letter);
              if (idx != -1 && idx < options.length) {
                correctIndex = idx;
              }
            }
          }

          final q = Question(
            id: item['id']?.toString() ??
                'import_${DateTime.now().millisecondsSinceEpoch}_${questions.length}',
            content: rawContent,
            options: options.isNotEmpty ? options : ['（填空题）'],
            correctIndex: correctIndex,
            source: 'json',
            answer: options.isEmpty || options.first.contains('填空') ? answer : null,
          );

          if (q.content.isNotEmpty) {
            questions.add(q);
          }
        } catch (e) {
          debugPrint('⚠️ 跳过一条无效题目: $e');
          continue;
        }
      }

      if (questions.isEmpty) {
        throw Exception('JSON中未找到有效题目');
      }

      return questions;
    } catch (e) {
      throw Exception('JSON解析失败: $e');
    }
  }
}