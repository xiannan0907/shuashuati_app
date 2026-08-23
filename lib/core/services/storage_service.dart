import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageInfo {
  final int totalSize;
  final int cacheSize;
  final int timetableSize;
  final int quizSize;
  final int otherSize;
  final int otherCleanableSize; // ✅ 新增：可清理的其他数据

  StorageInfo({
    required this.totalSize,
    required this.cacheSize,
    required this.timetableSize,
    required this.quizSize,
    required this.otherSize,
    required this.otherCleanableSize, // ✅
  });

  String get totalSizeStr => _formatSize(totalSize);
  String get cacheSizeStr => _formatSize(cacheSize);
  String get timetableSizeStr => _formatSize(timetableSize);
  String get quizSizeStr => _formatSize(quizSize);
  String get otherSizeStr => _formatSize(otherSize);
  String get otherCleanableSizeStr => _formatSize(otherCleanableSize);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class StorageService {
  // ✅ 白名单文件（不可删除）：所有在用 Hive box 的实际文件名
  static const List<String> _keepFiles = [
    'userBox.hive',              // 用户资料
    'themeSettings.hive',        // 主题设置
    'settingsBox.hive',          // 刷题设置
    'timetable_settings.hive',   // 学期设置
    'notificationBox.hive',      // 通知
    'quizSetsBox.hive',          // 题库集合索引
    'wrongQuestionsBox.hive',    // 错题记录
    'wrongStatsBox.hive',        // 错题统计
    'towerBox.hive',             // 闯塔进度
    'timetable_courses.hive',    // 课程
    'timetable_list.hive',       // 课表
    'time_table_list.hive',      // 作息时段
  ];

  /// 获取存储信息
  static Future<StorageInfo> getStorageInfo() async {
    final docDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();

    int cacheSize = await _getDirectorySize(tempDir);
    int timetableSize = 0;
    int quizSize = 0;
    int otherSize = 0;
    int otherCleanableSize = 0;

    final files = await docDir.list().toList();
    for (var entity in files) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        final size = await entity.length();
        final isHive = fileName.endsWith('.hive');

        if (isHive) {
          // Hive 文件分类
          if (fileName.contains('timetable') || fileName.contains('course')) {
            timetableSize += size;
          } else if (fileName.contains('quiz') || fileName.contains('question') ||
              fileName.contains('tower') || fileName.contains('wrong')) {
            quizSize += size;
          } else {
            // 其他 hive 文件（如 user_model, settings）
            otherSize += size;
            // 如果不在白名单中，视为可清理
            if (!_keepFiles.contains(fileName)) {
              otherCleanableSize += size;
            }
          }
        } else {
          // 非 hive 文件
          otherSize += size;
          // 判断是否为可清理的类型
          final ext = path.extension(fileName).toLowerCase();
          if (ext == '.json' || ext == '.xlsx' || ext == '.xls' ||
              ext == '.log' || ext == '.txt' || ext == '.tmp' ||
              fileName.contains('file_picker')) {
            otherCleanableSize += size;
          }
        }
      } else if (entity is Directory) {
        // 子目录大小计入 other，但可能包含可清理文件，需要递归处理
        // 为简化，我们只统计大小，不细分清理
        final dirSize = await _getDirectorySize(entity);
        otherSize += dirSize;
        // 这里不把子目录的文件计入可清理，防止误删，用户可手动清理
      }
    }

    int totalSize = cacheSize + timetableSize + quizSize + otherSize;

    return StorageInfo(
      totalSize: totalSize,
      cacheSize: cacheSize,
      timetableSize: timetableSize,
      quizSize: quizSize,
      otherSize: otherSize,
      otherCleanableSize: otherCleanableSize,
    );
  }

  /// ✅ 清理可清理的其他数据
  static Future<void> clearOtherData() async {
    final docDir = await getApplicationDocumentsDirectory();
    final files = await docDir.list().toList();
    int deletedCount = 0;

    for (var entity in files) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        final isHive = fileName.endsWith('.hive');

        // 跳过白名单文件
        if (_keepFiles.contains(fileName)) continue;

        if (isHive) {
          // 只删除不在白名单中的其他 hive 文件（非课表/刷题）
          if (!fileName.contains('timetable') && !fileName.contains('course') &&
              !fileName.contains('quiz') && !fileName.contains('question') &&
              !fileName.contains('tower') && !fileName.contains('wrong')) {
            await entity.delete();
            deletedCount++;
          }
        } else {
          // 删除非 hive 的可清理文件
          final ext = path.extension(fileName).toLowerCase();
          if (ext == '.json' || ext == '.xlsx' || ext == '.xls' ||
              ext == '.log' || ext == '.txt' || ext == '.tmp' ||
              fileName.contains('file_picker')) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      // 目录不删除，只删文件
    }

    debugPrint('✅ 清理其他数据完成，删除了 $deletedCount 个文件');
  }

  /// 清理缓存（临时目录）
  static Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    await _deleteDirectoryContents(tempDir);
  }

  /// 递归计算目录大小
  static Future<int> _getDirectorySize(Directory dir) async {
    int total = 0;
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }

  /// 递归删除目录内容（保留目录本身）
  static Future<void> _deleteDirectoryContents(Directory dir) async {
    try {
      await for (var entity in dir.list(recursive: false)) {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
        }
      }
    } catch (_) {}
  }
}