import 'package:uuid/uuid.dart';

/// Portalborn 模块 ID 生成器
///
/// 统一使用 UUID v4 生成所有实体的唯一标识
class PortalbornIdGenerator {
  static const Uuid _uuid = Uuid();

  /// 生成一个新的唯一 ID
  static String generate() => _uuid.v4();

  /// 生成一个短 ID（取前 8 位，用于显示）
  static String short() => _uuid.v4().substring(0, 8);

  /// 生成一个带前缀的 ID，便于调试
  /// 例如: idWithPrefix('room') → 'room_123e4567-e89b-12d3-a456-426614174000'
  static String idWithPrefix(String prefix) => '${prefix}_${_uuid.v4()}';
}