# 题屿 (shuashuati_app)

一个模块化的 Flutter 本地优先学习应用，包含**刷题**、**课程表**和**记账**三个独立模块。全部数据存在本地 Hive，不依赖任何后端服务。

## 功能模块

| 模块 | 说明 |
|---|---|
| 📚 刷题 | Word/JSON 题库导入、答题练习、错题本与强化、智能复习（SM-2 间隔重复）、闯塔挑战、收藏、二维码/文件分享、全局搜索、通知中心 |
| 📅 课表 | xlsx/JSON 课表导入导出、周视图（拖放换课）、课程管理、学期设置、颜色标识、文件分享 |
| 💰 记账 | 收支流水（支持转账、报销标记）、多账本、账户与余额、分类管理、月度预算、收支统计（饼图 + 趋势折线）、月度流水 CSV 导出 |

> 传送门编年史（文字 RPG）模块已随 v1.0.3 整体下线，相关代码与依赖均已移除。

## 技术栈

- **架构**：模块化（`ModuleRegistry` 注册制 + `AppModule` 接口，支持每模块独立主题）、BLoC 状态管理
- **存储**：hive_ce（hive 社区维护版，二进制兼容 hive 2，`build_runner` 自动生成 TypeAdapter）
- **文件解析**：doc_text_extractor（Word）、archive + xml（xlsx）
- **图表**：fl_chart（记账收支统计）
- **分享**：share_plus（系统分享面板）、qr_flutter（二维码）

## 环境要求

- Flutter 3.44+（Dart 3.12+）
- Android compileSdk/targetSdk 36

## 开发

```bash
flutter pub get
# 修改 Hive 模型后重新生成适配器
dart run build_runner build
flutter analyze
flutter test
flutter run
```

## 生成应用图标 / 启动图

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## 目录结构

```
lib/
├── core/           # 模块系统（AppModule/ModuleRegistry）、主题、存储/备份/错误日志/版本信息服务
├── data/           # 全局模型（用户/通知）与仓库
├── presentation/   # 首页、全局搜索、个人中心、通知、存储管理、错误日志
├── modules/
│   ├── quiz/       # 刷题模块（题库/答题/错题/复习/闯塔/分享）
│   ├── timetable/  # 课表模块（xlsx 解析 + 周视图 + 导入导出）
│   └── ledger/     # 记账模块（流水/账户/分类/预算/统计）
└── main.dart       # 入口（Hive 初始化 + 适配器注册 + 启动）
```

## 项目文档

- [`docs/项目功能解析.md`](docs/项目功能解析.md)：逐模块的代码级功能解析与已知问题清单
- [`CHANGELOG.md`](CHANGELOG.md)：版本变更记录
