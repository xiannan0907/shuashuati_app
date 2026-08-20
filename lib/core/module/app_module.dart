import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/theme_bloc.dart';

/// 所有模块必须实现的接口
abstract class AppModule {
  /// 模块唯一标识（如 'quiz'）
  String get id;

  /// 底部导航栏显示的名称
  String get title;

  /// 底部导航栏图标
  IconData get icon;

  /// 模块的根页面（点击底部导航时显示）
  Widget get homePage;

  /// 模块是否启用（用于灰度或付费解锁）
  bool get enabled => true;

  /// 模块是否支持独立主题
  bool get supportsIndependentTheme => true;

  /// 模块默认主题（如果支持独立主题）
  AppThemeMode get defaultTheme => AppThemeMode.system;

  /// 构建模块页面（自动包裹主题）
  Widget buildModulePage(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final effectiveMode = themeCubit.getEffectiveTheme(id);

    return Theme(
      data: _getThemeData(effectiveMode, context),
      child: homePage,
    );
  }

  ThemeData _getThemeData(AppThemeMode mode, BuildContext context) {
    final baseTheme = Theme.of(context);
    switch (mode) {
      case AppThemeMode.light:
        return ThemeData.light().copyWith(
          primaryColor: baseTheme.primaryColor,
          appBarTheme: baseTheme.appBarTheme,
          scaffoldBackgroundColor: baseTheme.scaffoldBackgroundColor,
          cardTheme: baseTheme.cardTheme,
          colorScheme: baseTheme.colorScheme,
        );
      case AppThemeMode.dark:
        return ThemeData.dark().copyWith(
          primaryColor: baseTheme.primaryColor,
          appBarTheme: baseTheme.appBarTheme,
          scaffoldBackgroundColor: baseTheme.scaffoldBackgroundColor,
          cardTheme: baseTheme.cardTheme,
          colorScheme: baseTheme.colorScheme,
        );
      case AppThemeMode.system:
        return baseTheme;
    }
  }
}