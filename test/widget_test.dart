// 题屿 App 冒烟测试
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:shuashuati_app/main.dart';
import 'package:shuashuati_app/hive_registrar.g.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('shuashuati_test');
    Hive.init(dir.path);
    Hive.registerAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App 冒烟测试：首页渲染', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // 品牌区 + 模块网格应渲染
    expect(find.text('题屿'), findsOneWidget);
    expect(find.text('刷题'), findsOneWidget);
    expect(find.text('课表'), findsOneWidget);

    // 第三个模块在视口外，滚动后可见
    await tester.scrollUntilVisible(find.text('传送门编年史'), 200);
    expect(find.text('传送门编年史'), findsOneWidget);
  });
}
