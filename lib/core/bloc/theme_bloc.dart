import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// ============================================================
// 主题模式枚举
// ============================================================
enum AppThemeMode {
  light,
  dark,
  system,
}

// ============================================================
// 主题状态
// ============================================================
class ThemeState {
  final AppThemeMode globalMode;
  final Map<String, AppThemeMode> moduleModes;
  final bool useGlobalTheme;

  ThemeState({
    this.globalMode = AppThemeMode.system,
    this.moduleModes = const {},
    this.useGlobalTheme = true,
  });

  AppThemeMode getEffectiveMode(String moduleId) {
    if (useGlobalTheme) return globalMode;
    return moduleModes[moduleId] ?? globalMode;
  }

  ThemeState copyWith({
    AppThemeMode? globalMode,
    Map<String, AppThemeMode>? moduleModes,
    bool? useGlobalTheme,
  }) {
    return ThemeState(
      globalMode: globalMode ?? this.globalMode,
      moduleModes: moduleModes ?? this.moduleModes,
      useGlobalTheme: useGlobalTheme ?? this.useGlobalTheme,
    );
  }

  ThemeState setModuleTheme(String moduleId, AppThemeMode mode) {
    final newModes = Map<String, AppThemeMode>.from(moduleModes);
    newModes[moduleId] = mode;
    return ThemeState(
      globalMode: globalMode,
      moduleModes: newModes,
      useGlobalTheme: useGlobalTheme,
    );
  }
}

// ============================================================
// 主题 Cubit
// ============================================================
class ThemeCubit extends Cubit<ThemeState> {
  static const String _settingsBoxName = 'themeSettings';
  static const String _keyGlobalMode = 'global_mode';
  static const String _keyUseGlobal = 'use_global';
  static const String _keyModulePrefix = 'module_theme_';

  ThemeCubit() : super(ThemeState()) {
    _loadingFuture = _loadSettings();
  }

  Future<void>? _loadingFuture;

  /// 等待初始设置加载完成，避免未加载完就被覆盖
  Future<void> _ensureLoaded() async {
    await _loadingFuture;
  }

  // ============================================================
  // 加载保存的设置
  // ============================================================
  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox<String>(_settingsBoxName);

      final globalModeStr = box.get(_keyGlobalMode);
      final globalMode = _parseMode(globalModeStr) ?? AppThemeMode.system;

      final useGlobal = box.get(_keyUseGlobal) != 'false';

      final moduleModes = <String, AppThemeMode>{};
      for (var key in box.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith(_keyModulePrefix)) {
          final moduleId = keyStr.substring(_keyModulePrefix.length);
          final modeStr = box.get(keyStr);
          final mode = _parseMode(modeStr);
          if (mode != null) {
            moduleModes[moduleId] = mode;
          }
        }
      }

      emit(ThemeState(
        globalMode: globalMode,
        moduleModes: moduleModes,
        useGlobalTheme: useGlobal,
      ));
    } catch (e) { /* 忽略加载失败 */ }
  }

  // ============================================================
  // 保存设置
  // ============================================================
  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox<String>(_settingsBoxName);
      await box.put(_keyGlobalMode, _modeToString(state.globalMode));
      await box.put(_keyUseGlobal, state.useGlobalTheme.toString());

      final keysToRemove = box.keys
          .where((k) => k.toString().startsWith(_keyModulePrefix))
          .toList();
      for (var key in keysToRemove) {
        await box.delete(key);
      }

      for (var entry in state.moduleModes.entries) {
        final key = '$_keyModulePrefix${entry.key}';
        await box.put(key, _modeToString(entry.value));
      }
    } catch (e) {
      debugPrint('保存主题设置失败: $e');
    }
  }

  // ============================================================
  // 公共方法
  // ============================================================

  Future<void> setGlobalTheme(AppThemeMode mode) async {
    await _ensureLoaded();
    emit(state.copyWith(globalMode: mode));
    await _saveSettings();
  }

  Future<void> toggleThemeMode(bool useGlobal) async {
    await _ensureLoaded();
    emit(state.copyWith(useGlobalTheme: useGlobal));
    await _saveSettings();
  }

  Future<void> setModuleTheme(String moduleId, AppThemeMode mode) async {
    await _ensureLoaded();
    emit(state.setModuleTheme(moduleId, mode));
    await _saveSettings();
  }

  Future<void> resetModuleTheme(String moduleId) async {
    await _ensureLoaded();
    final newModes = Map<String, AppThemeMode>.from(state.moduleModes);
    newModes.remove(moduleId);
    emit(ThemeState(
      globalMode: state.globalMode,
      moduleModes: newModes,
      useGlobalTheme: state.useGlobalTheme,
    ));
    await _saveSettings();
  }

  AppThemeMode getEffectiveTheme(String moduleId) {
    return state.getEffectiveMode(moduleId);
  }

  // ============================================================
  // 工具方法
  // ============================================================
  static String _modeToString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  static AppThemeMode? _parseMode(String? str) {
    if (str == null) return null;
    switch (str) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      default:
        return null;
    }
  }
}