# 题屿 (shuashuati_app)

一个模块化的 Flutter 综合学习应用，包含**刷题**、**课程表**和**传送门编年史（文字 RPG）**三个独立模块。

## 功能模块

| 模块 | 说明 |
|---|---|
| 📚 刷题 | Word/JSON 题库导入、答题练习、错题本与强化、智能复习（间隔重复）、闯塔挑战、收藏、二维码/文件分享、全局搜索、通知中心 |
| 📅 课表 | xlsx/JSON 课表导入导出、周视图、课程管理、学期设置、颜色标识、文件分享 |
| 🌀 传送门编年史 | MUD 文字 RPG（开发中）：探索、战斗、装备、制作、UGC 领域编辑 |

## 技术栈

- **架构**：模块化（`ModuleRegistry` 注册制 + `AppModule` 接口，支持每模块独立主题）、BLoC 状态管理
- **存储**：hive_ce（hive 社区维护版，二进制兼容 hive 2，`build_runner` 自动生成 TypeAdapter）
- **游戏引擎**：flame / flame_bloc / flame_audio（portalborn 模块）
- **文件解析**：doc_text_extractor（Word）、archive + xml（xlsx）

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

## 生成应用图标

```bash
dart run flutter_launcher_icons
```

## 目录结构

```
lib/
├── core/           # 模块系统、主题、存储服务
├── data/           # 全局模型（用户/通知）与仓库
├── presentation/   # 首页、全局搜索、个人中心
├── modules/
│   ├── quiz/       # 刷题模块
│   ├── timetable/  # 课表模块
│   └── portalborn/ # 文字 RPG 模块
└── main.dart       # 入口（Hive 初始化 + 适配器注册 + 启动）
```
