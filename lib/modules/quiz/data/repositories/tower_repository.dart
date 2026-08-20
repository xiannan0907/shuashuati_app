import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/tower_model.dart';

class TowerRepository {
  static const String boxName = 'towerBox';

  Future<TowerProgress> getProgress() async {
    try {
      final box = await Hive.openBox<TowerProgress>(boxName);
      final data = box.get('progress');
      if (data != null) {
        return data;
      }
      final defaultProgress = TowerProgress();
      await box.put('progress', defaultProgress);
      return defaultProgress;
    } catch (e) {
      debugPrint('❌ 获取爬塔进度失败: $e');
      return TowerProgress();
    }
  }

  Future<void> saveProgress(TowerProgress progress) async {
    try {
      final box = await Hive.openBox<TowerProgress>(boxName);
      await box.put('progress', progress);
      debugPrint('✅ 爬塔进度已保存: 第${progress.currentFloor}层, 节点${progress.currentNodeIndex}/${progress.floorNodeCount}');
    } catch (e) {
      debugPrint('❌ 保存爬塔进度失败: $e');
    }
  }

  Future<void> resetProgress() async {
    try {
      final box = await Hive.openBox<TowerProgress>(boxName);
      await box.delete('progress');
      debugPrint('✅ 爬塔进度已重置');
    } catch (e) {
      debugPrint('❌ 重置爬塔进度失败: $e');
    }
  }
}