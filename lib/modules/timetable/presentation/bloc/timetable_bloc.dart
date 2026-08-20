import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../data/models/course_model.dart';
import '../../data/models/timetable_model.dart';
import '../../data/models/time_table_model.dart';
import '../../data/repositories/timetable_repository.dart';
import '../../services/timetable_parser_service.dart';

// ============================================================
// 事件
// ============================================================

abstract class TimetableEvent {}

class LoadTimetables extends TimetableEvent {}

class LoadTimeTables extends TimetableEvent {}

class AddCourse extends TimetableEvent {
  final Course course;
  AddCourse(this.course);
}

class UpdateCourse extends TimetableEvent {
  final Course course;
  UpdateCourse(this.course);
}

class DeleteCourse extends TimetableEvent {
  final String courseId;
  DeleteCourse(this.courseId);
}

class ClearAllCourses extends TimetableEvent {}

class ImportCourses extends TimetableEvent {
  final String filePath;
  ImportCourses(this.filePath);
}

class SetCurrentTimetable extends TimetableEvent {
  final String timetableId;
  SetCurrentTimetable(this.timetableId);
}

class CreateTimetable extends TimetableEvent {
  final String name;
  final int year;
  final int semester;
  final List<String> courseIds;
  CreateTimetable({
    required this.name,
    required this.year,
    required this.semester,
    this.courseIds = const [],
  });
}

class RenameTimetable extends TimetableEvent {
  final String id;
  final String newName;
  RenameTimetable(this.id, this.newName);
}

class DeleteTimetable extends TimetableEvent {
  final String id;
  DeleteTimetable(this.id);
}

// ✅ 时间表事件
class CreateTimeTable extends TimetableEvent {
  final String name;
  final int morningStart;
  final int afternoonStart;
  final int classDuration;
  final int breakDuration;
  CreateTimeTable({
    required this.name,
    required this.morningStart,
    required this.afternoonStart,
    required this.classDuration,
    required this.breakDuration,
  });
}

class UpdateTimeTable extends TimetableEvent {
  final TimeTable timeTable;
  UpdateTimeTable(this.timeTable);
}

class DeleteTimeTable extends TimetableEvent {
  final String id;
  DeleteTimeTable(this.id);
}

class SetTimetableTimeTable extends TimetableEvent {
  final String timetableId;
  final String? timeTableId;
  SetTimetableTimeTable(this.timetableId, this.timeTableId);
}

// ✅ 导出事件
class ExportCourses extends TimetableEvent {
  final String filePath;
  final String format; // 'json' 或 'xlsx'
  ExportCourses(this.filePath, this.format);
}

// ============================================================
// 状态
// ============================================================

abstract class TimetableState {}

class TimetableInitial extends TimetableState {}

class TimetableLoading extends TimetableState {}

class TimetableLoaded extends TimetableState {
  final List<Course> courses;
  final List<Timetable> timetables;
  final Timetable? currentTimetable;
  final List<TimeTable> timeTables;
  final String? importMessage;
  final String? lastExportedFilePath; // ✅ 最近导出的文件路径

  TimetableLoaded({
    required this.courses,
    required this.timetables,
    this.currentTimetable,
    this.timeTables = const [],
    this.importMessage,
    this.lastExportedFilePath,
  });

  TimetableLoaded copyWith({
    List<Course>? courses,
    List<Timetable>? timetables,
    Timetable? currentTimetable,
    List<TimeTable>? timeTables,
    String? importMessage,
    String? lastExportedFilePath,
    bool clearImportMessage = false,
    bool clearLastExportedFilePath = false,
  }) {
    return TimetableLoaded(
      courses: courses ?? this.courses,
      timetables: timetables ?? this.timetables,
      currentTimetable: currentTimetable ?? this.currentTimetable,
      timeTables: timeTables ?? this.timeTables,
      importMessage: clearImportMessage ? null : (importMessage ?? this.importMessage),
      lastExportedFilePath: clearLastExportedFilePath
          ? null
          : (lastExportedFilePath ?? this.lastExportedFilePath),
    );
  }
}

class TimetableError extends TimetableState {
  final String message;
  TimetableError(this.message);
}

// ============================================================
// BLoC
// ============================================================

class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final TimetableRepository repository;
  final TimetableParserService parser;

  TimetableBloc(this.repository, this.parser) : super(TimetableInitial()) {
    // ============================================================
    // 加载课表
    // ============================================================
    on<LoadTimetables>((event, emit) async {
      emit(TimetableLoading());
      try {
        final timetables = await repository.getAllTimetables();
        final current = await repository.getCurrentTimetable();
        final courses = await repository.getCurrentTimetableCourses();
        final timeTables = await repository.getAllTimeTables();
        emit(TimetableLoaded(
          courses: courses,
          timetables: timetables,
          currentTimetable: current,
          timeTables: timeTables,
        ));
      } catch (e) {
        emit(TimetableError('加载课表失败: $e'));
      }
    });

    // ============================================================
    // 加载时间表
    // ============================================================
    on<LoadTimeTables>((event, emit) async {
      try {
        final timeTables = await repository.getAllTimeTables();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(timeTables: timeTables));
        }
      } catch (e) {
        emit(TimetableError('加载时间表失败: $e'));
      }
    });

    // ============================================================
    // 切换课表
    // ============================================================
    on<SetCurrentTimetable>((event, emit) async {
      try {
        await repository.setCurrentTimetable(event.timetableId);
        final timetables = await repository.getAllTimetables();
        final current = await repository.getCurrentTimetable();
        final courses = await repository.getCurrentTimetableCourses();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(
            timetables: timetables,
            currentTimetable: current,
            courses: courses,
          ));
        }
      } catch (e) {
        emit(TimetableError('切换课表失败: $e'));
      }
    });

    // ============================================================
    // 添加课程
    // ============================================================
    on<AddCourse>((event, emit) async {
      try {
        await repository.addCourseToCurrentTimetable(event.course);
        final courses = await repository.getCurrentTimetableCourses();
        if (state is TimetableLoaded) {
          final current = state as TimetableLoaded;
          emit(current.copyWith(courses: courses));
        }
      } catch (e) {
        emit(TimetableError('添加课程失败: $e'));
      }
    });

    // ============================================================
    // 更新课程
    // ============================================================
    on<UpdateCourse>((event, emit) async {
      try {
        await repository.removeCourseFromTimetable(event.course.id);
        await repository.saveCourse(event.course);
        await repository.addCourseToCurrentTimetable(event.course);
        final courses = await repository.getCurrentTimetableCourses();
        if (state is TimetableLoaded) {
          final current = state as TimetableLoaded;
          emit(current.copyWith(courses: courses));
        }
      } catch (e) {
        emit(TimetableError('更新课程失败: $e'));
      }
    });

    // ============================================================
    // 删除课程
    // ============================================================
    on<DeleteCourse>((event, emit) async {
      try {
        await repository.removeCourseFromTimetable(event.courseId);
        await repository.deleteCourse(event.courseId);
        final courses = await repository.getCurrentTimetableCourses();
        if (state is TimetableLoaded) {
          final current = state as TimetableLoaded;
          emit(current.copyWith(courses: courses));
        }
      } catch (e) {
        emit(TimetableError('删除课程失败: $e'));
      }
    });

// ============================================================
// 清空当前课表的课程（不删除其他课表）
// ============================================================
    on<ClearAllCourses>((event, emit) async {
      try {
        // 获取当前课表
        final currentTimetable = await repository.getCurrentTimetable();
        if (currentTimetable == null) {
          emit(TimetableError('没有当前课表'));
          return;
        }

        // 删除该课表下的所有课程
        final courseBox = await Hive.openBox<Course>(TimetableRepository.courseBoxName);
        for (var courseId in currentTimetable.courseIds) {
          await courseBox.delete(courseId);
        }

        // 清空课表的 courseIds
        currentTimetable.courseIds.clear();
        await repository.saveTimetable(currentTimetable);

        // 重新加载并更新状态
        final courses = await repository.getCurrentTimetableCourses();
        final timetables = await repository.getAllTimetables();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(
            courses: courses,
            timetables: timetables,
            currentTimetable: currentTimetable,
          ));
        } else {
          final timeTables = await repository.getAllTimeTables();
          emit(TimetableLoaded(
            courses: courses,
            timetables: timetables,
            currentTimetable: currentTimetable,
            timeTables: timeTables,
          ));
        }
      } catch (e) {
        emit(TimetableError('清空当前课表失败: $e'));
      }
    });
    // ============================================================
    // 导入课程
    // ============================================================
    on<ImportCourses>((event, emit) async {
      emit(TimetableLoading());
      try {
        final courses = await parser.parseFile(event.filePath);
        for (var course in courses) {
          await repository.addCourseToCurrentTimetable(course);
        }
        final allCourses = await repository.getCurrentTimetableCourses();

        if (state is TimetableLoaded) {
          final current = state as TimetableLoaded;
          emit(current.copyWith(
            courses: allCourses,
            importMessage: '成功导入 ${courses.length} 门课程',
          ));
        } else {
          final timetables = await repository.getAllTimetables();
          final currentTimetable = await repository.getCurrentTimetable();
          final timeTables = await repository.getAllTimeTables();
          emit(TimetableLoaded(
            courses: allCourses,
            timetables: timetables,
            currentTimetable: currentTimetable,
            timeTables: timeTables,
            importMessage: '成功导入 ${courses.length} 门课程',
          ));
        }

        await Future.delayed(const Duration(seconds: 5));
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(clearImportMessage: true));
        }
      } catch (e) {
        emit(TimetableError('导入失败: ${e.toString()}'));
      }
    });

    // ============================================================
    // 创建课表
    // ============================================================
    on<CreateTimetable>((event, emit) async {
      try {
        final timetable = Timetable(
          id: 'tt_${DateTime.now().millisecondsSinceEpoch}',
          name: event.name,
          year: event.year,
          semester: event.semester,
          courseIds: event.courseIds,
          isCurrent: true,
        );
        await repository.saveTimetable(timetable);

        final all = await repository.getAllTimetables();
        for (var t in all) {
          if (t.id != timetable.id) {
            t.isCurrent = false;
            await repository.saveTimetable(t);
          }
        }

        final timetables = await repository.getAllTimetables();
        final courses = await repository.getCurrentTimetableCourses();
        final timeTables = await repository.getAllTimeTables();

        emit(TimetableLoaded(
          courses: courses,
          timetables: timetables,
          currentTimetable: timetable,
          timeTables: timeTables,
        ));
      } catch (e) {
        emit(TimetableError('创建课表失败: $e'));
      }
    });

    // ============================================================
    // 重命名课表
    // ============================================================
    on<RenameTimetable>((event, emit) async {
      try {
        await repository.renameTimetable(event.id, event.newName);
        final timetables = await repository.getAllTimetables();
        final current = await repository.getCurrentTimetable();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(
            timetables: timetables,
            currentTimetable: current,
          ));
        }
      } catch (e) {
        emit(TimetableError('重命名失败: $e'));
      }
    });

    // ============================================================
    // 删除课表
    // ============================================================
    on<DeleteTimetable>((event, emit) async {
      try {
        await repository.deleteTimetableWithCourses(event.id);
        final timetables = await repository.getAllTimetables();
        final current = await repository.getCurrentTimetable();
        final courses = await repository.getCurrentTimetableCourses();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(
            timetables: timetables,
            currentTimetable: current,
            courses: courses,
          ));
        }
      } catch (e) {
        emit(TimetableError('删除课表失败: $e'));
      }
    });

    // ============================================================
    // 创建时间表
    // ============================================================
    on<CreateTimeTable>((event, emit) async {
      try {
        final timeTable = TimeTable(
          id: 'tt_${DateTime.now().millisecondsSinceEpoch}',
          name: event.name,
          morningStart: event.morningStart,
          afternoonStart: event.afternoonStart,
          classDuration: event.classDuration,
          breakDuration: event.breakDuration,
        );
        await repository.saveTimeTable(timeTable);
        final timeTables = await repository.getAllTimeTables();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(timeTables: timeTables));
        }
      } catch (e) {
        emit(TimetableError('创建时间表失败: $e'));
      }
    });

    // ============================================================
    // 更新时间表
    // ============================================================
    on<UpdateTimeTable>((event, emit) async {
      try {
        await repository.saveTimeTable(event.timeTable);
        final timeTables = await repository.getAllTimeTables();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(timeTables: timeTables));
        }
      } catch (e) {
        emit(TimetableError('更新时间表失败: $e'));
      }
    });

    // ============================================================
    // 删除时间表
    // ============================================================
    on<DeleteTimeTable>((event, emit) async {
      try {
        await repository.deleteTimeTable(event.id);
        final timeTables = await repository.getAllTimeTables();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(timeTables: timeTables));
        }
      } catch (e) {
        emit(TimetableError('删除时间表失败: $e'));
      }
    });

    // ============================================================
    // 设置课表关联的时间表
    // ============================================================
    on<SetTimetableTimeTable>((event, emit) async {
      try {
        await repository.updateTimetableTimeTable(event.timetableId, event.timeTableId);
        final timetables = await repository.getAllTimetables();
        final current = await repository.getCurrentTimetable();
        final timeTables = await repository.getAllTimeTables();
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(
            timetables: timetables,
            currentTimetable: current,
            timeTables: timeTables,
          ));
        }
      } catch (e) {
        emit(TimetableError('设置课表时间表失败: $e'));
      }
    });

    // ============================================================
    // ✅ 导出课程（完整版）
    // ============================================================
    on<ExportCourses>((event, emit) async {
      try {
        final courses = await repository.getCurrentTimetableCourses();
        if (courses.isEmpty) {
          emit(TimetableError('当前课表没有课程可导出'));
          return;
        }

        final file = await parser.exportCourses(courses, event.filePath, event.format);

        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(
            importMessage: '✅ 成功导出 ${courses.length} 门课程',
            lastExportedFilePath: file.path,
          ));
        } else {
          // 如果当前状态不是 TimetableLoaded，创建新状态
          final timetables = await repository.getAllTimetables();
          final currentTimetable = await repository.getCurrentTimetable();
          final timeTables = await repository.getAllTimeTables();
          emit(TimetableLoaded(
            courses: courses,
            timetables: timetables,
            currentTimetable: currentTimetable,
            timeTables: timeTables,
            importMessage: '✅ 成功导出 ${courses.length} 门课程',
            lastExportedFilePath: file.path,
          ));
        }

        // 5秒后清除消息（但保留文件路径）
        await Future.delayed(const Duration(seconds: 5));
        if (state is TimetableLoaded) {
          final loaded = state as TimetableLoaded;
          emit(loaded.copyWith(
            clearImportMessage: true,
            // 保留 lastExportedFilePath
          ));
        }
      } catch (e) {
        emit(TimetableError('导出失败: ${e.toString()}'));
      }
    });
  }
}