import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/bloc/theme_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../pages/notification_page.dart';
import '../pages/storage_management_page.dart';

final userRepo = UserRepository();

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  bool _isLoading = true;

  final List<String> _presetAvatars = [
    '😀', '😎', '🤩', '😊', '🤗',
    '😺', '🐶', '🦊', '🐼', '🐨',
    '🐱', '🐰', '🦝', '🐻', '🐲',
    '🦄', '🐧', '🐦', '🐳', '🦋',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await userRepo.getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  // ============================================================
  // 头像选择
  // ============================================================

  void _showAvatarDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📷 更换头像',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetAvatars.map((emoji) {
                  final isSelected = _user?.avatarKey == emoji;
                  return GestureDetector(
                    onTap: () async {
                      await userRepo.updateAvatar(emoji);
                      await _loadUser();
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue.shade400
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionChip(
                  icon: Icons.photo_camera,
                  label: '拍照',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📷 拍照功能 - 开发中'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionChip(
                  icon: Icons.photo_library,
                  label: '相册',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🖼️ 相册功能 - 开发中'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionChip(
                  icon: Icons.close,
                  label: '取消',
                  onTap: () => Navigator.pop(ctx),
                  isCancel: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isCancel = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCancel
              ? Colors.grey.shade200
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCancel
                ? Colors.grey.shade300
                : Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isCancel ? Colors.grey.shade600 : Colors.blue.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isCancel ? Colors.grey.shade600 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 昵称编辑
  // ============================================================

  void _showNicknameDialog() {
    final controller = TextEditingController(text: _user?.nickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✏️ 修改昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '请输入你的昵称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _saveNickname(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => _saveNickname(ctx, controller.text),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNickname(BuildContext ctx, String text) async {
    if (text.trim().isEmpty) return;
    await userRepo.updateNickname(text.trim());
    await _loadUser();
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
  }

  // ============================================================
  // 签名编辑
  // ============================================================

  void _showSignatureDialog() {
    final controller = TextEditingController(text: _user?.signature ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📝 修改签名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: '请输入你的座右铭',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _saveSignature(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => _saveSignature(ctx, controller.text),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSignature(BuildContext ctx, String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('签名不能为空'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    await userRepo.updateSignature(text.trim());
    await _loadUser();
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
  }

  // ============================================================
  // 主题模式弹窗（浅色/深色/跟随系统）
  // ============================================================

  void _showThemeDialog() {
    final themeCubit = context.read<ThemeCubit>();
    final currentMode = themeCubit.state.globalMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '🌓 主题模式',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              label: '☀️ 浅色模式',
              isSelected: currentMode == AppThemeMode.light,
              onTap: () {
                themeCubit.setGlobalTheme(AppThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 4),
            _buildThemeOption(
              context,
              label: '🌙 深色模式',
              isSelected: currentMode == AppThemeMode.dark,
              onTap: () {
                themeCubit.setGlobalTheme(AppThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 4),
            _buildThemeOption(
              context,
              label: '⚙️ 跟随系统',
              isSelected: currentMode == AppThemeMode.system,
              onTap: () {
                themeCubit.setGlobalTheme(AppThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, {
        required String label,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.shade50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.blue.shade400 : Colors.blue.shade300)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ========== 头部（用户信息） ==========
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    // 头像（点击可更换）
                    GestureDetector(
                      onTap: _showAvatarDialog,
                      child: Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isDark ? Colors.blue.shade700 : Colors.blue.shade500,
                                  isDark ? Colors.blue.shade500 : Colors.blue.shade300,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _user?.avatarKey ?? '😊',
                                style: const TextStyle(fontSize: 34),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.grey.shade900 : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 昵称（点击可修改）
                          GestureDetector(
                            onTap: _showNicknameDialog,
                            child: Row(
                              children: [
                                Text(
                                  _user?.nickname ?? '学习者',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 签名（点击可修改）
                          GestureDetector(
                            onTap: _showSignatureDialog,
                            child: Row(
                              children: [
                                Text(
                                  '「${_user?.signature ?? '学无止境'}」',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),

            // ========== 功能列表（统计卡片已删除） ==========
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ----- 分组：个性化 -----
                  _buildSectionHeader('🎨 个性化', isDark),

                  // ✅ 主题模式（浅色/深色/跟随系统）
                  _buildListTile(
                    context,
                    icon: Icons.palette_outlined,
                    title: '主题模式',
                    subtitle: '浅色 / 深色 / 跟随系统',
                    isDark: isDark,
                    trailing: BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        final mode = state.globalMode;
                        String label = '跟随系统';
                        if (mode == AppThemeMode.light) label = '浅色';
                        if (mode == AppThemeMode.dark) label = '深色';
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ],
                        );
                      },
                    ),
                    onTap: _showThemeDialog,
                  ),

                  const Divider(height: 20, indent: 16, endIndent: 16),

                  // ----- 分组：设置 -----
                  _buildSectionHeader('⚙️ 设置', isDark),

                  _buildListTile(
                    context,
                    icon: Icons.notifications_active_outlined,
                    title: '通知设置',
                    subtitle: '学习提醒 / 错题提醒 / 成就通知',
                    isDark: isDark,
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationPage()),
                      );
                    },
                  ),

                  _buildListTile(
                    context,
                    icon: Icons.storage_outlined,
                    title: '存储管理',
                    subtitle: '查看存储空间使用情况',
                    isDark: isDark,
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StorageManagementPage(),
                        ),
                      );
                    },
                  ),

                  _buildListTile(
                    context,
                    icon: Icons.backup_outlined,
                    title: '数据备份与恢复',
                    subtitle: '导出 / 导入所有数据',
                    isDark: isDark,
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('💾 数据备份与恢复 - 开发中'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 20, indent: 16, endIndent: 16),

                  // ----- 分组：其他 -----
                  _buildSectionHeader('🎯 其他', isDark),

                  _buildListTile(
                    context,
                    icon: Icons.feedback_outlined,
                    title: '意见反馈',
                    subtitle: '反馈问题 / 建议',
                    isDark: isDark,
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('💬 意见反馈 - 开发中'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  _buildListTile(
                    context,
                    icon: Icons.star_outline,
                    title: '给个好评',
                    subtitle: '在应用商店评分',
                    isDark: isDark,
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⭐ 感谢支持！'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                  _buildListTile(
                    context,
                    icon: Icons.info_outline,
                    title: '关于',
                    subtitle: '版本 v1.0.0',
                    isDark: isDark,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('关于刷刷题'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '📱 刷刷题',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '版本 1.0.0',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '用心学习，不断成长 💪',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '📚 刷题 | 📝 笔记 | 🏋️ 健身',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '© 2025 刷刷题团队',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                '关闭',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 辅助组件
  // ============================================================

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required bool isDark,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
        ),
      ),
      trailing: trailing ?? const SizedBox.shrink(),
      onTap: onTap,
    );
  }
}