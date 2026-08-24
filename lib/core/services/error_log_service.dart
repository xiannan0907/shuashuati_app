import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 错误日志服务：落盘到应用文档目录，滚动保留，供设置页查看/导出/清除。
///
/// 设计原则：日志写入自身失败时静默吞掉——绝不因记录日志而影响主流程。
class ErrorLogService {
  ErrorLogService._();

  /// 滚动上限（字符数）：约 150KB，超出后丢弃最早的一半
  static const int _maxChars = 150 * 1024;

  static const String _fileName = 'error_log.txt';
  static const String _separator = '──────────────────────────────────────────────';

  static File? _cached;

  static Future<File> _file() async {
    final cached = _cached;
    if (cached != null) return cached;
    final dir = await getApplicationDocumentsDirectory();
    _cached = File('${dir.path}/$_fileName');
    return _cached!;
  }

  /// 记录一条错误。 anywhere 调用都安全（内部全量吞异常）。
  static Future<void> log(Object error,
      [StackTrace? stack, String? context]) async {
    try {
      final f = await _file();
      final ts = DateTime.now().toIso8601String();
      final buf = StringBuffer()
        ..writeln('[$ts]${context == null ? '' : ' ($context)'}')
        ..writeln(error.toString());
      if (stack != null && stack.toString().trim().isNotEmpty) {
        buf.writeln(stack.toString());
      }
      buf.writeln(_separator);

      var content =
          await f.exists() ? await f.readAsString() : '';
      content = '$content${buf.toString()}';

      // 滚动保留：超出上限时只留后半段
      if (content.length > _maxChars) {
        content = content.substring(content.length ~/ 2);
        // 对齐到下一条目开头
        final idx = content.indexOf('[');
        if (idx > 0) content = content.substring(idx);
      }
      await f.writeAsString(content);
    } catch (_) {
      // 静默：日志系统自身的故障不外泄
    }
  }

  /// 读取全部日志（文件不存在返回空串）
  static Future<String> readAll() async {
    try {
      final f = await _file();
      return await f.exists() ? await f.readAsString() : '';
    } catch (_) {
      return '';
    }
  }

  /// 日志文件路径（导出分享用）
  static Future<String?> path() async {
    try {
      final f = await _file();
      return await f.exists() ? f.path : null;
    } catch (_) {
      return null;
    }
  }

  /// 清空日志
  static Future<void> clear() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.writeAsString('');
    } catch (_) {}
  }
}
