import 'package:flutter/material.dart';

import '../../core/module/app_module.dart';
import '../../core/module/module_registry.dart';
import '../../data/repositories/notification_repository.dart'; // ✅ 新增
import 'global_search_page.dart';
import 'profile_page.dart';
import 'notification_page.dart';

/// 应用首页 - 模块入口 + 我的
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0; // 0: 主页, 1: 我的

  // ✅ 改为真实数据
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  // ✅ 新增：加载未读数
  Future<void> _loadUnreadCount() async {
    final count = await notificationRepo.getUnreadCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.modules;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeContent(context, modules, theme, isDark),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildNavItem(
                context,
                icon: Icons.apps,
                label: '主页',
                isSelected: _currentTab == 0,
                onTap: () => setState(() => _currentTab = 0),
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                label: '我的',
                isSelected: _currentTab == 1,
                onTap: () => setState(() => _currentTab = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
              top: BorderSide(
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                width: 2.5,
              ),
            )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600)
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600)
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(
      BuildContext context,
      List<AppModule> modules,
      ThemeData theme,
      bool isDark,
      ) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ========== 品牌区 ==========
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4),
              child: Column(
                children: [
                  Text(
                    '题屿',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1565C0),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.shade300 : const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========== 搜索栏 + 通知 ==========
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  // 搜索栏
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GlobalSearchPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '全局搜索...',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ 通知图标 + 红点（使用真实未读数）
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                      // 返回时刷新未读数
                      _loadUnreadCount();
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========== 模块网格 ==========
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index < modules.length) {
                    return _buildModuleCard(context, modules[index], theme, isDark);
                  } else {
                    return _buildPlaceholderCard(context, theme, isDark);
                  }
                },
                childCount: modules.length + 1, // 模块数 + 1 个"更多模块"占位卡
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
      BuildContext context,
      AppModule module,
      ThemeData theme,
      bool isDark,
      ) {
    final moduleColors = {
      'quiz': {
        'gradient': [Colors.blue.shade50, Colors.blue.shade100],
        'iconBg': Colors.blue.shade100,
        'iconColor': Colors.blue.shade700,
        'statusColor': Colors.blue.shade600,
      },
      'timetable': {
        'gradient': [Colors.teal.shade50, Colors.teal.shade100],
        'iconBg': Colors.teal.shade100,
        'iconColor': Colors.teal.shade700,
        'statusColor': Colors.teal.shade600,
      },
      'ledger': {
        'gradient': [Colors.green.shade50, Colors.green.shade100],
        'iconBg': Colors.green.shade100,
        'iconColor': Colors.green.shade700,
        'statusColor': Colors.green.shade600,
      },
    };

    final colors = moduleColors[module.id] ?? {
      'gradient': [Colors.purple.shade50, Colors.purple.shade100],
      'iconBg': Colors.purple.shade100,
      'iconColor': Colors.purple.shade700,
      'statusColor': Colors.purple.shade600,
    };

    final statusText = module.enabled ? '使用中' : '已禁用';

    return GestureDetector(
      onTap: () {
        // ✅ 走 buildModulePage，让模块独立主题在入口处生效
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => module.buildModulePage(context),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey.shade800, Colors.grey.shade700]
                : colors['gradient'] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.shade200.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade600.withValues(alpha: 0.3)
                          : colors['iconBg'] as Color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      module.icon,
                      color: isDark ? Colors.white : colors['iconColor'] as Color,
                      size: 26,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade600.withValues(alpha: 0.4)
                          : (colors['statusColor'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey.shade400
                            : colors['statusColor'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '点击进入 →',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    size: 26,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '即将上线',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '更多模块',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '敬请期待',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}