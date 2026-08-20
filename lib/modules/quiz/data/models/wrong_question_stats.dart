import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'wrong_question_stats.g.dart';

@HiveType(typeId: 2)
class WrongQuestionStats extends Equatable {
  @HiveField(0)
  final String questionId;

  @HiveField(1)
  int wrongCount;

  @HiveField(2)
  int correctCount;

  @HiveField(3)
  DateTime lastReviewed;

  @HiveField(4)
  double masteryLevel;

  // ========== 新增：间隔重复字段 ==========
  @HiveField(5)
  int consecutiveCorrect; // 连续正确次数

  @HiveField(6)
  DateTime lastReviewDate; // 上次复习日期

  @HiveField(7)
  double easinessFactor; // 难度因子 (2.5 初始值)

  @HiveField(8)
  int interval; // 当前间隔（天数）

  WrongQuestionStats({
    required this.questionId,
    this.wrongCount = 1,
    this.correctCount = 0,
    DateTime? lastReviewed,
    this.masteryLevel = 0.0,
    this.consecutiveCorrect = 0,
    DateTime? lastReviewDate,
    this.easinessFactor = 2.5,
    this.interval = 1,
  })  : lastReviewed = lastReviewed ?? DateTime.now(),
        lastReviewDate = lastReviewDate ?? DateTime.now();

  void calculateMastery() {
    final total = wrongCount + correctCount;
    if (total == 0) {
      masteryLevel = 0.0;
      return;
    }
    final correctRate = correctCount / total;
    final penalty = (wrongCount / (wrongCount + 5)).clamp(0.0, 0.4);
    masteryLevel = (correctRate * 0.6 + (1 - penalty) * 0.4).clamp(0.0, 1.0);
  }

  // 计算下次复习时间
  void calculateNextReview(bool isCorrect) {
    final now = DateTime.now();

    if (isCorrect) {
      consecutiveCorrect += 1;

      // 根据连续正确次数计算间隔
      if (consecutiveCorrect == 1) {
        interval = 1;
      } else if (consecutiveCorrect == 2) {
        interval = 3;
      } else if (consecutiveCorrect == 3) {
        interval = 7;
      } else if (consecutiveCorrect == 4) {
        interval = 15;
      } else if (consecutiveCorrect == 5) {
        interval = 30;
      } else {
        interval = (interval * 1.5).round().clamp(30, 365);
      }

      easinessFactor = (easinessFactor + 0.1).clamp(1.3, 2.6);
    } else {
      consecutiveCorrect = 0;
      interval = 1;
      easinessFactor = (easinessFactor - 0.2).clamp(1.3, 2.6);
      wrongCount += 1;
    }

    lastReviewDate = now;
    lastReviewed = now;
    calculateMastery();
  }

  // 判断是否到期需要复习
  bool get isDue {
    final dueDate = lastReviewDate.add(Duration(days: interval));
    return DateTime.now().isAfter(dueDate);
  }

  // 获取下次复习日期
  DateTime get nextReviewDate => lastReviewDate.add(Duration(days: interval));

  String get difficultyLevel {
    if (masteryLevel >= 0.7) return '已掌握';
    if (masteryLevel >= 0.4) return '中等';
    return '困难';
  }

  Color get difficultyColor {
    if (masteryLevel >= 0.7) return Colors.green;
    if (masteryLevel >= 0.4) return Colors.orange;
    return Colors.red;
  }

  WrongQuestionStats copyWith({
    String? questionId,
    int? wrongCount,
    int? correctCount,
    DateTime? lastReviewed,
    double? masteryLevel,
    int? consecutiveCorrect,
    DateTime? lastReviewDate,
    double? easinessFactor,
    int? interval,
  }) {
    return WrongQuestionStats(
      questionId: questionId ?? this.questionId,
      wrongCount: wrongCount ?? this.wrongCount,
      correctCount: correctCount ?? this.correctCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      interval: interval ?? this.interval,
    );
  }

  @override
  List<Object?> get props => [
    questionId,
    wrongCount,
    correctCount,
    lastReviewed,
    masteryLevel,
    consecutiveCorrect,
    lastReviewDate,
    easinessFactor,
    interval,
  ];
}