import 'package:hive_ce/hive.dart';

import '../models/character_model.dart';
import '../models/item_model.dart';
import '../models/game_state_model.dart';
import '../models/ugc_model.dart';

/// Portalborn 数据仓库
///
/// 封装所有 Hive CRUD 操作
class GameRepository {
  static const String _boxName = 'portalborn';

  late final Box _box;

  GameRepository() {
    _box = Hive.box(_boxName);
  }

  // ═══════════════════════════════════════════════════════════════
  // 👤 角色 (Character)
  // ═══════════════════════════════════════════════════════════════

  /// 保存角色
  Future<void> saveCharacter(GameCharacter character) async {
    await _box.put('char_${character.id}', character);
  }

  /// 获取角色
  GameCharacter? getCharacter(String id) {
    return _box.get('char_$id');
  }

  /// 获取所有角色
  List<GameCharacter> getAllCharacters() {
    final keys = _box.keys.where((k) => k.toString().startsWith('char_'));
    return keys.map((k) => _box.get(k) as GameCharacter).toList();
  }

  /// 删除角色
  Future<void> deleteCharacter(String id) async {
    await _box.delete('char_$id');
  }

  /// 检查角色是否存在
  bool hasCharacter(String id) {
    return _box.containsKey('char_$id');
  }

  // ═══════════════════════════════════════════════════════════════
  // 📦 物品 (Item)
  // ═══════════════════════════════════════════════════════════════

  /// 保存物品
  Future<void> saveItem(GameItem item) async {
    await _box.put('item_${item.id}', item);
  }

  /// 获取物品
  GameItem? getItem(String id) {
    return _box.get('item_$id');
  }

  /// 获取多个物品
  List<GameItem> getItems(List<String> ids) {
    final items = <GameItem>[];
    for (final id in ids) {
      final item = getItem(id);
      if (item != null) items.add(item);
    }
    return items;
  }

  /// 删除物品
  Future<void> deleteItem(String id) async {
    await _box.delete('item_$id');
  }

  /// 获取所有物品
  List<GameItem> getAllItems() {
    final keys = _box.keys.where((k) => k.toString().startsWith('item_'));
    return keys.map((k) => _box.get(k) as GameItem).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 💾 游戏状态 (GameState)
  // ═══════════════════════════════════════════════════════════════

  /// 保存游戏状态
  Future<void> saveGameState(GameState state) async {
    await _box.put('game_state', state);
  }

  /// 获取游戏状态
  GameState? getGameState() {
    return _box.get('game_state');
  }

  /// 是否存在存档
  bool hasGameState() {
    return _box.containsKey('game_state');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎨 UGC 自定义领域
  // ═══════════════════════════════════════════════════════════════

  /// 保存 UGC 领域
  Future<void> saveUGCRealm(UGCCustomRealm realm) async {
    await _box.put('ugc_${realm.id}', realm);
  }

  /// 获取 UGC 领域
  UGCCustomRealm? getUGCRealm(String id) {
    return _box.get('ugc_$id');
  }

  /// 获取所有 UGC 领域
  List<UGCCustomRealm> getAllUGCRealms() {
    final keys = _box.keys.where((k) => k.toString().startsWith('ugc_'));
    return keys.map((k) => _box.get(k) as UGCCustomRealm).toList();
  }

  /// 删除 UGC 领域
  Future<void> deleteUGCRealm(String id) async {
    await _box.delete('ugc_$id');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗑️ 通用工具
  // ═══════════════════════════════════════════════════════════════

  /// 清空所有数据（危险操作）
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// 获取存储统计信息
  Map<String, int> getStats() {
    final characterCount = _box.keys.where((k) => k.toString().startsWith('char_')).length;
    final itemCount = _box.keys.where((k) => k.toString().startsWith('item_')).length;
    final ugcCount = _box.keys.where((k) => k.toString().startsWith('ugc_')).length;
    final hasSave = _box.containsKey('game_state');

    return {
      'characters': characterCount,
      'items': itemCount,
      'ugcRealms': ugcCount,
      'hasSave': hasSave ? 1 : 0,
      'totalKeys': _box.keys.length,
    };
  }

  /// 自动存档（在 BLoC 中调用）
  Future<void> autoSave({
    required GameCharacter character,
    required GameState state,
  }) async {
    await saveCharacter(character);
    await saveGameState(state);
  }
}