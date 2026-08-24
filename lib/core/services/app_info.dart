import 'package:package_info_plus/package_info_plus.dart';

/// 应用版本信息：启动时加载一次，供各"关于/版本"区域展示真实版本号。
class AppInfo {
  AppInfo._();

  /// 当前版本号（如 1.0.3），加载失败时兜底 '1.0.0'
  static String version = '1.0.0';

  /// 构建号（如 4），仅内部参考
  static String buildNumber = '0';

  /// 在 main() 启动流程中调用一次
  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {
      // 保持兜底值
    }
  }
}
