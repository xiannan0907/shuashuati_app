import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../../services/file_parser_service.dart';
import '../../../../data/repositories/notification_repository.dart'; // ✅ 新增
import 'dart:math';

// ==================== 事件 ====================
abstract class QuizEvent {}

class LoadQuestions extends QuizEvent {}

class LoadQuizSet extends QuizEvent {
  final String setName;
  LoadQuizSet(this.setName);
}

class LoadQuizSetList extends QuizEvent {}

class SwitchQuizSet extends QuizEvent {
  final String setName;
  SwitchQuizSet(this.setName);
}

class DeleteQuizSet extends QuizEvent {
  final String setName;
  DeleteQuizSet(this.setName);
}

class RenameQuizSet extends QuizEvent {
  final String oldName;
  final String newName;
  RenameQuizSet(this.oldName, this.newName);
}

class ImportFiles extends QuizEvent {
  final List<String> filePaths;
  final String sourceType;
  ImportFiles(this.filePaths, this.sourceType);
}

class AppendFiles extends QuizEvent {
  final List<String> filePaths;
  final String sourceType;
  AppendFiles(this.filePaths, this.sourceType);
}

class ClearAllQuestions extends QuizEvent {}

class ClearFeedback extends QuizEvent {}

class ClearImportMessage extends QuizEvent {}

class ToggleShuffle extends QuizEvent {}

class ToggleStudyMode extends QuizEvent {}

class ResetProgress extends QuizEvent {}

class GoToQuestion extends QuizEvent {
  final int index;
  GoToQuestion(this.index);
}

class SelectAnswer extends QuizEvent {
  final int optionIndex;
  SelectAnswer(this.optionIndex);
}

class NextQuestion extends QuizEvent {}

class PreviousQuestion extends QuizEvent {}

class QuizCompletedEvent extends QuizEvent {
  final int correctCount;
  final int totalCount;
  QuizCompletedEvent(this.correctCount, this.totalCount);
}

class ResetQuiz extends QuizEvent {}

// ==================== 状态 ====================
abstract class QuizState {}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizEmpty extends QuizState {}

class QuizSetListLoaded extends QuizState {
  final List<String> setNames;
  final String currentSet;
  QuizSetListLoaded({required this.setNames, required this.currentSet});
}

class QuizImporting extends QuizState {
  final int progress;
  final String message;
  QuizImporting({this.progress = 0, this.message = '准备导入...'});
}

class QuizLoaded extends QuizState {
  final List<Question> questions;
  final int currentIndex;
  final int correctCount;
  final String? importMessage;
  final String? feedback;
  final String currentSetName;
  final bool isShuffled;
  final bool isStudyMode;

  QuizLoaded({
    required this.questions,
    required this.currentIndex,
    this.correctCount = 0,
    this.importMessage,
    this.feedback,
    this.currentSetName = '默认题库',
    this.isShuffled = false,
    this.isStudyMode = false,
  });

  QuizLoaded copyWith({
    List<Question>? questions,
    int? currentIndex,
    int? correctCount,
    String? importMessage,
    String? feedback,
    bool clearFeedback = false,
    String? currentSetName,
    bool? isShuffled,
    bool? isStudyMode,
  }) {
    return QuizLoaded(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      importMessage: importMessage ?? this.importMessage,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      currentSetName: currentSetName ?? this.currentSetName,
      isShuffled: isShuffled ?? this.isShuffled,
      isStudyMode: isStudyMode ?? this.isStudyMode,
    );
  }
}

class QuizCompleted extends QuizState {
  final int correctCount;
  final int totalCount;
  final List<Question> wrongQuestions;
  QuizCompleted(this.correctCount, this.totalCount, this.wrongQuestions);
}

class QuizError extends QuizState {
  final String message;
  QuizError(this.message);
}

// ==================== BLoC ====================
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuestionRepository repository;
  final FileParserService parser;
  String _currentSetName = '默认题库';
  bool _isShuffled = false;
  bool _isStudyMode = false;
  List<Question> _originalQuestions = [];
  int _currentOriginalIndex = 0;
  int _savedOriginalIndex = 0;

  QuizBloc(this.repository, this.parser) : super(QuizInitial()) {
    on<LoadQuizSetList>((event, emit) async {
      try {
        final setNames = await repository.getAllSetNames();
        final currentSet = await repository.getCurrentSetName() ?? '默认题库';
        emit(QuizSetListLoaded(setNames: setNames, currentSet: currentSet));
      } catch (e) {
        emit(QuizError('加载题库列表失败: $e'));
      }
    });

    on<LoadQuizSet>((event, emit) async {
      emit(QuizLoading());
      try {
        _currentSetName = event.setName;
        _originalQuestions = await repository.getQuestions(setName: event.setName);

        final savedOriginalIndex = await repository.getCurrentIndex(setName: event.setName);

        List<Question> displayQuestions = List.from(_originalQuestions);
        if (_isShuffled) {
          displayQuestions.shuffle(Random());
        }

        int displayIndex = 0;
        if (savedOriginalIndex >= 0 && savedOriginalIndex < _originalQuestions.length) {
          final targetQuestion = _originalQuestions[savedOriginalIndex];
          final foundIndex = displayQuestions.indexWhere((q) => q.id == targetQuestion.id);
          if (foundIndex != -1) {
            displayIndex = foundIndex;
            _currentOriginalIndex = savedOriginalIndex;
            _savedOriginalIndex = savedOriginalIndex;
          } else {
            _currentOriginalIndex = 0;
            _savedOriginalIndex = 0;
            displayIndex = 0;
          }
        } else {
          _currentOriginalIndex = 0;
          _savedOriginalIndex = 0;
          displayIndex = 0;
        }

        if (displayQuestions.isEmpty) {
          emit(QuizEmpty());
        } else {
          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: displayIndex,
            currentSetName: event.setName,
            isShuffled: _isShuffled,
            isStudyMode: _isStudyMode,
          ));
        }
        debugPrint('✅ LoadQuizSet 完成');
      } catch (e) {
        debugPrint('❌ LoadQuizSet 失败: $e');
        emit(QuizError('加载题库失败: $e'));
      }
    });

    on<LoadQuestions>((event, emit) async {
      emit(QuizLoading());
      try {
        final currentSet = await repository.getCurrentSetName() ?? '默认题库';
        _currentSetName = currentSet;
        _originalQuestions = await repository.getQuestions(setName: currentSet);

        final savedOriginalIndex = await repository.getCurrentIndex(setName: currentSet);

        List<Question> displayQuestions = List.from(_originalQuestions);
        if (_isShuffled) {
          displayQuestions.shuffle(Random());
        }

        int displayIndex = 0;
        if (savedOriginalIndex >= 0 && savedOriginalIndex < _originalQuestions.length) {
          final targetQuestion = _originalQuestions[savedOriginalIndex];
          final foundIndex = displayQuestions.indexWhere((q) => q.id == targetQuestion.id);
          if (foundIndex != -1) {
            displayIndex = foundIndex;
            _currentOriginalIndex = savedOriginalIndex;
            _savedOriginalIndex = savedOriginalIndex;
          } else {
            _currentOriginalIndex = 0;
            _savedOriginalIndex = 0;
            displayIndex = 0;
          }
        } else {
          _currentOriginalIndex = 0;
          _savedOriginalIndex = 0;
          displayIndex = 0;
        }

        if (displayQuestions.isEmpty) {
          emit(QuizEmpty());
        } else {
          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: displayIndex,
            currentSetName: currentSet,
            isShuffled: _isShuffled,
            isStudyMode: _isStudyMode,
          ));
        }
        debugPrint('✅ LoadQuestions 完成');
      } catch (e) {
        emit(QuizError('加载失败: $e'));
      }
    });

    on<SwitchQuizSet>((event, emit) async {
      emit(QuizLoading());
      try {
        _currentSetName = event.setName;
        await repository.createSet(event.setName);
        _originalQuestions = await repository.getQuestions(setName: event.setName);

        List<Question> displayQuestions = List.from(_originalQuestions);
        if (_isShuffled) {
          displayQuestions.shuffle(Random());
        }

        _currentOriginalIndex = 0;
        _savedOriginalIndex = 0;

        if (displayQuestions.isEmpty) {
          emit(QuizEmpty());
        } else {
          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: 0,
            currentSetName: event.setName,
            isShuffled: _isShuffled,
            isStudyMode: _isStudyMode,
          ));
        }

        final setNames = await repository.getAllSetNames();
        final currentSet = await repository.getCurrentSetName() ?? '默认题库';
        emit(QuizSetListLoaded(setNames: setNames, currentSet: currentSet));
      } catch (e) {
        emit(QuizError('切换题库失败: $e'));
      }
    });

    on<DeleteQuizSet>((event, emit) async {
      emit(QuizLoading());
      try {
        await repository.deleteSet(event.setName);
        final setNames = await repository.getAllSetNames();
        final currentSet = await repository.getCurrentSetName() ?? '默认题库';
        if (setNames.isEmpty) {
          emit(QuizEmpty());
        } else {
          _originalQuestions = await repository.getQuestions(setName: currentSet);
          List<Question> displayQuestions = List.from(_originalQuestions);
          if (_isShuffled) {
            displayQuestions.shuffle(Random());
          }
          _currentOriginalIndex = 0;
          _savedOriginalIndex = 0;
          await repository.saveCurrentIndex(0, setName: currentSet);
          if (displayQuestions.isEmpty) {
            emit(QuizEmpty());
          } else {
            emit(QuizLoaded(
              questions: displayQuestions,
              currentIndex: 0,
              currentSetName: currentSet,
              isShuffled: _isShuffled,
              isStudyMode: _isStudyMode,
            ));
          }
        }
        emit(QuizSetListLoaded(setNames: setNames, currentSet: currentSet));
      } catch (e) {
        emit(QuizError('删除题库失败: $e'));
      }
    });

    on<RenameQuizSet>((event, emit) async {
      emit(QuizLoading());
      try {
        await repository.renameSet(event.oldName, event.newName);
        final setNames = await repository.getAllSetNames();
        final currentSet = await repository.getCurrentSetName() ?? '默认题库';
        _originalQuestions = await repository.getQuestions(setName: currentSet);
        List<Question> displayQuestions = List.from(_originalQuestions);
        if (_isShuffled) {
          displayQuestions.shuffle(Random());
        }
        _currentOriginalIndex = 0;
        _savedOriginalIndex = 0;
        await repository.saveCurrentIndex(0, setName: currentSet);
        if (displayQuestions.isEmpty) {
          emit(QuizEmpty());
        } else {
          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: 0,
            currentSetName: currentSet,
            isShuffled: _isShuffled,
            isStudyMode: _isStudyMode,
          ));
        }
        emit(QuizSetListLoaded(setNames: setNames, currentSet: currentSet));
      } catch (e) {
        emit(QuizError('重命名失败: $e'));
      }
    });

    on<ImportFiles>((event, emit) async {
      emit(QuizImporting(progress: 0, message: '开始导入文件...'));

      try {
        List<Question> allQuestions = [];
        int totalFiles = event.filePaths.length;
        int processed = 0;

        for (var filePath in event.filePaths) {
          bool success = false;
          try {
            final questions = await parser.parseFile(filePath, event.sourceType);
            allQuestions.addAll(questions);
            success = true;
            debugPrint('✅ 解析成功: ${filePath.split('/').last}，得到 ${questions.length} 道题');
          } catch (e) {
            debugPrint('❌ 解析失败: ${filePath.split('/').last}，错误: $e');
          }
          processed++;
          emit(QuizImporting(
            progress: (processed / totalFiles * 100).toInt(),
            message: success
                ? '已解析: ${filePath.split('/').last}'
                : '⚠️ 解析失败: ${filePath.split('/').last}，跳过',
          ));
        }

        if (allQuestions.isEmpty) {
          emit(QuizError('未导入任何有效题目，请检查文件格式'));
          return;
        }

        await repository.saveQuestions(allQuestions, setName: _currentSetName);
        _originalQuestions = List.from(allQuestions);
        _currentOriginalIndex = 0;
        _savedOriginalIndex = 0;
        List<Question> displayQuestions = List.from(allQuestions);
        if (_isShuffled) {
          displayQuestions.shuffle(Random());
        }
        await repository.saveCurrentIndex(0, setName: _currentSetName);

        emit(QuizLoaded(
          questions: displayQuestions,
          currentIndex: 0,
          importMessage: '✅ 成功导入 ${allQuestions.length} 道题目到 $_currentSetName',
          currentSetName: _currentSetName,
          isShuffled: _isShuffled,
          isStudyMode: _isStudyMode,
        ));
        debugPrint('✅ 已发射 QuizLoaded');
      } catch (e) {
        debugPrint('❌ 导入失败: $e');
        emit(QuizError('导入失败: ${e.toString()}'));
      }
    });

    on<AppendFiles>((event, emit) async {
      final existing = await repository.getQuestions(setName: _currentSetName);

      emit(QuizImporting(progress: 0, message: '开始追加导入...'));

      try {
        List<Question> newQuestions = [];
        int totalFiles = event.filePaths.length;
        int processed = 0;

        for (var filePath in event.filePaths) {
          bool success = false;
          try {
            final questions = await parser.parseFile(filePath, event.sourceType);
            newQuestions.addAll(questions);
            success = true;
            debugPrint('✅ 解析成功: ${filePath.split('/').last}，得到 ${questions.length} 道题');
          } catch (e) {
            debugPrint('❌ 解析失败: ${filePath.split('/').last}，错误: $e');
          }
          processed++;
          emit(QuizImporting(
            progress: (processed / totalFiles * 100).toInt(),
            message: success
                ? '已解析: ${filePath.split('/').last}'
                : '⚠️ 解析失败: ${filePath.split('/').last}，跳过',
          ));
        }

        if (newQuestions.isEmpty) {
          emit(QuizError('未解析到有效题目'));
          return;
        }

        final all = [...existing, ...newQuestions];
        await repository.saveQuestions(all, setName: _currentSetName);
        _originalQuestions = List.from(all);
        _currentOriginalIndex = 0;
        _savedOriginalIndex = 0;
        List<Question> displayQuestions = List.from(all);
        if (_isShuffled) {
          displayQuestions.shuffle(Random());
        }
        await repository.saveCurrentIndex(0, setName: _currentSetName);

        emit(QuizLoaded(
          questions: displayQuestions,
          currentIndex: 0,
          importMessage: '✅ 追加导入 ${newQuestions.length} 道题目，共 ${all.length} 道',
          currentSetName: _currentSetName,
          isShuffled: _isShuffled,
          isStudyMode: _isStudyMode,
        ));
      } catch (e) {
        debugPrint('❌ 追加导入失败: $e');
        emit(QuizError('追加导入失败: ${e.toString()}'));
      }
    });

    on<ClearImportMessage>((event, emit) {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        if (current.importMessage != null) {
          emit(current.copyWith(importMessage: null));
        }
      }
    });

    on<ClearAllQuestions>((event, emit) async {
      emit(QuizLoading());
      try {
        await repository.clearAll(setName: _currentSetName);
        _originalQuestions = [];
        _currentOriginalIndex = 0;
        _savedOriginalIndex = 0;
        await repository.saveCurrentIndex(0, setName: _currentSetName);
        emit(QuizEmpty());
        final setNames = await repository.getAllSetNames();
        final currentSet = await repository.getCurrentSetName() ?? '默认题库';
        emit(QuizSetListLoaded(setNames: setNames, currentSet: currentSet));
      } catch (e) {
        emit(QuizError('清空失败: $e'));
      }
    });

    on<ClearFeedback>((event, emit) {
      if (state is QuizLoaded) {
        emit((state as QuizLoaded).copyWith(clearFeedback: true));
      }
    });

    on<ToggleShuffle>((event, emit) async {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        final newShuffleState = !current.isShuffled;

        if (newShuffleState) {
          _savedOriginalIndex = _currentOriginalIndex;

          List<Question> displayQuestions = List.from(current.questions);
          displayQuestions.shuffle(Random());

          int newDisplayIndex = 0;

          if (displayQuestions.isNotEmpty) {
            final firstQuestion = displayQuestions[0];
            final originalIndex = _originalQuestions.indexWhere((q) => q.id == firstQuestion.id);
            _currentOriginalIndex = originalIndex != -1 ? originalIndex : 0;
          } else {
            _currentOriginalIndex = 0;
          }

          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: newDisplayIndex,
            correctCount: current.correctCount,
            currentSetName: _currentSetName,
            isShuffled: true,
            isStudyMode: _isStudyMode,
          ));

          await repository.saveCurrentIndex(_currentOriginalIndex, setName: _currentSetName);
          _isShuffled = true;
          debugPrint('🔄 切换到乱序，进度重置到第一题，正序进度: $_savedOriginalIndex');
        } else {
          List<Question> displayQuestions = List.from(_originalQuestions);

          int displayIndex = _savedOriginalIndex;
          if (displayIndex >= displayQuestions.length) {
            displayIndex = 0;
            _savedOriginalIndex = 0;
          }
          _currentOriginalIndex = _savedOriginalIndex;

          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: displayIndex,
            correctCount: current.correctCount,
            currentSetName: _currentSetName,
            isShuffled: false,
            isStudyMode: _isStudyMode,
          ));

          await repository.saveCurrentIndex(_currentOriginalIndex, setName: _currentSetName);
          _isShuffled = false;
          debugPrint('🔄 切换到正序，恢复到进度: $_savedOriginalIndex');
        }
      }
    });

    on<ToggleStudyMode>((event, emit) {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        final newMode = !current.isStudyMode;
        _isStudyMode = newMode;
        emit(current.copyWith(
          isStudyMode: newMode,
          clearFeedback: true,
        ));
        debugPrint('🔄 切换模式: ${newMode ? "背题模式" : "做题模式"}');
      }
    });

    on<ResetProgress>((event, emit) async {
      emit(QuizLoading());
      try {
        await repository.resetProgress(setName: _currentSetName);

        _currentOriginalIndex = 0;
        _savedOriginalIndex = 0;
        _isShuffled = false;

        _originalQuestions = await repository.getQuestions(setName: _currentSetName);
        List<Question> displayQuestions = List.from(_originalQuestions);

        await repository.saveCurrentIndex(0, setName: _currentSetName);

        if (displayQuestions.isEmpty) {
          emit(QuizEmpty());
        } else {
          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: 0,
            currentSetName: _currentSetName,
            isShuffled: false,
            isStudyMode: _isStudyMode,
          ));
        }

        debugPrint('✅ 重置进度成功（最高优先级），强制回到正序第一题，已重新加载题库');
      } catch (e) {
        debugPrint('❌ 重置进度失败: $e');
        emit(QuizError('重置进度失败: $e'));
      }
    });

    on<GoToQuestion>((event, emit) {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        final total = current.questions.length;
        final targetIndex = event.index;
        if (targetIndex >= 0 && targetIndex < total) {
          final targetQuestion = current.questions[targetIndex];
          final originalIndex = _originalQuestions.indexWhere((q) => q.id == targetQuestion.id);
          if (originalIndex != -1) {
            _currentOriginalIndex = originalIndex;
          }
          emit(current.copyWith(
            currentIndex: targetIndex,
            clearFeedback: true,
          ));
          repository.saveCurrentIndex(_currentOriginalIndex, setName: _currentSetName);
          debugPrint('📍 跳转到显示索引 $targetIndex');
        }
      }
    });

    // ============================================================
    // ✅ SelectAnswer - 添加成就通知
    // ============================================================
    on<SelectAnswer>((event, emit) async {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        final q = current.questions[current.currentIndex];
        if (q.isAnsweredValue) return;

        final isCorrect = event.optionIndex == q.correctIndex;

        if (!isCorrect) {
          q.isWrong = true;
          await repository.addWrongQuestion(q, _currentSetName);
        } else {
          if (await repository.isWrongQuestion(q.id)) {
            await repository.removeWrongQuestion(q.id);
            q.isWrong = false;
          }

          // ✅ 新增：答对时累计总数，触发里程碑通知
          await _checkAndCreateAchievement();
        }

        String feedback;
        final isFill = q.options.length == 1 && q.options.first.contains('填空');
        final isJudge = q.options.length == 2 &&
            q.options.contains('正确') &&
            q.options.contains('错误');

        if (isFill) {
          final correctAnswer = q.answer ?? '未设置答案';
          feedback = isCorrect
              ? '✅ 回答正确！'
              : '❌ 回答错误，正确答案是：$correctAnswer';
        } else if (isJudge) {
          final correctText = q.correctIndex == 0 ? '正确' : '错误';
          feedback = isCorrect
              ? '✅ 回答正确！'
              : '❌ 回答错误，正确答案是：$correctText';
        } else {
          final letter = String.fromCharCode(65 + q.correctIndex);
          feedback = isCorrect
              ? '✅ 回答正确！'
              : '❌ 回答错误，正确答案是 $letter';
        }

        final updatedQuestions = List<Question>.from(current.questions);
        updatedQuestions[current.currentIndex] = q.copyWith(
          selectedOption: event.optionIndex,
          isAnswered: true,
          isWrong: !isCorrect,
        );

        emit(current.copyWith(
          questions: updatedQuestions,
          correctCount: isCorrect ? current.correctCount + 1 : current.correctCount,
          feedback: feedback,
        ));

        await repository.saveQuestions(updatedQuestions, setName: _currentSetName);
        await repository.saveCurrentIndex(_currentOriginalIndex, setName: _currentSetName);
      }
    });

    on<NextQuestion>((event, emit) {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        if (current.isStudyMode) {
          if (current.currentIndex < current.questions.length - 1) {
            final newIndex = current.currentIndex + 1;
            final targetQuestion = current.questions[newIndex];
            final originalIndex = _originalQuestions.indexWhere((q) => q.id == targetQuestion.id);
            if (originalIndex != -1) {
              _currentOriginalIndex = originalIndex;
            }
            emit(current.copyWith(
              currentIndex: newIndex,
              clearFeedback: true,
            ));
            repository.saveCurrentIndex(_currentOriginalIndex, setName: _currentSetName);
          }
          return;
        }

        final allAnswered = current.questions.every((q) => q.isAnsweredValue);
        if (allAnswered) {
          final wrong = current.questions
              .where((q) => q.isAnsweredValue && q.selectedOption != q.correctIndex)
              .toList();
          emit(QuizCompleted(current.correctCount, current.questions.length, wrong));
        } else if (current.currentIndex < current.questions.length - 1) {
          final newIndex = current.currentIndex + 1;
          final targetQuestion = current.questions[newIndex];
          final originalIndex = _originalQuestions.indexWhere((q) => q.id == targetQuestion.id);
          if (originalIndex != -1) {
            _currentOriginalIndex = originalIndex;
          }
          emit(current.copyWith(
            currentIndex: newIndex,
            clearFeedback: true,
          ));
          repository.saveCurrentIndex(_currentOriginalIndex, setName: _currentSetName);
        } else {
          final wrong = current.questions
              .where((q) => q.isAnsweredValue && q.selectedOption != q.correctIndex)
              .toList();
          emit(QuizCompleted(current.correctCount, current.questions.length, wrong));
        }
      }
    });

    on<PreviousQuestion>((event, emit) {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        if (current.currentIndex > 0) {
          final newIndex = current.currentIndex - 1;
          final targetQuestion = current.questions[newIndex];
          final originalIndex = _originalQuestions.indexWhere((q) => q.id == targetQuestion.id);
          if (originalIndex != -1) {
            _currentOriginalIndex = originalIndex;
          }
          emit(current.copyWith(
            currentIndex: newIndex,
            clearFeedback: true,
          ));
          repository.saveCurrentIndex(_currentOriginalIndex, setName: _currentSetName);
        }
      }
    });

    on<QuizCompletedEvent>((event, emit) {
      if (state is QuizLoaded) {
        final current = state as QuizLoaded;
        final correct = current.questions
            .where((q) => q.isAnsweredValue && q.selectedOption == q.correctIndex)
            .length;
        final wrong = current.questions
            .where((q) => q.isAnsweredValue && q.selectedOption != q.correctIndex)
            .toList();
        emit(QuizCompleted(correct, current.questions.length, wrong));
      } else {
        emit(QuizCompleted(event.correctCount, event.totalCount, []));
      }
    });

    on<ResetQuiz>((event, emit) async {
      emit(QuizLoading());
      try {
        await repository.resetProgress(setName: _currentSetName);
        _originalQuestions = await repository.getQuestions(setName: _currentSetName);
        _currentOriginalIndex = 0;
        _savedOriginalIndex = 0;
        List<Question> displayQuestions = List.from(_originalQuestions);
        if (_isShuffled) {
          displayQuestions.shuffle(Random());
        }
        if (displayQuestions.isEmpty) {
          emit(QuizEmpty());
        } else {
          emit(QuizLoaded(
            questions: displayQuestions,
            currentIndex: 0,
            currentSetName: _currentSetName,
            isShuffled: _isShuffled,
            isStudyMode: _isStudyMode,
          ));
        }
        await repository.saveCurrentIndex(0, setName: _currentSetName);
      } catch (e) {
        emit(QuizError('重置失败: $e'));
      }
    });
  }

  // ============================================================
  // ✅ 新增：成就通知检查
  // ============================================================

  Future<void> _checkAndCreateAchievement() async {
    try {
      final totalCorrect = await _getTotalCorrectCount();

      // 用 sourceId 去重，每个里程碑只触发一次
      if (totalCorrect == 10) {
        await notificationRepo.create(
          title: '🎉 完成 10 道题！',
          content: '你已完成 10 道题，继续加油！',
          type: 'achievement',
          actionRoute: '/profile',
          icon: 'star',
          sourceId: 'achievement_10_questions',
        );
      } else if (totalCorrect == 50) {
        await notificationRepo.create(
          title: '🌟 完成 50 道题！',
          content: '离「刷题达人」又近了一步！',
          type: 'achievement',
          actionRoute: '/profile',
          icon: 'star',
          sourceId: 'achievement_50_questions',
        );
      } else if (totalCorrect == 100) {
        await notificationRepo.create(
          title: '🏅 完成 100 道题！',
          content: '太棒了！你已获得「刷题达人」称号！',
          type: 'achievement',
          actionRoute: '/profile',
          icon: 'emoji_events',
          sourceId: 'achievement_100_questions',
        );
      } else if (totalCorrect == 500) {
        await notificationRepo.create(
          title: '🏆 完成 500 道题！',
          content: '你已超越绝大多数学习者！',
          type: 'achievement',
          actionRoute: '/profile',
          icon: 'emoji_events',
          sourceId: 'achievement_500_questions',
        );
      } else if (totalCorrect == 1000) {
        await notificationRepo.create(
          title: '👑 完成 1000 道题！',
          content: '你已是当之无愧的「学神」！',
          type: 'achievement',
          actionRoute: '/profile',
          icon: 'emoji_events',
          sourceId: 'achievement_1000_questions',
        );
      }
    } catch (e) {
      debugPrint('❌ 检查成就通知失败: $e');
    }
  }

  Future<int> _getTotalCorrectCount() async {
    try {
      final setNames = await repository.getAllSetNames();
      int total = 0;
      for (var name in setNames) {
        final questions = await repository.getQuestions(setName: name);
        total += questions.where((q) =>
        q.isAnsweredValue && q.selectedOption == q.correctIndex).length;
      }
      return total;
    } catch (e) {
      debugPrint('❌ 获取总正确数失败: $e');
      return 0;
    }
  }
}