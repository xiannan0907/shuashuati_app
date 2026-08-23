// lib/modules/ledger/ledger_module.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/module/app_module.dart';
import 'data/repositories/ledger_repository.dart';
import 'presentation/bloc/ledger_bloc.dart';
import 'presentation/pages/ledger_home_page.dart';

/// 💰 记账模块（学习开销记录）
class LedgerModule extends AppModule {
  @override
  String get id => 'ledger';
  @override
  String get title => '记账';
  @override
  IconData get icon => Icons.savings;

  @override
  Widget get homePage {
    return BlocProvider(
      create: (_) => LedgerBloc(repository: LedgerRepository())..add(LedgerStarted()),
      child: const LedgerHomePage(),
    );
  }

  /// 初始化种子数据（默认账本/账户/预置分类）——由 main 启动时调用
  static Future<void> init() => LedgerRepository().initIfNeeded();
}
