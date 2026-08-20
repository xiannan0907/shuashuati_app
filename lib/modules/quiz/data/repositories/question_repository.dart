import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'dart:convert';
import '../models/question_model.dart';
import '../models/wrong_question_stats.dart';
import '../../../../data/repositories/notification_repository.dart'; // ✅ 新增

class QuestionRepository {
  static const String boxName = 'questionsBox';
  static const String setsBoxName = 'quizSetsBox';
  static const String setsKey = 'sets';
  static const String currentSetKey = 'currentSet';
  static const String currentIndexKey = 'currentIndex';
  static const String wrongQuestionsBoxName = 'wrongQuestionsBox';
  static const String wrongStatsBoxName = 'wrongStatsBox';

  String _getBoxName(String setName) {
    return '${boxName}_${Uri.encodeComponent(setName)}';
  }

  // ---------- 获取所有题库名称 ----------
  Future<List<String>> getAllSetNames() async {
    try {
      final setsBox = await Hive.openBox<String>(setsBoxName);
      List<String> setNames = [];

      final setsData = setsBox.get(setsKey);
      if (setsData != null && setsData.isNotEmpty) {
        setNames = setsData.split(',').toList();
      }

      if (setNames.isEmpty) {
        setNames = ['默认题库'];
        await setsBox.put(setsKey, setNames.join(','));
        await setsBox.put(currentSetKey, '默认题库');
      }

      return setNames;
    } catch (e) {
      debugPrint('❌ 获取题库列表失败: $e');
      return ['默认题库'];
    }
  }

  Future<void> _saveSetNames(List<String> names) async {
    final setsBox = await Hive.openBox<String>(setsBoxName);
    await setsBox.put(setsKey, names.join(','));
  }

  Future<String?> getCurrentSetName() async {
    try {
      final setsBox = await Hive.openBox<String>(setsBoxName);
      String? current = setsBox.get(currentSetKey);
      if (current == null || current.isEmpty) {
        final names = await getAllSetNames();
        if (names.isNotEmpty) {
          current = names.first;
          await setsBox.put(currentSetKey, current);
        }
      }
      return current;
    } catch (e) {
      return '默认题库';
    }
  }

  Future<void> setCurrentSetName(String name) async {
    try {
      final setsBox = await Hive.openBox<String>(setsBoxName);
      await setsBox.put(currentSetKey, name);
      final names = await getAllSetNames();
      if (!names.contains(name)) {
        names.add(name);
        await _saveSetNames(names);
      }
    } catch (e) {
      debugPrint('❌ 设置当前题库失败: $e');
    }
  }

  // ---------- 索引 ----------
  Future<void> saveCurrentIndex(int index, {String? setName}) async {
    try {
      final name = setName ?? (await getCurrentSetName() ?? '默认题库');
      final key = '${currentIndexKey}_${Uri.encodeComponent(name)}';
      final box = await Hive.openBox<String>(setsBoxName);
      await box.put(key, index.toString());
    } catch (e) {
      debugPrint('❌ 保存索引失败: $e');
    }
  }

  Future<int> getCurrentIndex({String? setName}) async {
    try {
      final name = setName ?? (await getCurrentSetName() ?? '默认题库');
      final key = '${currentIndexKey}_${Uri.encodeComponent(name)}';
      final box = await Hive.openBox<String>(setsBoxName);
      final value = box.get(key);
      return value != null ? int.tryParse(value) ?? 0 : 0;
    } catch (e) {
      return 0;
    }
  }

  // ---------- 筛选类型 ----------
  Future<void> saveFilterType(String setName, String filterType) async {
    try {
      final setsBox = await Hive.openBox<String>(setsBoxName);
      final key = 'filterType_${Uri.encodeComponent(setName)}';
      await setsBox.put(key, filterType);
    } catch (e) {
      debugPrint('❌ 保存筛选类型失败: $e');
    }
  }

  Future<String> getFilterType(String setName) async {
    try {
      final setsBox = await Hive.openBox<String>(setsBoxName);
      final key = 'filterType_${Uri.encodeComponent(setName)}';
      return setsBox.get(key) ?? '全部';
    } catch (e) {
      return '全部';
    }
  }

  // ---------- 显示索引 ----------
  Future<void> saveDisplayIndex(String setName, int index) async {
    try {
      final setsBox = await Hive.openBox<String>(setsBoxName);
      final key = 'displayIndex_${Uri.encodeComponent(setName)}';
      await setsBox.put(key, index.toString());
    } catch (e) {
      debugPrint('❌ 保存显示索引失败: $e');
    }
  }

  Future<int> getDisplayIndex(String setName) async {
    try {
      final setsBox = await Hive.openBox<String>(setsBoxName);
      final key = 'displayIndex_${Uri.encodeComponent(setName)}';
      final value = setsBox.get(key);
      return value != null ? int.tryParse(value) ?? 0 : 0;
    } catch (e) {
      return 0;
    }
  }

  // ---------- 创建 ----------
  Future<void> createSet(String name) async {
    try {
      final names = await getAllSetNames();
      if (!names.contains(name)) {
        names.add(name);
        await _saveSetNames(names);
      }
      await setCurrentSetName(name);
      await saveCurrentIndex(0, setName: name);
    } catch (e) {
      debugPrint('❌ 创建题库失败: $e');
      rethrow;
    }
  }

  // ---------- 删除 ----------
  Future<void> deleteSet(String name) async {
    try {
      final names = await getAllSetNames();
      if (!names.contains(name)) return;
      names.remove(name);
      await _saveSetNames(names);

      final questionBox = await Hive.openBox<Question>(_getBoxName(name));
      await questionBox.clear();
      await questionBox.close();
      await Hive.deleteBoxFromDisk(_getBoxName(name));

      final setsBox = await Hive.openBox<String>(setsBoxName);
      final indexKey = '${currentIndexKey}_${Uri.encodeComponent(name)}';
      await setsBox.delete(indexKey);

      final filterKey = 'filterType_${Uri.encodeComponent(name)}';
      final displayKey = 'displayIndex_${Uri.encodeComponent(name)}';
      await setsBox.delete(filterKey);
      await setsBox.delete(displayKey);

      final current = setsBox.get(currentSetKey);
      if (current == name) {
        if (names.isNotEmpty) {
          await setsBox.put(currentSetKey, names.first);
        } else {
          await setsBox.put(currentSetKey, '默认题库');
          await createSet('默认题库');
        }
      }
    } catch (e) {
      debugPrint('❌ 删除题库失败: $e');
      rethrow;
    }
  }

  // ---------- 重命名 ----------
  Future<void> renameSet(String oldName, String newName) async {
    try {
      final names = await getAllSetNames();
      final index = names.indexOf(oldName);
      if (index == -1) {
        throw Exception('找不到题库 "$oldName"');
      }
      names[index] = newName;
      await _saveSetNames(names);

      final setsBox = await Hive.openBox<String>(setsBoxName);
      final current = setsBox.get(currentSetKey);
      if (current == oldName) {
        await setsBox.put(currentSetKey, newName);
      }

      final oldIndexKey = '${currentIndexKey}_${Uri.encodeComponent(oldName)}';
      final newIndexKey = '${currentIndexKey}_${Uri.encodeComponent(newName)}';
      final oldIndex = setsBox.get(oldIndexKey);
      if (oldIndex != null) {
        await setsBox.delete(oldIndexKey);
        await setsBox.put(newIndexKey, oldIndex);
      }

      final oldFilterKey = 'filterType_${Uri.encodeComponent(oldName)}';
      final newFilterKey = 'filterType_${Uri.encodeComponent(newName)}';
      final oldFilter = setsBox.get(oldFilterKey);
      if (oldFilter != null) {
        await setsBox.delete(oldFilterKey);
        await setsBox.put(newFilterKey, oldFilter);
      }

      final oldDisplayKey = 'displayIndex_${Uri.encodeComponent(oldName)}';
      final newDisplayKey = 'displayIndex_${Uri.encodeComponent(newName)}';
      final oldDisplay = setsBox.get(oldDisplayKey);
      if (oldDisplay != null) {
        await setsBox.delete(oldDisplayKey);
        await setsBox.put(newDisplayKey, oldDisplay);
      }

      final oldBoxName = _getBoxName(oldName);
      final newBoxName = _getBoxName(newName);
      final oldBox = await Hive.openBox<Question>(oldBoxName);
      final questions = oldBox.values.toList();
      await oldBox.clear();
      await oldBox.close();

      final newBox = await Hive.openBox<Question>(newBoxName);
      for (int i = 0; i < questions.length; i++) {
        await newBox.put(i, questions[i]);
      }
      await newBox.close();
      await Hive.deleteBoxFromDisk(oldBoxName);
    } catch (e) {
      debugPrint('❌ 重命名失败: $e');
      rethrow;
    }
  }

  // ---------- 获取题目 ----------
  Future<List<Question>> getQuestions({String? setName}) async {
    try {
      final name = setName ?? (await getCurrentSetName() ?? '默认题库');
      final box = await Hive.openBox<Question>(_getBoxName(name));
      return box.values.toList();
    } catch (e) {
      debugPrint('❌ getQuestions 失败: $e');
      return [];
    }
  }

  // ---------- 保存题目 ----------
  Future<void> saveQuestions(List<Question> questions, {String? setName}) async {
    try {
      final name = setName ?? (await getCurrentSetName() ?? '默认题库');
      await setCurrentSetName(name);
      final box = await Hive.openBox<Question>(_getBoxName(name));
      await box.clear();
      const int pageSize = 20;
      for (int i = 0; i < questions.length; i += pageSize) {
        final end = (i + pageSize > questions.length) ? questions.length : i + pageSize;
        final page = questions.sublist(i, end);
        final Map<int, Question> map = {};
        for (int j = 0; j < page.length; j++) {
          map[i + j] = page[j];
        }
        await box.putAll(map);
      }
      debugPrint('✅ saveQuestions 成功，共 ${questions.length} 道题');
    } catch (e) {
      debugPrint('❌ saveQuestions 失败: $e');
      rethrow;
    }
  }

  // ---------- 清空 ----------
  Future<void> clearAll({String? setName}) async {
    try {
      final name = setName ?? (await getCurrentSetName() ?? '默认题库');
      final box = await Hive.openBox<Question>(_getBoxName(name));
      await box.clear();
      debugPrint('✅ clearAll 成功');
    } catch (e) {
      debugPrint('❌ clearAll 失败: $e');
      rethrow;
    }
  }

  // ---------- 重置进度 ----------
  Future<void> resetProgress({String? setName}) async {
    try {
      final name = setName ?? (await getCurrentSetName() ?? '默认题库');
      final box = await Hive.openBox<Question>(_getBoxName(name));
      final questions = box.values.toList();
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        q.selectedOption = null;
        q.isAnswered = false;
        q.isWrong = false;
        await box.putAt(i, q);
      }
      await saveCurrentIndex(0, setName: name);
      debugPrint('✅ resetProgress 成功');
    } catch (e) {
      debugPrint('❌ resetProgress 失败: $e');
      rethrow;
    }
  }

  // =============================================
  // 错题集管理
  // =============================================

  Future<void> addWrongQuestion(Question question, String setName) async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      await wrongBox.put(question.id, {
        'id': question.id,
        'setName': setName,
        'addedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ 添加错题: ${question.id}');

      // ✅ 新增：检查是否需要生成复习通知
      await _checkAndCreateReviewNotification(setName);
    } catch (e) {
      debugPrint('❌ 添加错题失败: $e');
    }
  }

  // ✅ 新增私有方法：检查错题数并生成通知
  Future<void> _checkAndCreateReviewNotification(String setName) async {
    try {
      final wrongRecords = await getWrongQuestionRecordsBySet(setName: setName);
      final count = wrongRecords.length;

      if (count >= 5) {
        await notificationRepo.create(
          title: '📚 有错题需要复习',
          content: '你有 $count 道错题待复习，趁热打铁巩固一下吧！',
          type: 'review',
          actionRoute: '/quiz/review',
          icon: 'error_outline',
          sourceId: 'review_${DateTime.now().toIso8601String().split('T')[0]}',
        );
      }
    } catch (e) {
      debugPrint('❌ 检查错题通知失败: $e');
    }
  }

  Future<void> removeWrongQuestion(String questionId) async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      await wrongBox.delete(questionId);
      debugPrint('✅ 移除错题: $questionId');
    } catch (e) {
      debugPrint('❌ 移除错题失败: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWrongQuestionRecords() async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      final records = <Map<String, dynamic>>[];
      for (var key in wrongBox.keys) {
        final value = wrongBox.get(key);
        if (value != null) {
          records.add({
            'id': key.toString(),
            'setName': value['setName'] ?? '默认题库',
            'addedAt': value['addedAt'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
      records.sort((a, b) => b['addedAt'].compareTo(a['addedAt']));
      return records;
    } catch (e) {
      debugPrint('❌ 获取错题记录失败: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWrongQuestionRecordsBySet({String? setName}) async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      final records = <Map<String, dynamic>>[];
      for (var key in wrongBox.keys) {
        final value = wrongBox.get(key);
        if (value != null) {
          final recordSetName = value['setName'] ?? '默认题库';
          if (setName != null && recordSetName != setName) {
            continue;
          }
          records.add({
            'id': key.toString(),
            'setName': recordSetName,
            'addedAt': value['addedAt'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
      records.sort((a, b) => b['addedAt'].compareTo(a['addedAt']));
      return records;
    } catch (e) {
      debugPrint('❌ 获取错题记录失败: $e');
      return [];
    }
  }

  Future<List<String>> getWrongQuestionSetNames() async {
    try {
      final records = await getWrongQuestionRecords();
      final setNames = <String>{};
      for (var record in records) {
        setNames.add(record['setName'] ?? '默认题库');
      }
      return setNames.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Question>> getWrongQuestions() async {
    try {
      final records = await getWrongQuestionRecords();
      final questions = <Question>[];
      for (var record in records) {
        final setName = record['setName'] ?? '默认题库';
        final questionId = record['id'];
        final box = await Hive.openBox<Question>(_getBoxName(setName));
        for (var q in box.values) {
          if (q.id == questionId) {
            questions.add(q);
            break;
          }
        }
      }
      return questions;
    } catch (e) {
      debugPrint('❌ 获取错题列表失败: $e');
      return [];
    }
  }

  Future<int> getWrongQuestionCount() async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      return wrongBox.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> clearAllWrongQuestions() async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      await wrongBox.clear();
      debugPrint('✅ 清空所有错题');
    } catch (e) {
      debugPrint('❌ 清空错题失败: $e');
    }
  }

  Future<bool> isWrongQuestion(String questionId) async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      return wrongBox.containsKey(questionId);
    } catch (e) {
      return false;
    }
  }

  // ---------- 批量移除错题 ----------
  Future<void> batchRemoveWrongQuestions(List<String> questionIds) async {
    try {
      final wrongBox = await Hive.openBox<Map>(wrongQuestionsBoxName);
      for (var id in questionIds) {
        await wrongBox.delete(id);
      }
      debugPrint('✅ 批量移除 ${questionIds.length} 道错题');
    } catch (e) {
      debugPrint('❌ 批量移除错题失败: $e');
    }
  }

  // ---------- 获取错题统计概览 ----------
  Future<Map<String, int>> getWrongStatsSummary() async {
    try {
      final records = await getWrongQuestionRecords();
      final total = records.length;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayNew = records.where((r) {
        final addedAt = DateTime.tryParse(r['addedAt'] ?? '');
        return addedAt != null && addedAt.isAfter(todayStart);
      }).length;

      return {
        'total': total,
        'todayNew': todayNew,
        'mastered': 0,
      };
    } catch (e) {
      return {'total': 0, 'todayNew': 0, 'mastered': 0};
    }
  }

  // ---------- 获取某个题库的错题数量 ----------
  Future<int> getWrongQuestionCountBySet(String setName) async {
    try {
      final records = await getWrongQuestionRecordsBySet(setName: setName);
      return records.length;
    } catch (e) {
      return 0;
    }
  }

  // =============================================
  // 错题统计（掌握度相关）
  // =============================================

  Future<Box<WrongQuestionStats>> _getWrongStatsBox() async {
    return await Hive.openBox<WrongQuestionStats>(wrongStatsBoxName);
  }

  /// 更新错题统计（当答错或答对时调用）
  Future<void> updateWrongStats(String questionId, bool isCorrect) async {
    final box = await _getWrongStatsBox();
    var stats = box.get(questionId);
    if (stats == null) {
      stats = WrongQuestionStats(
        questionId: questionId,
        wrongCount: isCorrect ? 0 : 1,
        correctCount: isCorrect ? 1 : 0,
        lastReviewed: DateTime.now(),
      );
    } else {
      if (isCorrect) {
        stats.correctCount += 1;
      } else {
        stats.wrongCount += 1;
      }
      stats.lastReviewed = DateTime.now();
    }
    stats.calculateMastery();
    await box.put(questionId, stats);
    debugPrint('📊 更新错题统计: $questionId, 正确=$isCorrect, 掌握度=${stats.masteryLevel}');
  }

  /// 获取某个题目的统计信息
  Future<WrongQuestionStats?> getWrongQuestionStats(String questionId) async {
    final box = await _getWrongStatsBox();
    return box.get(questionId);
  }

  /// 获取所有错题统计列表
  Future<List<WrongQuestionStats>> getAllWrongStats() async {
    final box = await _getWrongStatsBox();
    return box.values.toList();
  }

  /// 获取错题统计概览（详细版）
  Future<Map<String, dynamic>> getWrongStatsOverview() async {
    final statsList = await getAllWrongStats();
    if (statsList.isEmpty) {
      return {
        'total': 0,
        'mastered': 0,
        'medium': 0,
        'hard': 0,
        'avgMastery': 0.0,
      };
    }
    int mastered = 0, medium = 0, hard = 0;
    double totalMastery = 0.0;
    for (var stats in statsList) {
      totalMastery += stats.masteryLevel;
      if (stats.masteryLevel >= 0.7) {
        mastered++;
      } else if (stats.masteryLevel >= 0.4) {
        medium++;
      } else {
        hard++;
      }
    }
    return {
      'total': statsList.length,
      'mastered': mastered,
      'medium': medium,
      'hard': hard,
      'avgMastery': totalMastery / statsList.length,
    };
  }

  /// 清除所有错题统计
  Future<void> clearAllWrongStats() async {
    final box = await _getWrongStatsBox();
    await box.clear();
    debugPrint('🗑️ 清空错题统计');
  }

  /// 删除单个错题统计
  Future<void> removeWrongStats(String questionId) async {
    final box = await _getWrongStatsBox();
    await box.delete(questionId);
  }

  /// 迁移旧错题记录到统计（首次加载时调用）
  Future<void> migrateOldWrongRecords() async {
    final records = await getWrongQuestionRecords();
    final statsBox = await _getWrongStatsBox();
    for (var record in records) {
      final id = record['id'] as String;
      if (!statsBox.containsKey(id)) {
        final stats = WrongQuestionStats(
          questionId: id,
          wrongCount: 1,
          correctCount: 0,
          lastReviewed: DateTime.now(),
        );
        stats.calculateMastery();
        await statsBox.put(id, stats);
      }
    }
  }

  // =============================================
  // 间隔重复 / 智能复习 方法
  // =============================================

  /// 根据ID获取单个题目
  Future<Question?> getQuestionById(String questionId, {String? setName}) async {
    try {
      final name = setName ?? (await getCurrentSetName() ?? '默认题库');
      final box = await Hive.openBox<Question>(_getBoxName(name));
      for (var q in box.values) {
        if (q.id == questionId) {
          return q;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ getQuestionById 失败: $e');
      return null;
    }
  }

  /// 获取需要复习的题目列表
  Future<List<Question>> getReviewQuestions({String? setName, int limit = 30}) async {
    try {
      final statsBox = await _getWrongStatsBox();
      final allStats = statsBox.values.toList();

      // 筛选到期的题目
      var dueStats = allStats.where((stats) => stats.isDue).toList();

      // 按优先级排序：间隔越短越优先（即越紧急）
      dueStats.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));

      // 限制数量
      if (dueStats.length > limit) {
        dueStats = dueStats.take(limit).toList();
      }

      // 获取题目
      final questions = <Question>[];
      for (var stats in dueStats) {
        final q = await getQuestionById(stats.questionId, setName: setName);
        if (q != null) {
          questions.add(q);
        }
      }

      debugPrint('📚 获取到 ${questions.length} 道需要复习的题目');
      return questions;
    } catch (e) {
      debugPrint('❌ getReviewQuestions 失败: $e');
      return [];
    }
  }

  /// 更新复习统计（间隔重复）
  Future<void> updateReviewStats(String questionId, bool isCorrect) async {
    try {
      final box = await _getWrongStatsBox();
      var stats = box.get(questionId);

      if (stats == null) {
        stats = WrongQuestionStats(
          questionId: questionId,
          wrongCount: isCorrect ? 0 : 1,
          correctCount: isCorrect ? 1 : 0,
          lastReviewed: DateTime.now(),
        );
        stats.calculateNextReview(isCorrect);
        await box.put(questionId, stats);
        debugPrint('📊 创建复习统计: $questionId, 正确=$isCorrect');
        return;
      }

      if (isCorrect) {
        stats.correctCount += 1;
      } else {
        stats.wrongCount += 1;
      }
      stats.calculateNextReview(isCorrect);
      await box.put(questionId, stats);

      debugPrint('📊 更新复习统计: $questionId, 正确=$isCorrect, 间隔=${stats.interval}天, 连续正确=${stats.consecutiveCorrect}次');

      // 如果掌握度 >= 0.8 且连续正确 >= 5 次，可以从错题集移除
      if (stats.masteryLevel >= 0.8 && stats.consecutiveCorrect >= 5) {
        if (await isWrongQuestion(questionId)) {
          await removeWrongQuestion(questionId);
          debugPrint('✅ 掌握度高且连续正确5次，从错题集移除: $questionId');
        }
      }
    } catch (e) {
      debugPrint('❌ updateReviewStats 失败: $e');
    }
  }

  /// 获取复习统计概览
  Future<Map<String, dynamic>> getReviewStats() async {
    try {
      final statsList = await getAllWrongStats();
      final total = statsList.length;
      final dueCount = statsList.where((s) => s.isDue).length;
      final mastered = statsList.where((s) => s.masteryLevel >= 0.7).length;
      final avgMastery = total > 0 ? statsList.map((s) => s.masteryLevel).reduce((a, b) => a + b) / total : 0.0;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final reviewedToday = statsList.where((s) {
        return s.lastReviewDate.isAfter(todayStart);
      }).length;

      return {
        'total': total,
        'dueCount': dueCount,
        'mastered': mastered,
        'avgMastery': avgMastery,
        'reviewedToday': reviewedToday,
      };
    } catch (e) {
      return {
        'total': 0,
        'dueCount': 0,
        'mastered': 0,
        'avgMastery': 0.0,
        'reviewedToday': 0,
      };
    }
  }

  /// 迁移旧数据到间隔重复字段
  Future<void> migrateReviewFields() async {
    try {
      final box = await _getWrongStatsBox();
      final allStats = box.values.toList();

      for (var stats in allStats) {
        // 直接设置默认值（如果现有值为空或无效）
        if (stats.lastReviewDate == stats.lastReviewed && stats.interval == 1) {
          // 数据看起来已经是新的，跳过
          continue;
        }

        // 统一设置默认值
        stats.lastReviewDate = stats.lastReviewed;
        stats.easinessFactor = 2.5;
        stats.interval = 1;
        stats.consecutiveCorrect = 0;

        await box.put(stats.questionId, stats);
      }

      debugPrint('✅ 间隔重复字段迁移完成，共处理 ${allStats.length} 条记录');
    } catch (e) {
      debugPrint('❌ migrateReviewFields 失败: $e');
    }
  }

  // =============================================
  // ⭐ 收藏功能（跨题库支持）
  // =============================================

  /// 收藏题目（在所有题库中查找）
  Future<void> favoriteQuestion(String questionId) async {
    try {
      final setNames = await getAllSetNames();

      for (var name in setNames) {
        final box = await Hive.openBox<Question>(_getBoxName(name));
        for (int i = 0; i < box.length; i++) {
          final q = box.getAt(i);
          if (q != null && q.id == questionId) {
            final updated = q.copyWith(isFavorite: true);
            await box.putAt(i, updated);
            debugPrint('⭐ 收藏题目: ${q.content.substring(0, q.content.length > 30 ? 30 : q.content.length)}... (来源: $name)');
            return;
          }
        }
      }
      debugPrint('⚠️ 未找到要收藏的题目 ID: $questionId');
    } catch (e) {
      debugPrint('❌ 收藏失败: $e');
    }
  }

  /// 取消收藏（在所有题库中查找）
  Future<void> unfavoriteQuestion(String questionId) async {
    try {
      final setNames = await getAllSetNames();

      for (var name in setNames) {
        final box = await Hive.openBox<Question>(_getBoxName(name));
        for (int i = 0; i < box.length; i++) {
          final q = box.getAt(i);
          if (q != null && q.id == questionId) {
            final updated = q.copyWith(isFavorite: false);
            await box.putAt(i, updated);
            debugPrint('⭐ 取消收藏: ${q.content.substring(0, q.content.length > 30 ? 30 : q.content.length)}... (来源: $name)');
            return;
          }
        }
      }
      debugPrint('⚠️ 未找到要取消收藏的题目 ID: $questionId');
    } catch (e) {
      debugPrint('❌ 取消收藏失败: $e');
    }
  }

  /// 切换收藏状态（在所有题库中查找）
  Future<bool> toggleFavorite(String questionId) async {
    try {
      final setNames = await getAllSetNames();

      for (var name in setNames) {
        final box = await Hive.openBox<Question>(_getBoxName(name));
        for (int i = 0; i < box.length; i++) {
          final q = box.getAt(i);
          if (q != null && q.id == questionId) {
            final newState = !q.isFavorite;
            final updated = q.copyWith(isFavorite: newState);
            await box.putAt(i, updated);
            debugPrint('⭐ 切换收藏: ${q.content.substring(0, q.content.length > 30 ? 30 : q.content.length)}... -> $newState (来源: $name)');
            return newState;
          }
        }
      }
      debugPrint('⚠️ 未找到要切换收藏的题目 ID: $questionId');
      return false;
    } catch (e) {
      debugPrint('❌ 切换收藏失败: $e');
      return false;
    }
  }

  /// 检查是否已收藏（在所有题库中查找）
  Future<bool> isFavorite(String questionId) async {
    try {
      final setNames = await getAllSetNames();

      for (var name in setNames) {
        final box = await Hive.openBox<Question>(_getBoxName(name));
        for (var q in box.values) {
          if (q.id == questionId) {
            return q.isFavorite;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取所有收藏题目（跨题库）
  Future<List<Question>> getFavoriteQuestions() async {
    try {
      final setNames = await getAllSetNames();
      final favorites = <Question>[];

      for (var name in setNames) {
        final box = await Hive.openBox<Question>(_getBoxName(name));
        for (var q in box.values) {
          if (q.isFavorite) {
            favorites.add(q);
          }
        }
      }

      // 按ID倒序排列（越晚收藏的越靠前）
      favorites.sort((a, b) => b.id.compareTo(a.id));
      return favorites;
    } catch (e) {
      debugPrint('❌ 获取收藏列表失败: $e');
      return [];
    }
  }

  /// 获取所有收藏题目，附带来源题库名称
  Future<List<Map<String, dynamic>>> getFavoriteQuestionsWithSource() async {
    try {
      final setNames = await getAllSetNames();
      final favorites = <Map<String, dynamic>>[];

      for (var name in setNames) {
        final box = await Hive.openBox<Question>(_getBoxName(name));
        for (var q in box.values) {
          if (q.isFavorite) {
            favorites.add({
              'question': q,
              'setName': name,
            });
          }
        }
      }

      // 按收藏时间倒序（最新在前）
      favorites.sort((a, b) => b['question'].id.compareTo(a['question'].id));
      return favorites;
    } catch (e) {
      debugPrint('❌ 获取收藏列表(含来源)失败: $e');
      return [];
    }
  }

  /// 获取收藏数量
  Future<int> getFavoriteCount() async {
    try {
      final favorites = await getFavoriteQuestions();
      return favorites.length;
    } catch (e) {
      return 0;
    }
  }

  // =============================================
  // 🔍 搜索功能
  // =============================================

  /// 搜索题目（跨题库搜索）
  /// 支持按题库名称和题型筛选
  Future<List<Map<String, dynamic>>> searchQuestions({
    required String query,
    String? setName,
    String? questionType,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final setNames = await getAllSetNames();
      final results = <Map<String, dynamic>>[];
      final searchQuery = query.trim().toLowerCase();

      // 确定要搜索的题库
      List<String> targetSets;
      if (setName != null && setName.isNotEmpty && setName != '全部') {
        targetSets = [setName];
      } else {
        targetSets = setNames;
      }

      for (var name in targetSets) {
        final box = await Hive.openBox<Question>(_getBoxName(name));
        final questions = box.values.toList();
        final total = questions.length;
        final answered = questions.where((q) => q.isAnsweredValue).length;
        final progress = total > 0 ? answered / total : 0.0;

        // 搜索匹配
        for (var q in questions) {
          // 关键词匹配
          final contentMatch = q.content.toLowerCase().contains(searchQuery);
          final optionMatch = q.options.any((opt) => opt.toLowerCase().contains(searchQuery));
          final answerMatch = q.answer?.toLowerCase().contains(searchQuery) ?? false;

          if (!contentMatch && !optionMatch && !answerMatch) continue;

          // 题型筛选
          if (questionType != null && questionType != '全部') {
            final isJudge = q.options.length == 2 &&
                q.options.contains('正确') &&
                q.options.contains('错误');
            final isFill = q.options.length == 1 &&
                q.options.first.contains('填空');

            if (questionType == '选择题' && (isJudge || isFill)) continue;
            if (questionType == '判断题' && !isJudge) continue;
            if (questionType == '填空题' && !isFill) continue;
          }

          results.add({
            'setName': name,
            'question': q,
            'setTotal': total,
            'setAnswered': answered,
            'setProgress': progress,
          });
        }
      }

      // 按匹配度排序：题目内容匹配 > 选项匹配 > 答案匹配
      results.sort((a, b) {
        final qa = a['question'] as Question;
        final qb = b['question'] as Question;
        final scoreA = _getMatchScore(qa, searchQuery);
        final scoreB = _getMatchScore(qb, searchQuery);
        return scoreB.compareTo(scoreA);
      });

      return results;
    } catch (e) {
      debugPrint('❌ 搜索失败: $e');
      return [];
    }
  }

  /// 计算匹配分数（用于排序）
  int _getMatchScore(Question q, String query) {
    int score = 0;
    final lowerContent = q.content.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (lowerContent.contains(lowerQuery)) {
      // 题目内容匹配：权重最高
      score += 100;
      if (lowerContent.startsWith(lowerQuery)) {
        score += 50; // 开头匹配加分
      }
    }
    for (var opt in q.options) {
      if (opt.toLowerCase().contains(lowerQuery)) {
        score += 30;
      }
    }
    if (q.answer?.toLowerCase().contains(lowerQuery) ?? false) {
      score += 20;
    }
    return score;
  }

  // =============================================
  // 📤 导出功能
  // =============================================

  /// 导出题库为JSON字符串
  Future<String> exportQuestionsToJson(String setName) async {
    final box = await Hive.openBox<Question>(_getBoxName(setName));
    final questions = box.values.toList();

    final jsonData = {
      'setName': setName,
      'exportTime': DateTime.now().toIso8601String(),
      'total': questions.length,
      'questions': questions.map((q) => {
        'id': q.id,
        'content': q.content,
        'options': q.options,
        'correctIndex': q.correctIndex,
        'answer': q.answer,
        'source': q.source,
      }).toList(),
    };

    return jsonEncode(jsonData);
  }

  /// 导出题库为TXT文本
  Future<String> exportQuestionsToTxt(String setName) async {
    final box = await Hive.openBox<Question>(_getBoxName(setName));
    final questions = box.values.toList();

    final buffer = StringBuffer();
    buffer.writeln('=' * 40);
    buffer.writeln('📚 $setName（共 ${questions.length} 题）');
    buffer.writeln('=' * 40);
    buffer.writeln();

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final isJudge = q.options.length == 2 &&
          q.options.contains('正确') &&
          q.options.contains('错误');
      final isFill = q.options.length == 1 &&
          q.options.first.contains('填空');
      final typeLabel = isJudge ? '判断题' : (isFill ? '填空题' : '选择题');

      buffer.writeln('【第 ${i + 1} 题】$typeLabel');
      buffer.writeln(q.content);
      buffer.writeln();

      for (int j = 0; j < q.options.length; j++) {
        final letter = String.fromCharCode(65 + j);
        final isCorrect = j == q.correctIndex;
        buffer.writeln('  $letter. ${q.options[j]}${isCorrect ? '  ✅' : ''}');
      }

      if (isFill && q.answer != null) {
        buffer.writeln('  答案：${q.answer}');
      }
      buffer.writeln();
      buffer.writeln('-' * 40);
      buffer.writeln();
    }

    return buffer.toString();
  }
}