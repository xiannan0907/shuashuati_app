import 'package:flutter/material.dart';

import '../../data/models/notification_item.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> _notifications = [];
  String _filter = '全部';
  bool _isLoading = true;

  final List<String> _filterOptions = ['全部', '提醒', '复习', '成就', '系统'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final items = await notificationRepo.getAll();
    setState(() {
      _notifications = items;
      _isLoading = false;
    });
  }

  List<NotificationItem> get _filteredNotifications {
    if (_filter == '全部') return _notifications;
    final typeMap = {
      '提醒': 'reminder',
      '复习': 'review',
      '成就': 'achievement',
      '系统': 'system',
    };
    final targetType = typeMap[_filter];
    if (targetType == null) return _notifications;
    return _notifications.where((item) => item.type == targetType).toList();
  }

  int get _unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  Future<void> _markAllAsRead() async {
    await notificationRepo.markAllAsRead();
    await _loadNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已全部标记为已读'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _markAsRead(String id) async {
    await notificationRepo.markAsRead(id);
    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空通知'),
        content: const Text('确定要清空所有通知吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doClearAll();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  Future<void> _doClearAll() async {
    await notificationRepo.clearAll();
    await _loadNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已清空所有通知'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.grey.shade700,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              '通知',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            if (_unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                '全部已读',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
            onPressed: _notifications.isEmpty ? null : _clearAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 筛选标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((label) {
                  final isSelected = _filter == label;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = label),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.blue.shade800 : Colors.blue.shade50)
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.blue.shade400 : Colors.blue.shade300)
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 通知列表
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _buildNotificationItem(context, item, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _filter == '全部' ? '暂无通知' : '暂无${_filter}通知',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '新的通知会在这里显示',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context,
      NotificationItem item,
      bool isDark,
      ) {
    return GestureDetector(
      onTap: () {
        if (!item.isRead) {
          _markAsRead(item.id);
        }
        if (item.actionRoute != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('跳转到: ${item.actionRoute}'),
              duration: const Duration(seconds: 1),
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? (isDark ? Colors.grey.shade800 : Colors.white)
              : (isDark ? Colors.blue.shade900.withOpacity(0.15) : Colors.blue.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRead
                ? (isDark ? Colors.grey.shade700 : Colors.grey.shade100)
                : (isDark ? Colors.blue.shade700.withOpacity(0.3) : Colors.blue.shade200),
            width: item.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.typeColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(item.icon),
                color: item.typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: item.typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${item.timeAgo}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                      const Spacer(),
                      if (!item.isRead)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 辅助：将字符串图标名转为 IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'error_outline':
        return Icons.error_outline;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'note_add':
        return Icons.note_add;
      case 'alarm':
        return Icons.alarm;
      case 'star':
        return Icons.star;
      case 'new_releases':
        return Icons.new_releases;
      default:
        return Icons.notifications;
    }
  }
}