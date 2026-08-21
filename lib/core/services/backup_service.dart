import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

/// 用户数据备份/恢复服务
///
/// 采用「文件级备份」：直接打包 Hive 数据文件为 zip（100% 保真，
/// 无需逐模型 JSON 序列化）。导出走系统分享（可存网盘/发给自己），
/// 恢复时覆盖本地数据文件并要求重启应用。
class BackupService {
  /// 固定备份的数据文件（与 main.dart / 各 Repository 一致）
  static const List<String> _fixedBoxes = [
    'quizSetsBox',
    'wrongQuestionsBox',
    'wrongStatsBox',
    'towerBox',
    'notificationBox',
    'timetable_courses',
    'timetable_list',
    'time_table_list',
    'portalborn',
    'userBox',
    'themeSettings',
    'settingsBox',
    'timetable_settings',
  ];

  /// 收集需要备份的 .hive 文件（含按题库名动态创建的题库 box）
  static Future<List<File>> collectHiveFiles() async {
    final docDir = await getApplicationDocumentsDirectory();
    final names = <String>[..._fixedBoxes];

    // 动态题库 box：从 quizSetsBox 的 sets 索引解析题库名
    try {
      if (Hive.isBoxOpen('quizSetsBox')) {
        final sets = Hive.box('quizSetsBox').get('sets') as String?;
        if (sets != null && sets.isNotEmpty) {
          for (final name in sets.split(',')) {
            final trimmed = name.trim();
            if (trimmed.isNotEmpty) {
              names.add('questionsBox_${Uri.encodeComponent(trimmed)}');
            }
          }
        }
      }
    } catch (_) {}

    final files = <File>[];
    for (final name in names) {
      final f = File('${docDir.path}/$name.hive');
      if (await f.exists()) {
        files.add(f);
      }
    }
    return files;
  }

  /// 导出全部数据为 zip，返回 [文件路径, 大小字节]；失败抛异常
  static Future<(String, int)> exportBackup() async {
    // 1. 将所有已打开 box 的写入缓冲刷盘，确保备份完整
    try {
      final names = [..._fixedBoxes];
      if (Hive.isBoxOpen('quizSetsBox')) {
        final sets = Hive.box('quizSetsBox').get('sets') as String?;
        if (sets != null && sets.isNotEmpty) {
          for (final n in sets.split(',')) {
            final trimmed = n.trim();
            if (trimmed.isNotEmpty) names.add('questionsBox_${Uri.encodeComponent(trimmed)}');
          }
        }
      }
      for (final name in names) {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).flush();
        }
      }
    } catch (_) {}

    // 2. 收集数据文件
    final files = await collectHiveFiles();
    if (files.isEmpty) {
      throw Exception('没有找到可备份的数据文件');
    }

    // 3. 打包 zip
    final archive = Archive();
    for (final f in files) {
      final bytes = await f.readAsBytes();
      archive.addFile(ArchiveFile(f.uri.pathSegments.last, bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive);

    // 4. 写入临时目录
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final tempDir = await getTemporaryDirectory();
    final outPath = '${tempDir.path}/shuashuati_backup_$dateStr.zip';
    await File(outPath).writeAsBytes(zipBytes);

    return (outPath, zipBytes.length);
  }

  /// 从 zip 恢复数据（覆盖本地数据文件）。成功后调用方必须提示用户重启应用。
  static Future<int> restoreBackup(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. 关闭所有已打开 box（避免内存态回写覆盖恢复的数据）
    await Hive.close();

    // 2. 解压覆盖 .hive 文件到应用文档目录
    final docDir = await getApplicationDocumentsDirectory();
    var restored = 0;
    for (final file in archive) {
      if (!file.isFile || !file.name.endsWith('.hive')) continue;
      final outFile = File('${docDir.path}/${file.name}');
      await outFile.writeAsBytes(file.content as List<int>);
      restored++;
    }

    if (restored == 0) {
      throw Exception('备份文件中没有有效的数据文件');
    }

    debugPrint('✅ 数据恢复完成，共恢复 $restored 个数据文件');
    return restored;
  }
}
