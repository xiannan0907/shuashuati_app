import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'presentation/pages/home_page.dart';
import 'core/bloc/theme_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/notification_repository.dart';
import 'data/models/user_model.dart';
import 'data/models/notification_item.dart';
import 'modules/quiz/data/models/wrong_question_stats.dart';
import 'modules/quiz/data/models/tower_model.dart';
import 'modules/timetable/data/models/course_model.dart';
import 'modules/timetable/data/models/timetable_model.dart';
import 'modules/timetable/data/models/time_table_model.dart';
import 'hive_registrar.g.dart';

void main() async {
  // ✅ 添加全局异常捕获
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('✅ 1. WidgetsFlutterBinding 初始化完成');

      // ⚠️ release 模式静默 debugPrint（166 处调用不输出，避免日志/路径泄露）
      if (!kDebugMode) {
        debugPrint = (String? message, {int? wrapWidth}) {};
      }

      await Hive.initFlutter();
      debugPrint('✅ 2. Hive 初始化完成');

      // ✅ 注册所有 Hive 适配器（由 hive_ce_generator 自动生成）
      Hive.registerAdapters();
      debugPrint('✅ 3. 适配器注册完成');

      // ✅ 打开所有 Hive Box
      debugPrint('⏳ 4. 开始打开 Hive Boxes...');

      // ✅ 打开所有 Hive Box（与各 Repository 实际 box 名及泛型一致，避免类型冲突）
      debugPrint('⏳ 4. 开始打开 Hive Boxes...');

      await Hive.openBox<String>('quizSetsBox');
      debugPrint('✅ 4.1 quizSetsBox 打开成功');
      await Hive.openBox<Map>('wrongQuestionsBox');
      debugPrint('✅ 4.2 wrongQuestionsBox 打开成功');
      await Hive.openBox<WrongQuestionStats>('wrongStatsBox');
      debugPrint('✅ 4.3 wrongStatsBox 打开成功');
      await Hive.openBox<TowerProgress>('towerBox');
      debugPrint('✅ 4.4 towerBox 打开成功');
      await Hive.openBox<NotificationItem>('notificationBox');
      debugPrint('✅ 4.5 notificationBox 打开成功');
      await Hive.openBox<Course>('timetable_courses');
      debugPrint('✅ 4.6 timetable_courses 打开成功');
      await Hive.openBox<Timetable>('timetable_list');
      debugPrint('✅ 4.7 timetable_list 打开成功');
      await Hive.openBox<TimeTable>('time_table_list');
      debugPrint('✅ 4.8 time_table_list 打开成功');
      await Hive.openBox('portalborn');
      debugPrint('✅ 4.9 portalborn 打开成功');
      await Hive.openBox<UserModel>('userBox');
      debugPrint('✅ 4.10 userBox 打开成功');
      await Hive.openBox<String>('themeSettings');
      debugPrint('✅ 4.11 themeSettings 打开成功');
      await Hive.openBox<String>('settingsBox');
      debugPrint('✅ 4.12 settingsBox 打开成功');
      await Hive.openBox<String>('timetable_settings');
      debugPrint('✅ 4.13 timetable_settings 打开成功');

      // ✅ 初始化通知数据
      debugPrint('⏳ 5. 初始化通知数据...');
      await notificationRepo.initSampleNotifications();
      debugPrint('✅ 5. 通知数据初始化完成');

      debugPrint('✅ 6. 启动应用...');
      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('❌❌❌ 未捕获的异常: $error');
      debugPrint(stack.toString());
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
