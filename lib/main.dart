import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/pages/home_page.dart';

import 'core/bloc/theme_bloc.dart';
import 'core/theme/app_theme.dart';

import 'modules/quiz/data/models/question_model.dart';
import 'modules/quiz/data/models/wrong_question_stats.dart';
import 'modules/quiz/data/models/tower_model.dart';
import 'data/models/notification_item.dart';
import 'data/models/user_model.dart';
import 'data/repositories/notification_repository.dart';

import 'modules/timetable/data/models/course_model.dart';
import 'modules/timetable/data/models/timetable_model.dart';
import 'modules/timetable/data/models/time_table_model.dart';
import 'dart:async';  // ✅ 添加这行
import 'modules/portalborn/data/models/character_model.dart';
import 'modules/portalborn/data/models/item_model.dart';
import 'modules/portalborn/data/models/game_state_model.dart';
import 'modules/portalborn/data/models/ugc_model.dart';

void main() async {
  // ✅ 添加全局异常捕获
  runZonedGuarded(
        () async {
      WidgetsFlutterBinding.ensureInitialized();
      print('✅ 1. WidgetsFlutterBinding 初始化完成');

      await Hive.initFlutter();
      print('✅ 2. Hive 初始化完成');

      // ═══════════════════════════════════════════════════════════
      // ⚠️ 开发阶段：强制删除所有旧数据（避免 typeId 冲突）
      // ═══════════════════════════════════════════════════════════
      try {
        final boxNames = [
          'questions', 'wrong_stats', 'tower',
          'notifications',
          'timetables', 'time_tables', 'courses',
          'portalborn'
        ];
        for (final name in boxNames) {
          if (await Hive.boxExists(name)) {
            await Hive.deleteBoxFromDisk(name);
            print('✅ 已删除 $name');
          }
        }
      } catch (e) {
        print('⚠️ 删除数据失败: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // ✅ 打开所有 Hive Box
      // ═══════════════════════════════════════════════════════════
      print('⏳ 3. 开始打开 Hive Boxes...');

      await Hive.openBox('questions');
      print('✅ 3.1 questions 打开成功');
      await Hive.openBox('wrong_stats');
      print('✅ 3.2 wrong_stats 打开成功');
      await Hive.openBox('tower');
      print('✅ 3.3 tower 打开成功');
      await Hive.openBox('notifications');
      print('✅ 3.4 notifications 打开成功');
      await Hive.openBox('timetables');
      print('✅ 3.5 timetables 打开成功');
      await Hive.openBox('time_tables');
      print('✅ 3.6 time_tables 打开成功');
      await Hive.openBox('courses');
      print('✅ 3.7 courses 打开成功');
      await Hive.openBox('portalborn');
      print('✅ 3.8 portalborn 打开成功');

      // ============================================================
      // ✅ 注册所有 Hive 适配器
      // ============================================================
      print('⏳ 4. 开始注册适配器...');

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(QuestionAdapter());
        print('✅ 4.1 QuestionAdapter');
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(WrongQuestionStatsAdapter());
        print('✅ 4.2 WrongQuestionStatsAdapter');
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TowerProgressAdapter());
        print('✅ 4.3 TowerProgressAdapter');
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(NotificationItemAdapter());
        print('✅ 4.4 NotificationItemAdapter');
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(UserModelAdapter());
        print('✅ 4.5 UserModelAdapter');
      }
      if (!Hive.isAdapterRegistered(30)) {
        Hive.registerAdapter(CourseAdapter());
        print('✅ 4.6 CourseAdapter');
      }
      if (!Hive.isAdapterRegistered(31)) {
        Hive.registerAdapter(TimetableAdapter());
        print('✅ 4.7 TimetableAdapter');
      }
      if (!Hive.isAdapterRegistered(32)) {
        Hive.registerAdapter(TimeTableAdapter());
        print('✅ 4.8 TimeTableAdapter');
      }
      if (!Hive.isAdapterRegistered(33)) {
        Hive.registerAdapter(GameCharacterAdapter());
        print('✅ 4.9 GameCharacterAdapter');
      }
      if (!Hive.isAdapterRegistered(34)) {
        Hive.registerAdapter(GameItemAdapter());
        print('✅ 4.10 GameItemAdapter');
      }
      if (!Hive.isAdapterRegistered(35)) {
        Hive.registerAdapter(GameStateAdapter());
        print('✅ 4.11 GameStateAdapter');
      }
      if (!Hive.isAdapterRegistered(36)) {
        Hive.registerAdapter(UGCCustomRealmAdapter());
        print('✅ 4.12 UGCCustomRealmAdapter');
      }
      if (!Hive.isAdapterRegistered(37)) {
        Hive.registerAdapter(UGCRoomAdapter());
        print('✅ 4.13 UGCRoomAdapter');
      }
      if (!Hive.isAdapterRegistered(38)) {
        Hive.registerAdapter(UGCExitAdapter());
        print('✅ 4.14 UGCExitAdapter');
      }
      if (!Hive.isAdapterRegistered(39)) {
        Hive.registerAdapter(UGCInteractableAdapter());
        print('✅ 4.15 UGCInteractableAdapter');
      }
      if (!Hive.isAdapterRegistered(40)) {
        Hive.registerAdapter(UGCMonsterAdapter());
        print('✅ 4.16 UGCMonsterAdapter');
      }
      if (!Hive.isAdapterRegistered(41)) {
        Hive.registerAdapter(UGCDropAdapter());
        print('✅ 4.17 UGCDropAdapter');
      }
      if (!Hive.isAdapterRegistered(42)) {
        Hive.registerAdapter(UGCItemAdapter());
        print('✅ 4.18 UGCItemAdapter');
      }

      // ═══════════════════════════════════════════════════════════
      // ✅ 初始化通知数据
      // ═══════════════════════════════════════════════════════════
      print('⏳ 5. 初始化通知数据...');
      await notificationRepo.initSampleNotifications();
      print('✅ 5. 通知数据初始化完成');

      print('✅ 6. 启动应用...');
      runApp(const MyApp());
    },
        (error, stack) {
      print('❌❌❌ 未捕获的异常: $error');
      print(stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          ThemeMode themeMode;
          switch (themeState.globalMode) {
            case AppThemeMode.light:
              themeMode = ThemeMode.light;
              break;
            case AppThemeMode.dark:
              themeMode = ThemeMode.dark;
              break;
            case AppThemeMode.system:
              themeMode = ThemeMode.system;
              break;
          }

          return MaterialApp(
            title: '刷刷题',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeMode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}