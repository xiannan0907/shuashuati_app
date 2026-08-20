import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/bloc/portalborn_bloc.dart';
import '../../presentation/bloc/portalborn_event.dart';
import '../../presentation/bloc/portalborn_state.dart';
import '../widgets/portalborn_loading.dart';
import 'portalborn_create_character.dart';

class PortalbornMainMenuPage extends StatelessWidget {
  const PortalbornMainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF0a0a0f), Color(0xFF141425)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: BlocBuilder<PortalbornBloc, PortalbornState>(
                builder: (context, state) {
                  if (state is PortalbornLoading) {
                    return const PortalbornLoadingWidget(message: '加载中...');
                  }
                  if (state is PortalbornMainMenu) {
                    return _MainMenuContent(
                      hasSave: state.hasSave,
                      characters: state.characters,
                    );
                  }
                  if (state is PortalbornError) {
                    return _ErrorContent(message: state.message);
                  }
                  // 其他状态（如 Hub）理论上不会在这里出现，因为由 Screen 分发
                  return const PortalbornLoadingWidget(message: '准备中...');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// _MainMenuContent, _ErrorContent 保持不变（与之前相同）

// _MainMenuContent, _ErrorContent 等保持不变...

// ... 其余组件保持不变 ...
class _MainMenuContent extends StatelessWidget {
  final bool hasSave;
  final List<dynamic> characters;

  const _MainMenuContent({
    required this.hasSave,
    required this.characters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Logo(),
        const SizedBox(height: 48),
        if (hasSave) ...[
          _MenuButton(
            icon: Icons.play_arrow,
            label: '继续冒险',
            subtitle: '加载上次的存档',
            onTap: () {
              if (characters.isNotEmpty) {
                context.read<PortalbornBloc>().add(
                  PortalbornSelectCharacter(
                    characters.first.id,
                  ),
                );
              }
            },
            isPrimary: true,
          ),
          const SizedBox(height: 16),
        ],
        _MenuButton(
          icon: Icons.add,
          label: '新游戏',
          subtitle: '创建新的角色',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PortalbornBloc>(),
                  child: const PortalbornCreateCharacterPage(),
                ),
              ),
            );
          },
          isPrimary: !hasSave,
        ),
        const SizedBox(height: 16),
        _MenuButton(
          icon: Icons.settings,
          label: '传送门工坊',
          subtitle: '探索自定义领域',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('工坊功能开发中...')),
            );
          },
        ),
        const SizedBox(height: 16),
        _MenuButton(
          icon: Icons.help_outline,
          label: '游戏指南',
          subtitle: '了解基本玩法',
          onTap: () {
            _showHelpDialog(context);
          },
        ),
        const SizedBox(height: 48),
        Text(
          'Portalborn v0.1.0',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📖 游戏指南'),
        content: const SingleChildScrollView(
          child: Text(
            '🎯 目标\n'
                '探索传送门后的神秘领域，击败Boss，收集宝藏。\n\n'
                '⌨️ 基本操作\n'
                '• 移动: north/south/east/west/up/down\n'
                '• 战斗: attack / defend / flee\n'
                '• 交互: look / examine / search / open\n'
                '• 物品: inventory / equip / use / drop\n'
                '• 角色: status / levelup / rest\n\n'
                '💡 提示\n'
                '输入 "help" 查看所有命令',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.explore,
          size: 80,
          color: Color(0xFF00ff88),
        ),
        const SizedBox(height: 16),
        const Text(
          'Portalborn',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00ff88),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '传送门编年史',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'MUD 文字冒险',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _MenuButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          backgroundColor: isPrimary ? const Color(0xFF00ff88) : Colors.transparent,
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.grey[800]!),
          ),
          elevation: isPrimary ? 4 : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isPrimary ? Colors.black87 : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;

  const _ErrorContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: Color(0xFFff3355),
        ),
        const SizedBox(height: 24),
        const Text(
          '加载失败',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            context.read<PortalbornBloc>().add(PortalbornLoad());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00ff88),
            foregroundColor: Colors.black,
          ),
          child: const Text('重试'),
        ),
      ],
    );
  }
}