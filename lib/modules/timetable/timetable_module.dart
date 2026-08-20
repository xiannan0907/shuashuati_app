import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/module/app_module.dart';
import '../../../core/bloc/theme_bloc.dart';
import 'presentation/pages/timetable_main_page.dart';
import 'presentation/bloc/timetable_bloc.dart';
import 'data/repositories/timetable_repository.dart';
import 'services/timetable_parser_service.dart';

class TimetableModule implements AppModule {
  @override
  String get id => 'timetable';

  @override
  String get title => '课表';

  @override
  IconData get icon => Icons.calendar_month;

  @override
  bool get enabled => true;

  @override
  bool get supportsIndependentTheme => true;

  @override
  AppThemeMode get defaultTheme => AppThemeMode.system;

  @override
  Widget get homePage {
    return BlocProvider(
      create: (context) => TimetableBloc(
        TimetableRepository(),
        TimetableParserService(),
      )..add(LoadTimetables()),
      child: const TimetableMainPage(),
    );
  }

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