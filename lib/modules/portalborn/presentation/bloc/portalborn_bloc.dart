// lib/modules/portalborn/presentation/bloc/portalborn_bloc.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'portalborn_event.dart';
import 'portalborn_state.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/character_model.dart';
import '../../data/models/game_state_model.dart';
import '../../data/models/realm_model.dart';
import '../../data/models/item_model.dart';
import '../../data/models/monster_model.dart';
import '../../data/seed_data/classes.dart';
import '../../data/seed_data/items.dart';
import '../../engine/command_parser.dart';
import '../../engine/game_engine.dart';
import '../../engine/realm_generator.dart';

class PortalbornBloc extends Bloc<PortalbornEvent, PortalbornState> {
  final GameRepository _repository;
  final CommandParser _parser = CommandParser();
  final Random _random = Random();
  Timer? _autoSaveTimer;

  GameCharacter? _currentCharacter;
  GameState? _currentState;
  Realm? _currentRealm;
  List<GameItem>? _currentInventory;

  PortalbornBloc({required GameRepository repository})
      : _repository = repository,
        super(PortalbornLoading()) {
    on<PortalbornLoad>(_onLoad);
    on<PortalbornCreateCharacter>(_onCreateCharacter);
    on<PortalbornSelectCharacter>(_onSelectCharacter);
    on<PortalbornSaveGame>(_onSaveGame);
    on<PortalbornQuit>(_onQuit);

    on<PortalbornSubmitCommand>(_onSubmitCommand);
    on<PortalbornClickExit>(_onClickExit);
    on<PortalbornQuickAction>(_onQuickAction);

    on<PortalbornPerformAttack>(_onPerformAttack);
    on<PortalbornCastSpell>(_onCastSpell);
    on<PortalbornUsePotion>(_onUsePotion);
    on<PortalbornDefend>(_onDefend);
    on<PortalbornFlee>(_onFlee);

    on<PortalbornExamine>(_onExamine);
    on<PortalbornSearch>(_onSearch);
    on<PortalbornTakeItem>(_onTakeItem);
    on<PortalbornDropItem>(_onDropItem);
    on<PortalbornUseItem>(_onUseItem);

    on<PortalbornToggleInventory>(_onToggleInventory);
    on<PortalbornEquipItem>(_onEquipItem);
    on<PortalbornUnequipItem>(_onUnequipItem);

    on<PortalbornToggleCrafting>(_onToggleCrafting);
    on<PortalbornCraftItem>(_onCraftItem);

    on<PortalbornImportUGC>(_onImportUGC);
    on<PortalbornExportUGC>(_onExportUGC);
    on<PortalbornDeleteUGC>(_onDeleteUGC);

    on<PortalbornToggleLore>(_onToggleLore);
    on<PortalbornViewLore>(_onViewLore);

    on<PortalbornReturnToHub>(_onReturnToHub);
  }

  // ─── 生命周期处理器 ──────────────────────────────────────
  Future<void> _onLoad(PortalbornLoad event, Emitter<PortalbornState> emit) async {
    try {
      final hasSave = _repository.hasGameState();
      if (hasSave) {
        final state = _repository.getGameState()!;
        final character = _repository.getCharacter(state.currentCharacterId);
        if (character != null) {
          _currentCharacter = character;
          _currentState = state;
          _currentInventory = _repository.getItems(character.inventoryIds);
          emit(PortalbornHub(
            character: character,
            inventory: _currentInventory!,
            gameState: state,
          ));
          _startAutoSave();
          return;
        }
      }
      final characters = _repository.getAllCharacters();
      emit(PortalbornMainMenu(
        hasSave: hasSave && characters.isNotEmpty,
        characters: characters,
      ));
    } catch (e) {
      emit(PortalbornError('加载失败: $e'));
    }
  }

  Future<void> _onCreateCharacter(PortalbornCreateCharacter event, Emitter<PortalbornState> emit) async {
    try {
      final classData = getClassData(event.classType);
      if (classData == null) {
        emit(PortalbornError('无效的职业'));
        return;
      }
      final stats = classData.baseStats;
      final character = GameCharacter(
        name: event.name,
        mainClass: event.classType,
        lineage: event.lineage,
        strength: stats['strength'] ?? 5,
        dexterity: stats['dexterity'] ?? 5,
        intelligence: stats['intelligence'] ?? 5,
        constitution: stats['constitution'] ?? 5,
        maxHp: 20 + (stats['constitution'] ?? 5) * 2,
        currentHp: 20 + (stats['constitution'] ?? 5) * 2,
        baseAttack: 2 + (classData.bonus['atk'] ?? 0),
        baseDefense: 1,
        gold: 10,
      );
      final gameState = GameState(
        currentCharacterId: character.id,
        unlockedThemes: ['forest'],
        createdAt: DateTime.now(),
        lastSavedAt: DateTime.now(),
      );
      await _repository.saveCharacter(character);
      await _repository.saveGameState(gameState);
      _currentCharacter = character;
      _currentState = gameState;
      _currentInventory = [];
      emit(PortalbornHub(
        character: character,
        inventory: [],
        gameState: gameState,
        messages: ['🎉 欢迎，${character.name}！你的冒险开始了！'],
      ));
      _startAutoSave();
    } catch (e) {
      emit(PortalbornError('创建角色失败: $e'));
    }
  }

  Future<void> _onSelectCharacter(PortalbornSelectCharacter event, Emitter<PortalbornState> emit) async {
    try {
      final character = _repository.getCharacter(event.characterId);
      if (character == null) {
        emit(PortalbornError('角色不存在'));
        return;
      }
      final state = _repository.getGameState();
      if (state == null) {
        emit(PortalbornError('存档不存在'));
        return;
      }
      _currentCharacter = character;
      _currentState = state;
      _currentInventory = _repository.getItems(character.inventoryIds);
      emit(PortalbornHub(
        character: character,
        inventory: _currentInventory!,
        gameState: state,
      ));
      _startAutoSave();
    } catch (e) {
      emit(PortalbornError('加载角色失败: $e'));
    }
  }

  Future<void> _onSaveGame(PortalbornSaveGame event, Emitter<PortalbornState> emit) async {
    await _saveCurrentState();
    _addMessage('💾 游戏已保存');
  }

  void _onQuit(PortalbornQuit event, Emitter<PortalbornState> emit) {
    _autoSaveTimer?.cancel();
    _currentCharacter = null;
    _currentState = null;
    _currentRealm = null;
    _currentInventory = null;
    emit(PortalbornMainMenu(
      hasSave: _repository.hasGameState(),
      characters: _repository.getAllCharacters(),
    ));
  }

  // ─── 命令系统 ─────────────────────────────────────────────
  void _onSubmitCommand(PortalbornSubmitCommand event, Emitter<PortalbornState> emit) {
    final result = _parser.parse(event.command);
    if (!result.success) {
      _addMessage('❌ ${result.error}');
      return;
    }
    _handleAction(result.action!, result.params ?? {}, emit);
  }

  void _onClickExit(PortalbornClickExit event, Emitter<PortalbornState> emit) {
    _handleAction('move', {'direction': event.direction}, emit);
  }

  void _onQuickAction(PortalbornQuickAction event, Emitter<PortalbornState> emit) {
    switch (event.action) {
      case 'attack':
        add(PortalbornPerformAttack());
        break;
      case 'search':
        add(PortalbornSearch());
        break;
      case 'inventory':
        add(PortalbornToggleInventory());
        break;
      case 'help':
        _addMessage(_parser.getHelp());
        break;
      default:
        _addMessage('❌ 未知快捷操作');
    }
  }

  void _onExamine(PortalbornExamine event, Emitter<PortalbornState> emit) {
    _handleExamine(event.target, emit);
  }

  void _handleAction(String action, Map<String, dynamic> params, Emitter<PortalbornState> emit) {
    switch (action) {
      case 'move':
        final direction = params['direction'] as String?;
        if (direction == null) {
          _addMessage('❌ 请指定方向');
          return;
        }
        if (direction == 'portal' && state is PortalbornHub) {
          _enterPortal(emit);
          return;
        }
        _handleMove(direction, emit);
        break;
      case 'attack':
        add(PortalbornPerformAttack());
        break;
      case 'cast':
        add(PortalbornCastSpell(spellId: params['target'] as String));
        break;
      case 'defend':
        add(PortalbornDefend());
        break;
      case 'flee':
        add(PortalbornFlee());
        break;
      case 'look':
        _handleLook(emit);
        break;
      case 'examine':
        _handleExamine(params['target'] as String, emit);
        break;
      case 'search':
        add(PortalbornSearch(params['target'] as String?));
        break;
      case 'open':
      case 'close':
      case 'pull':
      case 'push':
      case 'pray':
      case 'drink':
      case 'read':
        _handleInteract(action, params['target'] as String?, emit);
        break;
      case 'take':
        add(PortalbornTakeItem(params['target'] as String));
        break;
      case 'drop':
        add(PortalbornDropItem(params['target'] as String));
        break;
      case 'use':
        add(PortalbornUseItem(params['target'] as String));
        break;
      case 'inventory':
        add(PortalbornToggleInventory());
        break;
      case 'equip':
        add(PortalbornEquipItem(params['target'] as String));
        break;
      case 'unequip':
        add(PortalbornUnequipItem(params['target'] as String));
        break;
      case 'status':
        _handleStatus(emit);
        break;
      case 'levelup':
        _handleLevelUp(emit);
        break;
      case 'assign':
        _handleAssignStats(params, emit);
        break;
      case 'skills':
        _handleSkills(emit);
        break;
      case 'rest':
        _handleRest(emit);
        break;
      case 'help':
        _addMessage(_parser.getHelp(command: params['target'] as String?));
        break;
      case 'save':
        add(PortalbornSaveGame());
        break;
      case 'quit':
        add(PortalbornQuit());
        break;
      default:
        _addMessage('❌ 未知操作: $action');
    }
  }

  // ─── 进入传送门 ──────────────────────────────────────────
  void _enterPortal(Emitter<PortalbornState> emit) {
    if (_currentCharacter == null || _currentState == null) {
      _addMessage('❌ 角色数据异常');
      return;
    }
    final realm = RealmGenerator.generateRealm(playerLevel: _currentCharacter!.level);
    _currentRealm = realm;
    final entryRoom = realm.entryRoom;
    entryRoom.isExplored = true;
    final hasMonster = entryRoom.hasMonster;
    emit(PortalbornExploring(
      character: _currentCharacter!,
      inventory: _currentInventory ?? [],
      gameState: _currentState!,
      currentRealm: realm,
      currentRoom: entryRoom,
      roomIndex: 0,
      totalRooms: realm.rooms.length,
      messages: ['🌀 你穿过传送门，来到了 ${realm.name}！'],
      isInBattle: hasMonster,
      currentMonster: entryRoom.monster,
    ));
    if (hasMonster) {
      _addMessage('⚔️ 你遇到了 ${entryRoom.monster!.name}！');
    }
    _autoSave();
  }

  // ─── 移动 ─────────────────────────────────────────────────
  void _handleMove(String direction, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornExploring) {
      _addMessage('❌ 当前无法移动');
      return;
    }
    if (state.isInBattle) {
      _addMessage('❌ 战斗中无法移动！使用 "flee" 逃跑或击败敌人。');
      return;
    }
    if (direction == 'portal') {
      _returnToHub(emit);
      return;
    }
    final exit = state.currentRoom.getExit(direction);
    if (exit == null) {
      _addMessage('❌ 那边没有出口。');
      return;
    }
    if (exit.isLocked) {
      _addMessage('🔒 门被锁住了。需要 ${exit.keyItemId ?? '特殊钥匙'}。');
      return;
    }
    if (exit.isHidden) {
      _addMessage('❌ 那里看起来没有路。');
      return;
    }
    final targetRoom = state.currentRealm.getRoom(exit.targetRoomId);
    if (targetRoom == null) {
      _addMessage('❌ 房间不存在，请报告此错误。');
      return;
    }
    targetRoom.isExplored = true;
    final newIndex = state.currentRealm.rooms.indexOf(targetRoom);
    final hasMonster = targetRoom.hasMonster;
    emit(PortalbornExploring(
      character: state.character,
      inventory: state.inventory,
      gameState: state.gameState,
      currentRealm: state.currentRealm,
      currentRoom: targetRoom,
      roomIndex: newIndex,
      totalRooms: state.totalRooms,
      messages: [...state.messages, '🚶 你来到了 ${targetRoom.name}'],
      isInBattle: hasMonster,
      currentMonster: targetRoom.monster,
    ));
    if (hasMonster) {
      _addMessage('⚔️ 你遇到了 ${targetRoom.monster!.name}！');
      _addMessage('💡 输入 "attack" 开始战斗，或 "flee" 逃跑。');
    }
    _autoSave();
  }

  // ─── 返回大厅 ─────────────────────────────────────────────
  void _returnToHub(Emitter<PortalbornState> emit) {
    if (_currentCharacter == null || _currentState == null) return;
    if (_currentRealm != null) {
      _currentRealm = _currentRealm!.copyWith(isCompleted: true);
      _currentState = _currentState!.copyWith(
        totalRealmsCompleted: _currentState!.totalRealmsCompleted + 1,
      );
    }
    emit(PortalbornHub(
      character: _currentCharacter!,
      inventory: _currentInventory ?? [],
      gameState: _currentState!,
      messages: const ['你安全地回到了大厅。'],
    ));
    _autoSave();
  }

  void _onReturnToHub(PortalbornReturnToHub event, Emitter<PortalbornState> emit) {
    _returnToHub(emit);
  }

  // ─── 交互辅助 ─────────────────────────────────────────────
  void _handleLook(Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornExploring) return;
    final room = state.currentRoom;
    final buffer = StringBuffer();
    buffer.writeln('📍 ${room.name}');
    buffer.writeln(room.description);
    if (room.visibleExits.isNotEmpty) {
      buffer.writeln('\n🚪 出口:');
      for (final exit in room.visibleExits) {
        buffer.writeln('  • ${exit.displayName}: ${exit.description}');
      }
    }
    if (state.interactableObjects.isNotEmpty) {
      buffer.writeln('\n📦 可互动物件:');
      for (final obj in state.interactableObjects) {
        buffer.writeln('  • ${obj.name}');
      }
    }
    if (room.hasMonster) {
      buffer.writeln('\n⚔️ 这里有 ${room.monster!.name}！');
    }
    _addMessage(buffer.toString());
  }

  void _handleExamine(String target, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornExploring) return;
    for (final obj in state.currentRoom.objects) {
      if (obj.name.contains(target)) {
        _addMessage('📖 ${obj.name}: ${obj.description}');
        return;
      }
    }
    for (final exit in state.currentRoom.exits) {
      if (exit.direction == target) {
        _addMessage('🚪 ${exit.displayName}: ${exit.description}');
        return;
      }
    }
    if (state.currentRoom.monster != null) {
      final monster = state.currentRoom.monster!;
      if (monster.name.contains(target)) {
        _addMessage('👾 ${monster.emoji} ${monster.name}: ${monster.description}');
        return;
      }
    }
    _addMessage('❌ 没有找到 "$target"');
  }

  void _handleInteract(String action, String? target, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornExploring) return;
    if (target == null) {
      _addMessage('❌ 请指定目标');
      return;
    }
    for (final obj in state.currentRoom.objects) {
      if (obj.name.contains(target) && obj.actions.contains(action)) {
        if (obj.isUsed) {
          _addMessage('⏳ 这个已经使用过了。');
          return;
        }
        if (obj.result != null) {
          _processObjectResult(obj, emit);
        } else {
          _addMessage('🔄 你 ${_actionDisplayName(action)}了 ${obj.name}。');
        }
        return;
      }
    }
    _addMessage('❌ 无法在这里执行 "$action $target"');
  }

  void _processObjectResult(InteractableObject obj, Emitter<PortalbornState> emit) {
    final result = obj.result!;
    obj.isUsed = true;
    switch (result['type']) {
      case 'item':
        final itemId = result['itemId'] as String;
        final quantity = result['quantity'] as int? ?? 1;
        _addMessage('🎁 你获得了 ${_itemName(itemId)} ×$quantity');
        break;
      case 'gold':
        final amount = result['amount'] as int;
        if (_currentCharacter != null) {
          _currentCharacter = _currentCharacter!.copyWith(
            gold: _currentCharacter!.gold + amount,
          );
          _addMessage('🪙 你获得了 $amount 金币');
        }
        break;
      case 'damage':
        final amount = result['amount'] as int;
        if (_currentCharacter != null) {
          _currentCharacter = _currentCharacter!.copyWith(
            currentHp: (_currentCharacter!.currentHp - amount).clamp(0, _currentCharacter!.maxHp),
          );
          _addMessage('💥 你受到了 $amount 点伤害！');
          _checkPlayerDeath(emit);
        }
        break;
      case 'heal':
        final amount = result['amount'] as int;
        if (_currentCharacter != null) {
          _currentCharacter = _currentCharacter!.copyWith(
            currentHp: (_currentCharacter!.currentHp + amount).clamp(0, _currentCharacter!.maxHp),
          );
          _addMessage('💚 你恢复了 $amount HP');
        }
        break;
      case 'chest':
        final gold = result['gold'] as int? ?? 5;
        if (_currentCharacter != null) {
          _currentCharacter = _currentCharacter!.copyWith(
            gold: _currentCharacter!.gold + gold,
          );
          _addMessage('🪙 你找到了 $gold 金币！');
        }
        break;
      default:
        _addMessage('🔄 你与 ${obj.name} 互动了。');
    }
    _autoSave();
  }

  String _actionDisplayName(String action) {
    const map = {
      'open': '打开',
      'close': '关闭',
      'pull': '拉动',
      'push': '推动',
      'pray': '祈祷',
      'drink': '饮用',
      'read': '阅读',
    };
    return map[action] ?? action;
  }

  String _itemName(String itemId) {
    final item = getItemTemplate(itemId);
    return item?.name ?? itemId.replaceAll('_', ' ');
  }

  // ─── 战斗处理器 ──────────────────────────────────────────
  void _onPerformAttack(PortalbornPerformAttack event, Emitter<PortalbornState> emit) {
    _executeCombatAction('attack', emit: emit);
  }

  void _onCastSpell(PortalbornCastSpell event, Emitter<PortalbornState> emit) {
    _executeCombatAction('spell', emit: emit, spellPower: 15);
  }

  void _onUsePotion(PortalbornUsePotion event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornBattle && state is! PortalbornExploring) return;
    final potion = _findPotion(event.itemId);
    if (potion == null) {
      _addMessage('❌ 没有可用的药水');
      return;
    }
    if (_currentCharacter == null) return;
    final healed = (potion.healAmount).clamp(0, _currentCharacter!.maxHp - _currentCharacter!.currentHp);
    _currentCharacter = _currentCharacter!.copyWith(
      currentHp: _currentCharacter!.currentHp + healed,
    );
    _removeItemFromInventory(potion.id);
    _addMessage('💚 使用了 ${potion.name}，恢复了 $healed HP');
    if (state is PortalbornBattle) {
      _executeMonsterCounter(emit);
    }
    _autoSave();
  }

  void _onDefend(PortalbornDefend event, Emitter<PortalbornState> emit) {
    _executeCombatAction('defend', emit: emit);
  }

  void _onFlee(PortalbornFlee event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornBattle) {
      _addMessage('❌ 当前不在战斗中');
      return;
    }
    final dex = state.character.dexterity;
    final success = GameEngine.tryFlee(dex);
    if (success) {
      _addMessage('🏃 你成功逃离了战斗！');
      emit(PortalbornExploring(
        character: state.character,
        inventory: state.inventory,
        gameState: state.gameState,
        currentRealm: state.currentRealm,
        currentRoom: state.currentRoom,
        roomIndex: state.currentRealm.rooms.indexOf(state.currentRoom),
        totalRooms: state.currentRealm.rooms.length,
        messages: [...state.battleLog, '你逃回了 ${state.currentRoom.name}'],
        isInBattle: false,
        currentMonster: null,
      ));
      _autoSave();
    } else {
      _addMessage('❌ 逃跑失败！怪物趁势攻击！');
      _executeMonsterCounter(emit);
    }
  }

  void _executeCombatAction(
      String action, {
        Emitter<PortalbornState>? emit,
        int spellPower = 0,
      }) {
    final state = this.state;
    if (state is! PortalbornBattle) {
      _addMessage('❌ 当前不在战斗中');
      return;
    }
    if (_currentCharacter == null) return;
    final result = GameEngine.executeBattleTurn(
      player: state.character,
      monster: state.monster,
      inventory: state.inventory,
      action: action,
      spellPower: spellPower > 0 ? spellPower : null,
    );
    _currentCharacter = state.character;

    if (result.isPlayerWin) {
      final expGained = result.expGained ?? 0;
      final goldGained = result.goldGained ?? 0;
      _currentCharacter = _currentCharacter!.copyWith(
        exp: _currentCharacter!.exp + expGained,
        gold: _currentCharacter!.gold + goldGained,
        totalKills: _currentCharacter!.totalKills + 1,
      );
      _addMessage(result.message);
      _addMessage('✨ 获得 $expGained EXP，$goldGained 金币');
      _checkLevelUp(emit);
      final currentRoom = state.currentRoom;
      currentRoom.monster = null;
      if (emit != null) {
        emit(PortalbornExploring(
          character: _currentCharacter!,
          inventory: state.inventory,
          gameState: state.gameState,
          currentRealm: state.currentRealm,
          currentRoom: currentRoom,
          roomIndex: state.currentRealm.rooms.indexOf(currentRoom),
          totalRooms: state.currentRealm.rooms.length,
          messages: [...state.battleLog, result.message],
          isInBattle: false,
          currentMonster: null,
        ));
      }
      _autoSave();
      return;
    }

    if (result.isMonsterWin) {
      _currentCharacter = _currentCharacter!.copyWith(currentHp: 0);
      _addMessage('💀 你被 ${state.monster.name} 击败了...');
      _handlePlayerDeath(emit);
      return;
    }

    if (result.isFled) return;

    if (emit != null) {
      emit(PortalbornBattle(
        character: _currentCharacter!,
        inventory: state.inventory,
        gameState: state.gameState,
        currentRealm: state.currentRealm,
        currentRoom: state.currentRoom,
        monster: state.monster,
        battleLog: [...state.battleLog, result.message],
        isPlayerTurn: true,
      ));
    }
  }

  void _executeMonsterCounter([Emitter<PortalbornState>? emit]) {
    final state = this.state;
    if (state is! PortalbornBattle) return;
    if (_currentCharacter == null) return;
    final result = GameEngine.executeBattleTurn(
      player: state.character,
      monster: state.monster,
      inventory: state.inventory,
      action: 'defend',
    );
    _currentCharacter = state.character;
    if (result.isMonsterWin) {
      _currentCharacter = _currentCharacter!.copyWith(currentHp: 0);
      _addMessage('💀 你被 ${state.monster.name} 击败了...');
      _handlePlayerDeath(emit);
      return;
    }
    if (emit != null) {
      emit(PortalbornBattle(
        character: _currentCharacter!,
        inventory: state.inventory,
        gameState: state.gameState,
        currentRealm: state.currentRealm,
        currentRoom: state.currentRoom,
        monster: state.monster,
        battleLog: [...state.battleLog, result.message],
        isPlayerTurn: true,
      ));
    }
  }

  // ─── 背包与装备处理器 ──────────────────────────────────
  void _onToggleInventory(PortalbornToggleInventory event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is PortalbornHub) {
      emit(state.copyWith(isInventoryOpen: !state.isInventoryOpen));
    } else {
      _addMessage('📦 背包功能只能在大厅使用。');
    }
  }

  void _onEquipItem(PortalbornEquipItem event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornHub) {
      _addMessage('❌ 只能在大厅装备物品');
      return;
    }
    final item = state.inventory.firstWhere(
          (i) => i.id == event.itemId,
      orElse: () => throw Exception('物品不存在'),
    );
    if (!item.isEquippable) {
      _addMessage('❌ 该物品无法装备');
      return;
    }
    switch (item.type) {
      case 'weapon':
        _currentCharacter = _currentCharacter!.copyWith(weaponId: item.id);
        break;
      case 'armor':
        _currentCharacter = _currentCharacter!.copyWith(armorId: item.id);
        break;
      case 'accessory':
        _currentCharacter = _currentCharacter!.copyWith(accessoryId: item.id);
        break;
    }
    final updatedInventory = state.inventory.map((i) {
      if (i.id == event.itemId) {
        return i.copyWith(isEquipped: true);
      }
      return i;
    }).toList();
    _addMessage('✅ 已装备 ${item.name}');
    _currentInventory = updatedInventory;
    emit(state.copyWith(
      character: _currentCharacter!,
      inventory: updatedInventory,
    ));
    _autoSave();
  }

  void _onUnequipItem(PortalbornUnequipItem event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornHub) {
      _addMessage('❌ 只能在大厅卸下装备');
      return;
    }
    String? oldId;
    switch (event.slot) {
      case 'weapon':
        oldId = _currentCharacter?.weaponId;
        _currentCharacter = _currentCharacter!.copyWith(weaponId: null);
        break;
      case 'armor':
        oldId = _currentCharacter?.armorId;
        _currentCharacter = _currentCharacter!.copyWith(armorId: null);
        break;
      case 'accessory':
        oldId = _currentCharacter?.accessoryId;
        _currentCharacter = _currentCharacter!.copyWith(accessoryId: null);
        break;
      default:
        _addMessage('❌ 无效的装备槽位');
        return;
    }
    if (oldId == null) {
      _addMessage('❌ 该槽位没有装备');
      return;
    }
    final updatedInventory = state.inventory.map((i) {
      if (i.id == oldId) {
        return i.copyWith(isEquipped: false);
      }
      return i;
    }).toList();
    _addMessage('✅ 已卸下装备');
    _currentInventory = updatedInventory;
    emit(state.copyWith(
      character: _currentCharacter!,
      inventory: updatedInventory,
    ));
    _autoSave();
  }

  // ─── 搜索／拾取／丢弃／使用物品 ──────────────────────
  void _onSearch(PortalbornSearch event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornExploring) return;
    double discoverChance = 0.3;
    discoverChance += state.character.intelligence * 0.005;
    if (state.character.intelligence > 7) discoverChance += 0.1;
    if (_random.nextDouble() < discoverChance) {
      _addMessage('🔍 你仔细搜索了房间...');
      _addMessage('✨ 你发现了一些隐藏的东西！');
      final rewardType = _random.nextInt(3);
      switch (rewardType) {
        case 0:
          final gold = 2 + _random.nextInt(8);
          if (_currentCharacter != null) {
            _currentCharacter = _currentCharacter!.copyWith(
              gold: _currentCharacter!.gold + gold,
            );
          }
          _addMessage('🪙 你找到了 $gold 金币！');
          break;
        case 1:
          _addMessage('🎁 你找到了一个隐藏的宝物！');
          break;
        case 2:
          _addMessage('🚪 你发现了一条秘密通道！');
          break;
      }
      _autoSave();
    } else {
      _addMessage('🔍 你仔细搜索了房间，但什么都没有发现。');
    }
  }

  void _onTakeItem(PortalbornTakeItem event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornExploring) return;
    if (_currentInventory != null && _currentInventory!.length >= 20) {
      _addMessage('❌ 背包已满！');
      return;
    }
    for (final obj in state.currentRoom.objects) {
      if (obj.id == event.itemId && obj.actions.contains('take')) {
        obj.isUsed = true;
        // 将物品添加到背包（此处简化，实际应创建物品实例）
        _addMessage('✅ 你拾取了 ${obj.name}');
        _autoSave();
        return;
      }
    }
    _addMessage('❌ 没有找到可拾取的物品');
  }

  void _onDropItem(PortalbornDropItem event, Emitter<PortalbornState> emit) {
    if (_currentInventory == null) return;
    final index = _currentInventory!.indexWhere((i) => i.id == event.itemId);
    if (index == -1) {
      _addMessage('❌ 背包中没有该物品');
      return;
    }
    final item = _currentInventory!.removeAt(index);
    _addMessage('🗑️ 你丢弃了 ${item.name}');
    if (this.state is PortalbornHub) {
      final state = this.state as PortalbornHub;
      emit(state.copyWith(inventory: _currentInventory!));
    }
    _autoSave();
  }

  void _onUseItem(PortalbornUseItem event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is! PortalbornExploring && state is! PortalbornHub) return;
    final item = _currentInventory?.firstWhere(
          (i) => i.id == event.itemId,
      orElse: () => throw Exception('物品不存在'),
    );
    if (item == null) {
      _addMessage('❌ 物品不存在');
      return;
    }
    if (item.type == 'potion') {
      final healed = (item.healAmount).clamp(0, _currentCharacter!.maxHp - _currentCharacter!.currentHp);
      _currentCharacter = _currentCharacter!.copyWith(
        currentHp: _currentCharacter!.currentHp + healed,
      );
      _removeItemFromInventory(item.id);
      _addMessage('💚 使用了 ${item.name}，恢复了 $healed HP');
      _autoSave();
    } else {
      _addMessage('❌ 该物品无法使用');
    }
  }

  // ─── 制作 ────────────────────────────────────────────────
  void _onToggleCrafting(PortalbornToggleCrafting event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is PortalbornHub) {
      emit(state.copyWith(isCraftingOpen: !state.isCraftingOpen));
    }
  }

  void _onCraftItem(PortalbornCraftItem event, Emitter<PortalbornState> emit) {
    _addMessage('⚒️ 制作功能开发中...');
  }

  // ─── 角色状态 ────────────────────────────────────────────
  void _handleStatus(Emitter<PortalbornState> emit) {
    if (_currentCharacter == null) return;
    final c = _currentCharacter!;
    _addMessage('''
📊 角色状态
  名称: ${c.name}
  等级: Lv.${c.level}
  职业: ${c.mainClass}
  继承: ${c.lineage}
  HP: ${c.currentHp}/${c.maxHp}
  攻击: ${c.baseAttack} | 防御: ${c.baseDefense}
  力量: ${c.strength} | 敏捷: ${c.dexterity}
  智力: ${c.intelligence} | 体质: ${c.constitution}
  金币: ${c.gold} | 经验: ${c.exp}/${GameEngine.expForLevel(c.level)}
  击杀: ${c.totalKills} | 死亡: ${c.totalDeaths}
''');
  }

  void _handleLevelUp(Emitter<PortalbornState> emit) {
    if (_currentCharacter == null) return;
    final result = GameEngine.checkLevelUp(_currentCharacter!);
    if (result.isSuccess) {
      _currentCharacter = GameEngine.applyLevelUp(_currentCharacter!, result);
      _addMessage(result.message);
      _autoSave();
    } else {
      _addMessage('❌ 经验不足，无法升级。需要 ${GameEngine.expForLevel(_currentCharacter!.level)} EXP');
    }
  }

  void _handleAssignStats(Map<String, dynamic> params, Emitter<PortalbornState> emit) {
    _addMessage('📊 属性分配功能开发中...');
  }

  void _handleSkills(Emitter<PortalbornState> emit) {
    if (_currentCharacter == null) return;
    final skills = getSkillsForClass(_currentCharacter!.mainClass);
    if (skills.isEmpty) {
      _addMessage('📖 当前职业没有技能');
      return;
    }
    final skillList = skills.map((s) =>
    '  • ${s.name} (Lv.${s.levelRequired}): ${s.description}'
    ).join('\n');
    _addMessage('📖 技能列表:\n$skillList');
  }

  void _handleRest(Emitter<PortalbornState> emit) {
    if (_currentCharacter == null) return;
    final state = this.state;
    if (state is PortalbornExploring && state.isInBattle) {
      _addMessage('❌ 战斗中无法休息！');
      return;
    }
    final recovery = 1 + (_currentCharacter!.constitution * 0.3).round();
    final healed = (recovery).clamp(0, _currentCharacter!.maxHp - _currentCharacter!.currentHp);
    _currentCharacter = _currentCharacter!.copyWith(
      currentHp: _currentCharacter!.currentHp + healed,
    );
    _addMessage('💤 你休息了一会儿，恢复了 $healed HP');
    _autoSave();
  }

  // ─── UGC ──────────────────────────────────────────────────
  void _onImportUGC(PortalbornImportUGC event, Emitter<PortalbornState> emit) {
    _addMessage('📥 UGC 导入功能开发中...');
  }

  void _onExportUGC(PortalbornExportUGC event, Emitter<PortalbornState> emit) {
    _addMessage('📤 UGC 导出功能开发中...');
  }

  void _onDeleteUGC(PortalbornDeleteUGC event, Emitter<PortalbornState> emit) {
    _addMessage('🗑️ UGC 删除功能开发中...');
  }

  // ─── 词条 ──────────────────────────────────────────────────
  void _onToggleLore(PortalbornToggleLore event, Emitter<PortalbornState> emit) {
    final state = this.state;
    if (state is PortalbornHub) {
      emit(state.copyWith(isLoreOpen: !state.isLoreOpen));
    }
  }

  void _onViewLore(PortalbornViewLore event, Emitter<PortalbornState> emit) {
    _addMessage('📖 查看词条: ${event.loreId}');
  }

  // ─── 辅助方法 ────────────────────────────────────────────
  void _addMessage(String msg) {
    final state = this.state;
    if (state is PortalbornHub) {
      final newMessages = [...state.messages, msg];
      if (newMessages.length > 100) {
        newMessages.removeRange(0, newMessages.length - 100);
      }
      emit(state.copyWith(messages: newMessages));
    } else if (state is PortalbornExploring) {
      final newMessages = [...state.messages, msg];
      if (newMessages.length > 100) {
        newMessages.removeRange(0, newMessages.length - 100);
      }
      emit(state.copyWith(messages: newMessages));
    } else if (state is PortalbornBattle) {
      final newLog = [...state.battleLog, msg];
      if (newLog.length > 50) {
        newLog.removeRange(0, newLog.length - 50);
      }
      emit(state.copyWith(battleLog: newLog));
    }
  }

  void _checkLevelUp([Emitter<PortalbornState>? emit]) {
    if (_currentCharacter == null) return;
    final result = GameEngine.checkLevelUp(_currentCharacter!);
    if (result.isSuccess) {
      _currentCharacter = GameEngine.applyLevelUp(_currentCharacter!, result);
      _addMessage(result.message);
    }
  }

  void _checkPlayerDeath([Emitter<PortalbornState>? emit]) {
    if (_currentCharacter == null) return;
    if (_currentCharacter!.currentHp <= 0) {
      _handlePlayerDeath(emit);
    }
  }

  void _handlePlayerDeath([Emitter<PortalbornState>? emit]) {
    if (_currentCharacter == null || _currentState == null) return;
    final deathResult = GameEngine.applyDeathPenalty(_currentCharacter!);
    _currentCharacter = GameEngine.applyDeath(_currentCharacter!, deathResult);
    _addMessage('💀 你被击败了...');
    _addMessage('📉 失去 ${deathResult.goldLost} 金币');
    _addMessage('💚 恢复 ${deathResult.hpRecovery} HP');
    if (emit != null) {
      emit(PortalbornHub(
        character: _currentCharacter!,
        inventory: _currentInventory ?? [],
        gameState: _currentState!,
        messages: const ['💀 你被击败了，回到了大厅。'],
      ));
    }
    _autoSave();
  }

  void _removeItemFromInventory(String itemId) {
    if (_currentInventory == null) return;
    final index = _currentInventory!.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final item = _currentInventory![index];
      if (item.quantity > 1) {
        _currentInventory![index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _currentInventory!.removeAt(index);
      }
    }
  }

  GameItem? _findPotion(String? itemId) {
    if (_currentInventory == null) return null;
    if (itemId != null) {
      try {
        return _currentInventory!.firstWhere(
              (i) => i.id == itemId && i.type == 'potion',
        );
      } catch (_) {
        return null;
      }
    }
    for (final item in _currentInventory!) {
      if (item.type == 'potion' && item.healAmount > 0) {
        return item;
      }
    }
    return null;
  }

  Future<void> _saveCurrentState() async {
    if (_currentCharacter != null && _currentState != null) {
      await _repository.autoSave(
        character: _currentCharacter!,
        state: _currentState!,
      );
    }
  }

  void _autoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      _saveCurrentState();
    });
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveCurrentState();
    });
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}