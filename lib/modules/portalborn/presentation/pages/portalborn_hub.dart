import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../portalborn_module.dart';
import '../../presentation/bloc/portalborn_bloc.dart';
import '../../presentation/bloc/portalborn_event.dart';
import '../../presentation/bloc/portalborn_state.dart';
import '../widgets/portalborn_status_bar.dart';
import '../widgets/portalborn_terminal.dart';
import '../widgets/portalborn_command_input.dart';
import 'portalborn_inventory.dart';
import 'portalborn_crafting.dart';

class PortalbornHubPage extends StatelessWidget {
  const PortalbornHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      body: SafeArea(
        child: BlocBuilder<PortalbornBloc, PortalbornState>(
          builder: (context, state) {
            if (state is PortalbornHub) {
              return _HubContent(state: state);
            }
            // 其他状态由 Screen 处理，这里不会出现
            return const Center(child: Text('加载中...', style: TextStyle(color: Colors.white)));
          },
        ),
      ),
    );
  }
}

class _HubContent extends StatelessWidget {
  final PortalbornHub state;
  const _HubContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final character = state.character;
    final messages = state.messages;

    return Column(
      children: [
        PortalbornStatusBar(character: character, showStats: true),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.explore, size: 20, color: Color(0xFF00ff88)),
              const SizedBox(width: 8),
              const Text('🏠 传送门大厅', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF141425), borderRadius: BorderRadius.circular(12)),
                child: Text('🎯 ${state.gameState.totalRealmsCompleted} 领域', style: const TextStyle(fontSize: 12, color: Color(0xFF8888aa))),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final bloc = PortalbornModule.bloc;
                  if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand('go portal'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFaa55ff),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('🌀 进入传送门', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),
        Expanded(
          child: PortalbornTerminal(
            messages: messages,
            placeholder: _getWelcomeMessage(state.character.name),
          ),
        ),
        // 快捷按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF0d0d1a),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickButton(
                icon: Icons.backpack,
                label: '背包',
                onTap: () {
                  // 直接打开背包页面（使用 Dialog 或 push，但 push 会导致状态不同步，建议用 Dialog）
                  // 为了简单，这里使用 Navigator，但需要确保不会影响状态
                  // 由于我们采用状态驱动，打开背包应使用新页面，但为了快速修复，暂时保留
                  // 但更好的方式是通过事件切换状态，这里先用 dialog 临时处理
                  showDialog(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: PortalbornModule.bloc,
                      child: const PortalbornInventoryPage(),
                    ),
                  );
                },
                color: const Color(0xFFffaa33),
              ),
              _QuickButton(
                icon: Icons.build,
                label: '制作',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: PortalbornModule.bloc,
                      child: const PortalbornCraftingPage(),
                    ),
                  );
                },
                color: const Color(0xFFaa55ff),
              ),
              _QuickButton(
                icon: Icons.search,
                label: '搜索',
                onTap: () {
                  final bloc = PortalbornModule.bloc;
                  if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand('search'));
                },
                color: const Color(0xFF44aaff),
              ),
              _QuickButton(
                icon: Icons.help_outline,
                label: '帮助',
                onTap: () {
                  final bloc = PortalbornModule.bloc;
                  if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand('help'));
                },
                color: const Color(0xFF8888aa),
              ),
            ],
          ),
        ),
        PortalbornCommandInput(
          onCommand: (command) {
            final bloc = PortalbornModule.bloc;
            if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand(command));
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('💡 输入命令或点击按钮探索', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
      ],
    );
  }

  String _getWelcomeMessage(String name) {
    return '👋 欢迎回来，$name！\n'
        '🌀 点击 "进入传送门" 探索领域\n'
        '📦 点击 "背包" 查看物品\n'
        '⚒️ 点击 "制作" 打造装备\n'
        '💡 输入 "help" 查看所有命令';
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _QuickButton({required this.icon, required this.label, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}