import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/bloc/portalborn_bloc.dart';
import '../../presentation/bloc/portalborn_event.dart';
import '../../presentation/bloc/portalborn_state.dart';
import '../widgets/portalborn_status_bar.dart';
import '../widgets/portalborn_command_input.dart';
import '../widgets/portalborn_battle_monster.dart';
import '../widgets/portalborn_battle_log.dart';
import '../widgets/portalborn_battle_buttons.dart';

/// Portalborn 战斗页面
class PortalbornBattlePage extends StatelessWidget {
  final PortalbornBattle state;
  const PortalbornBattlePage({
    super.key,
    required this.state,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      body: SafeArea(
        child: BlocBuilder<PortalbornBloc, PortalbornState>(
          builder: (context, state) {
            if (state is PortalbornBattle) {
              return _BattleContent(state: state);
            }

            if (state is PortalbornExploring) {
              // 战斗结束，返回探索
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
              return const Center(
                child: Text(
                  '返回探索...',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            if (state is PortalbornHub) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              });
              return const Center(
                child: Text(
                  '返回大厅...',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return const Center(
              child: Text(
                '加载中...',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 战斗内容
class _BattleContent extends StatelessWidget {
  final PortalbornBattle state;

  const _BattleContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final character = state.character;
    final monster = state.monster;

    return Column(
      children: [
        // 状态栏
        PortalbornStatusBar(
          character: character,
          showStats: true,
        ),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),

        // 战斗标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.sports_martial_arts,
                size: 20,
                color: Color(0xFFff3355),
              ),
              const SizedBox(width: 8),
              const Text(
                '⚔️ 战斗！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFff3355),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141425),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⚡ ${state.monster.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFffaa33),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),

        // 怪物卡片
        Expanded(
          flex: 2,
          child: PortalbornBattleMonster(
            monster: monster,
            isPlayerTurn: state.isPlayerTurn,
          ),
        ),

        // 战斗日志
        const Divider(height: 1, color: Color(0xFF2a2a4a)),
        Expanded(
          flex: 2,
          child: PortalbornBattleLog(
            logs: state.battleLog,
          ),
        ),

        // 战斗快捷按钮
        PortalbornBattleButtons(
          onAttack: () {
            context.read<PortalbornBloc>().add(
              PortalbornPerformAttack(),
            );
          },
          onCastSpell: () {
            _showSpellDialog(context);
          },
          onUsePotion: () {
            context.read<PortalbornBloc>().add(
              PortalbornUsePotion(),
            );
          },
          onDefend: () {
            context.read<PortalbornBloc>().add(
              PortalbornDefend(),
            );
          },
          onFlee: () {
            context.read<PortalbornBloc>().add(
             PortalbornFlee(),
            );
          },
          isPlayerTurn: state.isPlayerTurn,
        ),

        // 命令输入框
        PortalbornCommandInput(
          onCommand: (command) {
            context.read<PortalbornBloc>().add(
              PortalbornSubmitCommand(command),
            );
          },
        ),
      ],
    );
  }

  void _showSpellDialog(BuildContext context) {
    // TODO: 实现法术选择弹窗
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✨ 选择法术'),
        content: const Text('法术系统开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}