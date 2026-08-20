import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Portalborn 命令解析器
class CommandParser {
  static final CommandParser _instance = CommandParser._internal();
  factory CommandParser() => _instance;
  CommandParser._internal() {
    _initializeTemplates();
  }

  final List<CommandTemplate> _templates = [];

  void _initializeTemplates() {
    _templates.addAll([
      // ═══════════════════════════════════════════════
      // 🚶 移动类命令
      // ═══════════════════════════════════════════════
      const CommandTemplate(
        patterns: ['north', 'n'],
        action: 'move',
        params: {'direction': 'north'},
        help: '向北移动',
        category: 'movement',
      ),
      const CommandTemplate(
        patterns: ['south', 's'],
        action: 'move',
        params: {'direction': 'south'},
        help: '向南移动',
        category: 'movement',
      ),
      const CommandTemplate(
        patterns: ['east', 'e'],
        action: 'move',
        params: {'direction': 'east'},
        help: '向东移动',
        category: 'movement',
      ),
      const CommandTemplate(
        patterns: ['west', 'w'],
        action: 'move',
        params: {'direction': 'west'},
        help: '向西移动',
        category: 'movement',
      ),
      const CommandTemplate(
        patterns: ['up', 'u'],
        action: 'move',
        params: {'direction': 'up'},
        help: '向上移动',
        category: 'movement',
      ),
      const CommandTemplate(
        patterns: ['down', 'd'],
        action: 'move',
        params: {'direction': 'down'},
        help: '向下移动',
        category: 'movement',
      ),
      const CommandTemplate(
        patterns: ['portal'],
        action: 'move',
        params: {'direction': 'portal'},
        help: '进入传送门返回大厅',
        category: 'movement',
      ),
      // ✅ 新增：go 命令支持带参数
      const CommandTemplate(
        patterns: ['go'],
        action: 'move',
        requiresTarget: true,
        help: '向指定方向移动: go [方向]',
        category: 'movement',
      ),

      // ═══════════════════════════════════════════════
      // ⚔️ 战斗类命令
      // ═══════════════════════════════════════════════
      const CommandTemplate(
        patterns: ['attack', 'a'],
        action: 'attack',
        requiresTarget: false,
        help: '攻击当前敌人',
        category: 'combat',
      ),
      const CommandTemplate(
        patterns: ['kill', 'k'],
        action: 'attack',
        requiresTarget: false,
        help: '同 attack',
        category: 'combat',
      ),
      const CommandTemplate(
        patterns: ['cast'],
        action: 'cast',
        requiresTarget: true,
        help: '施放法术: cast [法术名] [目标]',
        category: 'combat',
      ),
      const CommandTemplate(
        patterns: ['defend', 'def'],
        action: 'defend',
        requiresTarget: false,
        help: '防御姿态（本回合减伤50%）',
        category: 'combat',
      ),
      const CommandTemplate(
        patterns: ['flee', 'f'],
        action: 'flee',
        requiresTarget: false,
        help: '尝试逃离战斗',
        category: 'combat',
      ),

      // ═══════════════════════════════════════════════
      // 👁️ 交互类命令
      // ═══════════════════════════════════════════════
      const CommandTemplate(
        patterns: ['look', 'l'],
        action: 'look',
        requiresTarget: false,
        help: '查看当前房间描述',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['examine', 'ex', 'inspect'],
        action: 'examine',
        requiresTarget: true,
        help: '仔细检查目标: examine [目标]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['search', 'se'],
        action: 'search',
        requiresTarget: false,
        help: '搜索当前房间',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['open', 'o'],
        action: 'open',
        requiresTarget: true,
        help: '打开宝箱/门: open [目标]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['close', 'cl'],
        action: 'close',
        requiresTarget: true,
        help: '关闭门/容器: close [目标]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['take', 'get', 't'],
        action: 'take',
        requiresTarget: true,
        help: '拾取物品: take [物品名]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['drop', 'dr'],
        action: 'drop',
        requiresTarget: true,
        help: '丢弃物品: drop [物品名]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['use'],
        action: 'use',
        requiresTarget: true,
        help: '使用物品: use [物品名]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['pull'],
        action: 'pull',
        requiresTarget: true,
        help: '拉动机关: pull [目标]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['push'],
        action: 'push',
        requiresTarget: true,
        help: '推动机关: push [目标]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['pray'],
        action: 'pray',
        requiresTarget: false,
        help: '向祭坛祈祷',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['drink'],
        action: 'drink',
        requiresTarget: true,
        help: '饮用: drink [目标]',
        category: 'interaction',
      ),
      const CommandTemplate(
        patterns: ['read'],
        action: 'read',
        requiresTarget: true,
        help: '阅读: read [目标]',
        category: 'interaction',
      ),

      // ═══════════════════════════════════════════════
      // 📦 物品类命令
      // ═══════════════════════════════════════════════
      const CommandTemplate(
        patterns: ['inventory', 'i', 'inv'],
        action: 'inventory',
        requiresTarget: false,
        help: '查看背包',
        category: 'item',
      ),
      const CommandTemplate(
        patterns: ['equip', 'eq'],
        action: 'equip',
        requiresTarget: true,
        help: '装备物品: equip [物品名]',
        category: 'item',
      ),
      const CommandTemplate(
        patterns: ['wear', 'wr'],
        action: 'equip',
        requiresTarget: true,
        help: '同 equip',
        category: 'item',
      ),
      const CommandTemplate(
        patterns: ['unequip', 'ue'],
        action: 'unequip',
        requiresTarget: true,
        help: '卸下装备: unequip [武器/护甲/饰品]',
        category: 'item',
      ),
      const CommandTemplate(
        patterns: ['remove', 'rm'],
        action: 'unequip',
        requiresTarget: true,
        help: '同 unequip',
        category: 'item',
      ),

      // ═══════════════════════════════════════════════
      // 👤 角色类命令
      // ═══════════════════════════════════════════════
      const CommandTemplate(
        patterns: ['status', 'stats', 'st'],
        action: 'status',
        requiresTarget: false,
        help: '查看角色状态',
        category: 'character',
      ),
      const CommandTemplate(
        patterns: ['levelup', 'lv'],
        action: 'levelup',
        requiresTarget: false,
        help: '升级（有可用点数时）',
        category: 'character',
      ),
      const CommandTemplate(
        patterns: ['assign', 'as'],
        action: 'assign',
        requiresTarget: true,
        help: '分配属性点: assign [属性] [点数]',
        category: 'character',
      ),
      const CommandTemplate(
        patterns: ['skills', 'sk'],
        action: 'skills',
        requiresTarget: false,
        help: '查看已学技能',
        category: 'character',
      ),
      const CommandTemplate(
        patterns: ['rest', 'wait'],
        action: 'rest',
        requiresTarget: false,
        help: '休息恢复HP（非战斗中）',
        category: 'character',
      ),

      // ═══════════════════════════════════════════════
      // 🌀 通用类命令
      // ═══════════════════════════════════════════════
      const CommandTemplate(
        patterns: ['help', 'h', '?'],
        action: 'help',
        requiresTarget: false,
        help: '显示帮助',
        category: 'general',
      ),
      const CommandTemplate(
        patterns: ['save'],
        action: 'save',
        requiresTarget: false,
        help: '手动保存游戏',
        category: 'general',
      ),
      const CommandTemplate(
        patterns: ['quit', 'exit'],
        action: 'quit',
        requiresTarget: false,
        help: '退出到主菜单',
        category: 'general',
      ),
    ]);
  }

  /// 解析用户输入
  ParseResult parse(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) {
      return ParseResult.error('请输入命令。输入 "help" 查看可用命令。', raw: input);
    }

    debugPrint('🔍 解析命令: "$normalized"');

    // 1. 精确匹配
    for (final template in _templates) {
      for (final pattern in template.patterns) {
        if (pattern == normalized) {
          debugPrint('✅ 精确匹配: ${template.action} ${template.params}');
          return ParseResult.success(
            action: template.action,
            params: template.params ?? {},
            raw: input,
          );
        }
      }
    }

    // 2. 带参数匹配 (如 'attack goblin', 'go north')
    for (final template in _templates) {
      if (!template.requiresTarget && template.params != null) continue;

      for (final pattern in template.patterns) {
        if (normalized.startsWith('$pattern ')) {
          final target = normalized.substring(pattern.length + 1).trim();
          if (target.isNotEmpty) {
            final params = Map<String, dynamic>.from(template.params ?? {});

            // ✅ 特殊处理：如果是 'go' 命令，target 就是方向
            if (pattern == 'go') {
              params['direction'] = target;
              debugPrint('✅ go 命令解析: direction=$target');
            } else {
              params['target'] = target;
            }

            debugPrint('✅ 带参数匹配: ${template.action} $params');
            return ParseResult.success(
              action: template.action,
              params: params,
              raw: input,
            );
          }
        }
      }
    }

    // 3. 模糊匹配建议
    final suggestions = _getSuggestions(normalized);
    if (suggestions.isNotEmpty) {
      final suggestionList = suggestions.take(3).join(', ');
      return ParseResult.error(
        '无法理解 "$input"。💡 你是想输入: $suggestionList 吗？',
        raw: input,
      );
    }

    return ParseResult.error(
      '无法理解 "$input"。输入 "help" 查看可用命令。',
      raw: input,
    );
  }

  String getHelp({String? command}) {
    if (command != null) {
      final normalized = _normalize(command);
      for (final template in _templates) {
        if (template.patterns.any((p) => p == normalized)) {
          return '📖 ${template.patterns.first}\n'
              '   ${template.help}\n'
              '   别名: ${template.patterns.skip(1).join(', ')}\n'
              '   分类: ${_categoryDisplay(template.category)}';
        }
      }
      return '❌ 未找到命令: "$command"';
    }

    final buffer = StringBuffer();
    buffer.writeln('═' * 40);
    buffer.writeln('📖 可用命令列表');
    buffer.writeln('═' * 40);

    final categories = _templates.map((t) => t.category).toSet().toList();
    for (final category in categories) {
      final cmds = _templates.where((t) => t.category == category).toList();
      buffer.writeln('');
      buffer.writeln('【${_categoryDisplay(category)}】');
      for (final cmd in cmds) {
        final mainPattern = cmd.patterns.first;
        buffer.writeln('  $mainPattern\t- ${cmd.help}');
      }
    }

    buffer.writeln('');
    buffer.writeln('💡 提示: help [命令名] 查看详细说明');
    buffer.writeln('═' * 40);
    return buffer.toString();
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _getSuggestions(String input) {
    final suggestions = <String>[];
    for (final template in _templates) {
      for (final pattern in template.patterns) {
        if (pattern.startsWith(input) && pattern != input) {
          suggestions.add(pattern);
        }
      }
    }
    return suggestions;
  }

  String _categoryDisplay(String category) {
    const map = {
      'movement': '🚶 移动',
      'combat': '⚔️ 战斗',
      'interaction': '👁️ 交互',
      'item': '📦 物品',
      'character': '👤 角色',
      'general': '🌀 通用',
    };
    return map[category] ?? category;
  }
}

class CommandTemplate {
  final List<String> patterns;
  final String action;
  final Map<String, dynamic>? params;
  final bool requiresTarget;
  final String help;
  final String category;

  const CommandTemplate({
    required this.patterns,
    required this.action,
    this.params,
    this.requiresTarget = false,
    required this.help,
    required this.category,
  });
}

class ParseResult {
  final bool success;
  final String? action;
  final Map<String, dynamic>? params;
  final String? error;
  final String raw;

  ParseResult._({
    required this.success,
    this.action,
    this.params,
    this.error,
    required this.raw,
  });

  factory ParseResult.success({
    required String action,
    required Map<String, dynamic> params,
    required String raw,
  }) {
    return ParseResult._(
      success: true,
      action: action,
      params: params,
      raw: raw,
    );
  }

  factory ParseResult.error(String error, {required String raw}) {
    return ParseResult._(
      success: false,
      error: error,
      raw: raw,
    );
  }

  @override
  String toString() {
    if (success) {
      return '✅ $action ${params ?? {}}';
    }
    return '❌ $error';
  }
}