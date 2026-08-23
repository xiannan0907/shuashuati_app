import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'presentation/pages/home_page.dart';
import 'core/bloc/theme_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/notification_repository.dart';
import 'data/models/notification_item.dart';
import 'modules/ledger/ledger_module.dart';
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

      // ✅ 全局 UI 错误兜底：渲染异常时显示友好页面而非灰屏，并记录日志
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('❌ Flutter 框架错误: ${details.exception}');
      };
      ErrorWidget.builder = (details) => Material(
            color: Colors.grey.shade100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('页面出错了', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    '${details.exception}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );

      await Hive.initFlutter();
      debugPrint('✅ 2. Hive 初始化完成');

      // ✅ 注册所有 Hive 适配器（由 hive_ce_generator 自动生成）
      Hive.registerAdapters();
      debugPrint('✅ 3. 适配器注册完成');

      // ✅ 启动性能优化：仅预开首屏必需的 box（notificationBox=首页红点；
      //    portalborn=GameRepository 构造要求已打开）。其余 box 由各 Repository
      //    运行期按需打开（Hive.openBox 幂等，已打开直接返回），大幅减少首帧主线程 IO。
      debugPrint('⏳ 4. 打开启动必需 Hive Boxes...');
      await Hive.openBox<NotificationItem>('notificationBox');
      debugPrint('✅ 4.1 notificationBox 打开成功');
      await Hive.openBox('portalborn');
      debugPrint('✅ 4.2 portalborn 打开成功');

      // ✅ 初始化通知数据
      debugPrint('⏳ 5. 初始化通知数据...');
      await notificationRepo.initSampleNotifications();
      debugPrint('✅ 5. 通知数据初始化完成');

      // ✅ 初始化记账模块种子数据（默认账本/账户/预置分类）
      await LedgerModule.init();
      debugPrint('✅ 5.1 记账模块初始化完成');

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
            title: '题屿',
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
