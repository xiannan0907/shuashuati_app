// lib/modules/portalborn/presentation/portalborn_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/portalborn_bloc.dart';
import 'bloc/portalborn_event.dart';
import 'bloc/portalborn_state.dart';
import 'pages/portalborn_main_menu.dart';
import 'pages/portalborn_hub.dart';
import 'pages/portalborn_explore.dart';
import 'pages/portalborn_battle.dart';

class PortalbornScreen extends StatelessWidget {
  const PortalbornScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortalbornBloc, PortalbornState>(
      builder: (context, state) {
        // ✅ 添加调试日志
        print('📌 PortalbornScreen 当前状态: ${state.runtimeType}');

        if (state is PortalbornMainMenu) {
          return const PortalbornMainMenuPage();
        } else if (state is PortalbornHub) {
          return const PortalbornHubPage();
        } else if (state is PortalbornExploring) {
          return PortalbornExplorePage(state: state);
        } else if (state is PortalbornBattle) {
          return PortalbornBattlePage(state: state);
        } else if (state is PortalbornLoading) {
          return const Center(
            child: Text('加载中...', style: TextStyle(color: Colors.white)),
          );
        } else if (state is PortalbornError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<PortalbornBloc>().add(PortalbornLoad());
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        } else {
          // ✅ 如果状态未知，显示错误信息
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                Text(
                  '未知状态: ${state.runtimeType}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<PortalbornBloc>().add(PortalbornLoad());
                  },
                  child: const Text('重新加载'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}