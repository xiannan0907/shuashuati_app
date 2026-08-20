import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/module/app_module.dart';
import '../../../core/bloc/theme_bloc.dart';
import 'presentation/pages/quiz_set_list_page.dart';
import 'presentation/bloc/quiz_bloc.dart';
import 'data/repositories/question_repository.dart';
import 'services/file_parser_service.dart';

class QuizModule implements AppModule {
  @override
  String get id => 'quiz';

  @override
  String get title => '刷题';

  @override
  IconData get icon => Icons.menu_book;

  @override
  bool get enabled => true;

  @override
  bool get supportsIndependentTheme => true;

  @override
  AppThemeMode get defaultTheme => AppThemeMode.system;

  @override
  Widget get homePage {
    return BlocProvider(
      create: (context) => QuizBloc(
        QuestionRepository(),
        FileParserService(),
      )..add(LoadQuizSetList()),
      child: const QuizSetListPage(),
    );
  }

  // ✅ 实现 buildModulePage
  @override
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