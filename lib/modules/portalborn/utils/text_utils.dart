/// Portalborn 模块文本工具
class PortalbornTextUtils {
  /// 标准化用户输入（小写 + 去多余空格 + 去标点）
  static String normalizeInput(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // 移除标点
        .replaceAll(RegExp(r'\s+'), ' ') // 合并多个空格
        .trim();
  }

  /// 检查字符串是否为空或仅包含空白
  static bool isBlank(String? input) {
    return input == null || input.trim().isEmpty;
  }

  /// 截断字符串到指定长度，末尾加 '...'
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 将字符串按行分割，保留空行
  static List<String> splitLines(String text) {
    return text.split('\n');
  }

  /// 将列表渲染为带编号的文本
  static String numberedList(List<String> items, {String prefix = '  '}) {
    return items
        .asMap()
        .entries
        .map((e) => '$prefix${e.key + 1}. ${e.value}')
        .join('\n');
  }

  /// 将列表渲染为带项目符号的文本
  static String bulletList(List<String> items, {String bullet = '• '}) {
    return items.map((item) => '$bullet$item').join('\n');
  }
}