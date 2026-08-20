// lib/modules/portalborn/presentation/pages/portalborn_explore.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/portalborn_bloc.dart';
import '../bloc/portalborn_event.dart';
import '../bloc/portalborn_state.dart';
import '../widgets/portalborn_status_bar.dart';
import '../widgets/portalborn_terminal.dart';
import '../widgets/portalborn_command_input.dart';
import '../widgets/portalborn_quick_buttons.dart';
import '../widgets/portalborn_exit_buttons.dart';
import '../widgets/portalborn_object_list.dart';
import '../widgets/portalborn_room_card.dart';

class PortalbornExplorePage extends StatelessWidget {
  final PortalbornExploring state;

  // ✅ 添加 required this.state
  const PortalbornExplorePage({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      body: SafeArea(
        child: _ExploreContent(state: state),
      ),
    );
  }
}

class _ExploreContent extends StatelessWidget {
  final PortalbornExploring state;

  const _ExploreContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final room = state.currentRoom;
    final progress = state.progress;
    final bloc = context.read<PortalbornBloc>();

    return Column(
      children: [
        PortalbornStatusBar(
          character: state.character,
          showStats: true,
        ),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '🌲 ${state.currentRealm.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                  '⭐ ${(progress * 100).toInt()}% 探索度',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8888aa),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141425),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🏠 ${state.roomIndex + 1}/${state.totalRooms}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8888aa),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (!bloc.isClosed) {
                    bloc.add(PortalbornReturnToHub());
                  }
                },
                icon: const Icon(Icons.home, color: Color(0xFF8888aa)),
                tooltip: '返回大厅',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF2a2a4a)),

        Expanded(
          flex: 3,
          child: PortalbornRoomCard(
            room: room,
            isInBattle: state.isInBattle,
            monster: state.currentMonster,
          ),
        ),

        if (state.interactableObjects.isNotEmpty) ...[
          const Divider(height: 1, color: Color(0xFF2a2a4a)),
          PortalbornObjectList(
            objects: state.interactableObjects,
            onObjectTap: (objectId, action) {
              if (!bloc.isClosed) {
                final objName = _getObjectName(objectId);
                bloc.add(PortalbornSubmitCommand('$action $objName'));
              }
            },
          ),
        ],

        if (state.visibleExits.isNotEmpty) ...[
          const Divider(height: 1, color: Color(0xFF2a2a4a)),
          PortalbornExitButtons(
            exits: state.visibleExits,
            onExitTap: (direction) {
              if (!bloc.isClosed) {
                bloc.add(PortalbornClickExit(direction));
              }
            },
          ),
        ],

        const Divider(height: 1, color: Color(0xFF2a2a4a)),
        Expanded(
          flex: 2,
          child: PortalbornTerminal(
            messages: state.messages,
            placeholder: '探索中...',
            maxLines: 20,
          ),
        ),

        PortalbornQuickButtons(
          onAttack: () {
            if (state.isInBattle) {
              if (!bloc.isClosed) bloc.add(PortalbornPerformAttack());
            } else {
              if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand('attack'));
            }
          },
          onSearch: () {
            if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand('search'));
          },
          onInventory: () {
            if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand('inventory'));
          },
          onHelp: () {
            if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand('help'));
          },
        ),

        PortalbornCommandInput(
          onCommand: (command) {
            if (!bloc.isClosed) bloc.add(PortalbornSubmitCommand(command));
          },
        ),
      ],
    );
  }

  String _getObjectName(String objectId) {
    for (final obj in state.interactableObjects) {
      if (obj.id == objectId) {
        return obj.name;
      }
    }
    return objectId;
  }
}