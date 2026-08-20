import 'package:flutter/material.dart'; // ✅ 新增
import 'package:hive_ce/hive.dart';

part 'notification_item.g.dart';

@HiveType(typeId: 99)
class NotificationItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String type; // 'reminder' | 'review' | 'achievement' | 'system' | 'update'

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  bool isRead;

  @HiveField(6)
  final String? actionRoute;

  @HiveField(7)
  final String? actionParams;

  @HiveField(8)
  final String icon;

  @HiveField(9)
  final String? sourceId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.actionParams,
    required this.icon,
    this.sourceId,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }

  String get typeLabel {
    switch (type) {
      case 'reminder':
        return '⏰ 提醒';
      case 'review':
        return '📚 复习';
      case 'achievement':
        return '🏆 成就';
      case 'system':
        return '📢 系统';
      case 'update':
        return '🔄 更新';
      default:
        return '📌 通知';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'reminder':
        return Colors.orange;
      case 'review':
        return Colors.red;
      case 'achievement':
        return Colors.amber;
      case 'system':
        return Colors.blue;
      case 'update':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      content: content,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute,
      actionParams: actionParams,
      icon: icon,
      sourceId: sourceId,
    );
  }
}