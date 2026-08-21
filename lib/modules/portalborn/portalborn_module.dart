// lib/modules/portalborn/portalborn_module.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/module/app_module.dart';
import 'data/repositories/game_repository.dart';
import 'presentation/bloc/portalborn_bloc.dart';
import 'presentation/bloc/portalborn_event.dart';
import 'presentation/portalborn_screen.dart';

class PortalbornModule extends AppModule {
  @override
  String get id => 'portalborn';
  @override
  String get title => '传送门编年史';
  @override
  IconData get icon => Icons.explore;
  // ✅ 占位页不依赖 Bloc（进入游戏时才创建 PortalbornBloc，见下方按钮）
  @override
  Widget get homePage => const PortalbornMainMenuPlaceholder();
  @override
  bool get enabled => true;
}

// 占位页面（含进入按钮）
class PortalbornMainMenuPlaceholder extends StatelessWidget {
  const PortalbornMainMenuPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌀 传送门编年史'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 80,
              color: const Color(0xFF00ff88),
            ),
            const SizedBox(height: 24),
            const Text(
              'Portalborn',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00ff88),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MUD 文字冒险',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? const Color(0xFF8888aa) : const Color(0xFF666688),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141425).withValues(alpha: 0.8)
                    : const Color(0xFFf0eee8).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2a2a4a) : const Color(0xFFd0ccc8),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '📖 开发中 - P0 阶段',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '基础框架已搭建，数据模型与种子数据加载中...\n'
                        '预计功能将在后续阶段逐步开放。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF666688) : const Color(0xFF999999),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // ✅ 进入游戏：创建全新 Bloc（pop 后销毁，避免静态单例跨页面持旧状态）
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => PortalbornBloc(repository: GameRepository())..add(PortalbornLoad()),
                      child: const PortalbornScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('🎮 进入游戏（测试版）'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ff88),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回首页'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                side: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[400]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}