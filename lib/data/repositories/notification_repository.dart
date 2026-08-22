import 'package:hive_ce/hive.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  static const String boxName = 'notificationBox';

  // ============================================================
  // 获取 Box
  // ============================================================

  Future<Box<NotificationItem>> _getBox() async {
    return await Hive.openBox<NotificationItem>(boxName);
  }

  // ============================================================
  // ✅ 初始化通知（首次启动示例 + 版本更新公告）
  // ============================================================

  Future<void> initSampleNotifications() async {
    final box = await _getBox();
    final now = DateTime.now();

    // ── 版本更新公告：无论是否首次启动都确保存在（升级用户可见，未读红点）──
    final announcements = [
      NotificationItem(
        id: 'announce_v1_0_1',
        title: '🔄 v1.0.1 版本更新',
        content: '【重大改进】\n'
            '· 修复：启动卡死问题、错题/存档数据误删风险\n'
            '· 新增：全局搜索可直接进入题库\n'
            '· 优化：错题复习算法、课表解析、主题切换\n'
            '· 其他：依赖全面升级、性能与细节打磨',
        type: 'update',
        timestamp: now,
        isRead: false,
        actionRoute: null,
        icon: 'new_releases',
      ),
    ];
    for (var item in announcements) {
      if (!box.containsKey(item.id)) {
        await box.put(item.id, item);
      }
    }

    // ── 首次启动示例（仅空 box 时插入）──
    if (box.isNotEmpty) return;

    final samples = [
      NotificationItem(
        id: 'sample_1',
        title: '📚 欢迎使用题屿！',
        content: '开始你的学习之旅吧，每天进步一点点 💪',
        type: 'system',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        actionRoute: null,
        icon: 'notifications',
      ),
      NotificationItem(
        id: 'sample_2',
        title: '💡 试试导入题库',
        content: '点击右上角「导入」按钮，导入Word或JSON格式的题库',
        type: 'system',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isRead: false,
        actionRoute: null,
        icon: 'lightbulb',
      ),
      NotificationItem(
        id: 'sample_3',
        title: '⚔️ 挑战冒险之塔',
        content: '在刷题中闯关，击败Boss获得称号！',
        type: 'system',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        actionRoute: null,
        icon: 'emoji_events',
      ),
    ];

    for (var item in samples) {
      await box.put(item.id, item);
    }
  }

  // ============================================================
  // 查询
  // ============================================================

  Future<List<NotificationItem>> getAll() async {
    final box = await _getBox();
    final list = box.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<int> getUnreadCount() async {
    final box = await _getBox();
    return box.values.where((item) => !item.isRead).length;
  }

  Future<int> getTodayCount() async {
    final box = await _getBox();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return box.values
        .where((item) => item.timestamp.isAfter(todayStart))
        .length;
  }

  // ============================================================
  // 创建通知
  // ============================================================

  Future<void> create({
    required String title,
    required String content,
    required String type,
    String? actionRoute,
    String? actionParams,
    String icon = 'notifications',
    String? sourceId,
  }) async {
    if (sourceId != null) {
      final box = await _getBox();
      final exists = box.values.any((item) =>
      item.sourceId == sourceId &&
          item.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 1))));
      if (exists) return;
    }

    final item = NotificationItem(
      id: 'notify_${DateTime.now().millisecondsSinceEpoch}_${type}_${sourceId ?? 'system'}',
      title: title,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      actionRoute: actionRoute,
      actionParams: actionParams,
      icon: icon,
      sourceId: sourceId,
    );

    final box = await _getBox();
    await box.put(item.id, item);

    final allItems = box.values.toList();
    if (allItems.length > 100) {
      allItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (int i = 0; i < allItems.length - 100; i++) {
        await box.delete(allItems[i].id);
      }
    }
  }

  // ============================================================
  // 操作
  // ============================================================

  Future<void> markAsRead(String id) async {
    final box = await _getBox();
    final item = box.get(id);
    if (item != null) {
      item.isRead = true;
      await box.put(id, item);
    }
  }

  Future<void> markAllAsRead() async {
    final box = await _getBox();
    final items = box.values.toList();
    for (var item in items) {
      item.isRead = true;
      await box.put(item.id, item);
    }
  }

  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }

  // ============================================================
  // 统计
  // ============================================================

  Future<Map<String, int>> getStats() async {
    final box = await _getBox();
    final all = box.values.toList();
    return {
      'total': all.length,
      'unread': all.where((item) => !item.isRead).length,
      'today': all.where((item) =>
          item.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 1))))
          .length,
    };
  }
}

final notificationRepo = NotificationRepository();