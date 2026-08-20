// lib/modules/portalborn/presentation/bloc/portalborn_event.dart
import 'package:equatable/equatable.dart';

abstract class PortalbornEvent extends Equatable {
  const PortalbornEvent();
  @override
  List<Object?> get props => [];
}

// ─── 生命周期 ──────────────────────────
class PortalbornLoad extends PortalbornEvent {}
class PortalbornCreateCharacter extends PortalbornEvent {
  final String name;
  final String classType;
  final String lineage;
  final Map<String, int> statAllocation;
  const PortalbornCreateCharacter({
    required this.name,
    required this.classType,
    required this.lineage,
    this.statAllocation = const {},
  });
  @override
  List<Object?> get props => [name, classType, lineage, statAllocation];
}

class PortalbornSelectCharacter extends PortalbornEvent {
  final String characterId;
  const PortalbornSelectCharacter(this.characterId);
  @override
  List<Object?> get props => [characterId];
}

class PortalbornSaveGame extends PortalbornEvent {}
class PortalbornQuit extends PortalbornEvent {}

// ─── 命令系统 ──────────────────────────
class PortalbornSubmitCommand extends PortalbornEvent {
  final String command;
  const PortalbornSubmitCommand(this.command);
  @override
  List<Object?> get props => [command];
}

class PortalbornClickExit extends PortalbornEvent {
  final String direction;
  const PortalbornClickExit(this.direction);
  @override
  List<Object?> get props => [direction];
}

class PortalbornQuickAction extends PortalbornEvent {
  final String action;
  const PortalbornQuickAction(this.action);
  @override
  List<Object?> get props => [action];
}

// ─── 战斗 ──────────────────────────────
class PortalbornPerformAttack extends PortalbornEvent {}
class PortalbornCastSpell extends PortalbornEvent {
  final String spellId;
  final String? target;
  const PortalbornCastSpell({required this.spellId, this.target});
  @override
  List<Object?> get props => [spellId, target];
}
class PortalbornUsePotion extends PortalbornEvent {
  final String? itemId;
  const PortalbornUsePotion([this.itemId]);
  @override
  List<Object?> get props => [itemId];
}
class PortalbornDefend extends PortalbornEvent {}
class PortalbornFlee extends PortalbornEvent {}

// ─── 交互 ──────────────────────────────
class PortalbornExamine extends PortalbornEvent {
  final String target;
  const PortalbornExamine(this.target);
  @override
  List<Object?> get props => [target];
}
class PortalbornSearch extends PortalbornEvent {
  final String? target;
  const PortalbornSearch([this.target]);
  @override
  List<Object?> get props => [target];
}
class PortalbornTakeItem extends PortalbornEvent {
  final String itemId;
  const PortalbornTakeItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}
class PortalbornDropItem extends PortalbornEvent {
  final String itemId;
  const PortalbornDropItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}
class PortalbornUseItem extends PortalbornEvent {
  final String itemId;
  const PortalbornUseItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

// ─── 背包与装备 ──────────────────────
class PortalbornToggleInventory extends PortalbornEvent {}
class PortalbornEquipItem extends PortalbornEvent {
  final String itemId;
  const PortalbornEquipItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}
class PortalbornUnequipItem extends PortalbornEvent {
  final String slot;
  const PortalbornUnequipItem(this.slot);
  @override
  List<Object?> get props => [slot];
}

// ─── 制作与工坊 ──────────────────────
class PortalbornToggleCrafting extends PortalbornEvent {}
class PortalbornCraftItem extends PortalbornEvent {
  final String recipeId;
  const PortalbornCraftItem(this.recipeId);
  @override
  List<Object?> get props => [recipeId];
}
class PortalbornToggleWorkshop extends PortalbornEvent {}

// ─── UGC ───────────────────────────────
class PortalbornImportUGC extends PortalbornEvent {
  final String jsonContent;
  const PortalbornImportUGC(this.jsonContent);
  @override
  List<Object?> get props => [jsonContent];
}
class PortalbornExportUGC extends PortalbornEvent {
  final String ugcId;
  const PortalbornExportUGC(this.ugcId);
  @override
  List<Object?> get props => [ugcId];
}
class PortalbornDeleteUGC extends PortalbornEvent {
  final String ugcId;
  const PortalbornDeleteUGC(this.ugcId);
  @override
  List<Object?> get props => [ugcId];
}

// ─── 词条 ──────────────────────────────
class PortalbornToggleLore extends PortalbornEvent {}
class PortalbornViewLore extends PortalbornEvent {
  final String loreId;
  const PortalbornViewLore(this.loreId);
  @override
  List<Object?> get props => [loreId];
}

// ─── 新增：返回大厅 ──────────────────
class PortalbornReturnToHub extends PortalbornEvent {}