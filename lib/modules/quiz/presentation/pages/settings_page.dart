import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../data/repositories/question_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoNext = false;
  bool _vibration = true;
  bool _sound = false;
  int _fontSizeIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox<String>('settingsBox');
      _autoNext = box.get('auto_next') == 'true';
      _vibration = box.get('vibration') != 'false';
      _sound = box.get('sound') == 'true';
      _fontSizeIndex = int.tryParse(box.get('font_size') ?? '1') ?? 1;
      setState(() {});
    } catch (e) { /* 忽略设置加载失败 */ }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      final box = await Hive.openBox<String>('settingsBox');
      await box.put(key, value);
    } catch (e) { /* 忽略设置保存失败 */ }
  }

  void _toggleAutoNext(bool value) {
    setState(() => _autoNext = value);
    _saveSetting('auto_next', value.toString());
  }

  void _toggleVibration(bool value) {
    setState(() => _vibration = value);
    _saveSetting('vibration', value.toString());
  }

  void _toggleSound(bool value) {
    setState(() => _sound = value);
    _saveSetting('sound', value.toString());
  }

  void _changeFontSize(int index) {
    setState(() => _fontSizeIndex = index);
    _saveSetting('font_size', index.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('⚙️ 刷题设置'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ============================================================
            // ⚙️ 刷题功能设置
            // ============================================================
            _buildSectionHeader('⚙️ 刷题功能', isDark),
            _buildInfoText(
              '仅影响刷题模块的行为，与全局主题无关',
              isDark,
            ),
            const SizedBox(height: 8),

            _buildSettingCard(
              icon: Icons.flash_on,
              iconColor: Colors.orange,
              title: '自动下一题',
              subtitle: '答完自动跳转下一题',
              rightWidget: Switch(
                value: _autoNext,
                onChanged: _toggleAutoNext,
                activeThumbColor: Colors.blue,
              ),
            ),
            _buildSettingCard(
              icon: Icons.vibration,
              iconColor: Colors.deepPurple,
              title: '震动反馈',
              subtitle: '答题时震动反馈',
              rightWidget: Switch(
                value: _vibration,
                onChanged: _toggleVibration,
                activeThumbColor: Colors.blue,
              ),
            ),
            _buildSettingCard(
              icon: Icons.volume_up,
              iconColor: Colors.teal,
              title: '声音反馈',
              subtitle: '答题时播放音效',
              rightWidget: Switch(
                value: _sound,
                onChanged: _toggleSound,
                activeThumbColor: Colors.blue,
              ),
            ),

            // 字体大小
            _buildSettingCard(
              icon: Icons.text_fields,
              iconColor: Colors.green,
              title: '字体大小',
              subtitle: '调整题目文字大小',
              rightWidget: _buildFontSizeSelector(),
            ),

            const SizedBox(height: 16),

            // ============================================================
            // 💾 数据管理
            // ============================================================
            _buildSectionHeader('💾 数据管理', isDark),
            _buildSettingCard(
              icon: Icons.delete_forever,
              iconColor: Colors.red,
              title: '清空所有数据',
              subtitle: '删除所有学习记录和题库',
              rightWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '⚠️ 危险',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () => _showClearAllConfirm(context),
            ),

            const SizedBox(height: 16),

            // ============================================================
            // ℹ️ 关于
            // ============================================================
            _buildSectionHeader('ℹ️ 关于', isDark),
            _buildSettingCard(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: '版本',
              subtitle: '当前应用版本',
              rightWidget: Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? rightWidget,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
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
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        trailing: rightWidget,
        onTap: onTap,
      ),
    );
  }

  Widget _buildFontSizeSelector() {
    final List<String> labels = ['小', '中', '大'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: labels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = _fontSizeIndex == index;

        return GestureDetector(
          onTap: () => _changeFontSize(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.blue.shade800 : Colors.blue.shade50)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
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
                fontSize: isSelected ? 14 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // 清空确认弹窗
  // ============================================================

  void _showClearAllConfirm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '⚠️ 危险操作',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        content: Text(
          '确定要清空所有数据吗？\n\n'
              '此操作将永久删除：\n'
              '• 所有题库和题目\n'
              '• 所有学习进度\n'
              '• 错题记录和收藏\n\n'
              '此操作不可撤销！',
          style: TextStyle(
            height: 1.6,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final repo = QuestionRepository();
      final setNames = await repo.getAllSetNames();

      for (var name in setNames) {
        await repo.clearAll(setName: name);
        await repo.deleteSet(name);
      }

      await repo.clearAllWrongQuestions();
      await repo.clearAllWrongStats();

      final settingsBox = await Hive.openBox<String>('settingsBox');
      await settingsBox.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已清空所有数据'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清空失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}