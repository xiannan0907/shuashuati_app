// ignore_for_file: must_be_immutable
import 'package:hive_ce/hive.dart';
import 'package:equatable/equatable.dart';

part 'question_model.g.dart';

@HiveType(typeId: 0)
class Question extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final List<String> options;

  @HiveField(3)
  final int correctIndex;

  @HiveField(4)
  int? selectedOption;

  @HiveField(5)
  bool? isAnswered;

  @HiveField(6)
  final String source;

  @HiveField(7)
  final String? answer;

  @HiveField(8)
  bool? isWrong;

  // ✅ 新增：收藏字段
  @HiveField(9)
  bool isFavorite;

  Question({
    required this.id,
    required this.content,
    required this.options,
    required this.correctIndex,
    this.selectedOption,
    this.isAnswered = false,
    this.source = 'imported',
    this.answer,
    this.isWrong = false,
    this.isFavorite = false, // ✅ 默认未收藏
  });

  bool get isAnsweredValue => isAnswered ?? false;
  bool get isWrongValue => isWrong ?? false;

  Question copyWith({
    String? id,
    String? content,
    List<String>? options,
    int? correctIndex,
    int? selectedOption,
    bool? isAnswered,
    String? source,
    String? answer,
    bool? isWrong,
    bool? isFavorite,
    bool clearSelectedOption = false,
    bool clearIsAnswered = false,
  }) {
    return Question(
      id: id ?? this.id,
      content: content ?? this.content,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      selectedOption: clearSelectedOption ? null : (selectedOption ?? this.selectedOption),
      isAnswered: clearIsAnswered ? false : (isAnswered ?? isAnsweredValue),
      source: source ?? this.source,
      answer: answer ?? this.answer,
      isWrong: isWrong ?? isWrongValue,
      isFavorite: isFavorite ?? this.isFavorite, // ✅
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    options,
    correctIndex,
    selectedOption,
    isAnswered,
    source,
    answer,
    isWrong,
    isFavorite, // ✅
  ];
}