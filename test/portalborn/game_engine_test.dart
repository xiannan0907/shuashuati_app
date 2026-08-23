// 传送门编年史 RPG 引擎纯函数单元测试
// 只测确定性纯函数；随机部分（伤害波动/暴击/掉落）不做精确值断言
import 'package:flutter_test/flutter_test.dart';

import 'package:shuashuati_app/modules/portalborn/data/models/character_model.dart';
import 'package:shuashuati_app/modules/portalborn/data/models/item_model.dart';
import 'package:shuashuati_app/modules/portalborn/engine/game_engine.dart';

GameCharacter makeChar({
  int level = 1,
  int exp = 0,
  int maxHp = 20,
  int currentHp = 20,
  int baseAttack = 10,
  int baseDefense = 5,
  int strength = 5,
  int dexterity = 5,
  int intelligence = 5,
  int constitution = 5,
  int availablePoints = 0,
}) {
  return GameCharacter(
    name: '测试角色',
    mainClass: 'warrior',
    level: level,
    exp: exp,
    maxHp: maxHp,
    currentHp: currentHp,
    baseAttack: baseAttack,
    baseDefense: baseDefense,
    strength: strength,
    dexterity: dexterity,
    intelligence: intelligence,
    constitution: constitution,
    availablePoints: availablePoints,
  );
}

GameItem makeItem({int atkBonus = 0, int defBonus = 0}) {
  return GameItem(
    name: '测试装备',
    type: 'weapon',
    subType: 'sword',
    description: '测试用',
    emoji: '🗡️',
    atkBonus: atkBonus,
    defBonus: defBonus,
  );
}

void main() {
  group('GameEngine.calculateTotalAttack', () {
    test('无武器时等于基础攻击（STR=5 无加成）', () {
      expect(GameEngine.calculateTotalAttack(makeChar(), null), 10);
    });

    test('STR>5 时获得力量加成 ((STR-5)×0.5)', () {
      // STR=9 → (9-5)×0.5 = 2
      expect(GameEngine.calculateTotalAttack(makeChar(strength: 9), null), 12);
    });

    test('STR<5 时力量加成为 0（不扣减）', () {
      // STR=4 → (4-5)×0.5 = -0.5 → round=-1 → max(0,·)=0
      expect(GameEngine.calculateTotalAttack(makeChar(strength: 4), null), 10);
    });

    test('武器 atkBonus 叠加到总攻击', () {
      expect(
        GameEngine.calculateTotalAttack(makeChar(), makeItem(atkBonus: 3)),
        13,
      );
    });

    test('总攻击力最低为 1', () {
      expect(
        GameEngine.calculateTotalAttack(makeChar(baseAttack: 0, strength: 1), null),
        1,
      );
    });
  });

  group('GameEngine.calculateTotalDefense', () {
    test('无护甲时等于基础防御（CON=5 无加成）', () {
      expect(GameEngine.calculateTotalDefense(makeChar(), null), 5);
    });

    test('CON>5 时获得体质加成 ((CON-5)×0.3)', () {
      // CON=10 → 5×0.3 = 1.5 → round = 2
      expect(GameEngine.calculateTotalDefense(makeChar(constitution: 10), null), 7);
    });

    test('CON<5 时体质加成为 0（不扣减）', () {
      // CON=4 → (4-5)×0.3 = -0.3 → round = 0
      expect(GameEngine.calculateTotalDefense(makeChar(constitution: 4), null), 5);
    });

    test('护甲 defBonus 叠加到总防御', () {
      expect(
        GameEngine.calculateTotalDefense(makeChar(), makeItem(defBonus: 4)),
        9,
      );
    });

    test('总防御力最低为 0', () {
      expect(
        GameEngine.calculateTotalDefense(makeChar(baseDefense: 0, constitution: 1), null),
        0,
      );
    });
  });

  group('GameEngine.calculateMaxHp', () {
    test('CON=5, Lv.1 → 30 + (1×(3+1)).round() = 34', () {
      expect(GameEngine.calculateMaxHp(makeChar(level: 1, constitution: 5)), 34);
    });

    test('CON=10, Lv.5 → 40 + (5×5).round() = 65', () {
      expect(GameEngine.calculateMaxHp(makeChar(level: 5, constitution: 10)), 65);
    });

    test('等级越高 HP 越高', () {
      final lv1 = GameEngine.calculateMaxHp(makeChar(level: 1));
      final lv10 = GameEngine.calculateMaxHp(makeChar(level: 10));
      expect(lv10, greaterThan(lv1));
    });
  });

  group('GameEngine.expForLevel', () {
    test('公式 level×15+10', () {
      expect(GameEngine.expForLevel(1), 25);
      expect(GameEngine.expForLevel(2), 40);
      expect(GameEngine.expForLevel(10), 160);
    });

    test('升级所需经验递增', () {
      expect(GameEngine.expForLevel(2), greaterThan(GameEngine.expForLevel(1)));
      expect(GameEngine.expForLevel(10), greaterThan(GameEngine.expForLevel(9)));
    });
  });

  group('GameEngine.checkLevelUp / applyLevelUp', () {
    test('经验不足时不升级', () {
      final result = GameEngine.checkLevelUp(makeChar(level: 1, exp: 24));
      expect(result.isSuccess, isFalse);
    });

    test('经验达标时升级（Lv.1→2，默认属性）', () {
      final result = GameEngine.checkLevelUp(makeChar(level: 1, exp: 25));
      expect(result.isSuccess, isTrue);
      expect(result.newLevel, 2);
      expect(result.remainingExp, 0);
      // hpGain = 5+(5×0.5).round() = 8；atkGain = (0.5+0.5).round() = 1；defGain = (0.3+0.25).round() = 1
      expect(result.hpGain, 8);
      expect(result.atkGain, 1);
      expect(result.defGain, 1);
      expect(result.pointsGained, 3);
    });

    test('剩余经验正确结转', () {
      final result = GameEngine.checkLevelUp(makeChar(level: 1, exp: 30));
      expect(result.isSuccess, isTrue);
      expect(result.remainingExp, 5);
    });

    test('高 CON 升级获得更多 HP', () {
      final result = GameEngine.checkLevelUp(
        makeChar(level: 2, exp: 40, constitution: 10),
      );
      expect(result.isSuccess, isTrue);
      expect(result.hpGain, 10); // 5 + (10×0.5).round()
    });

    test('applyLevelUp 应用升级属性', () {
      final player = makeChar(level: 1, exp: 25);
      final result = GameEngine.checkLevelUp(player);
      final leveled = GameEngine.applyLevelUp(player, result);
      expect(leveled.level, 2);
      expect(leveled.exp, 0);
      expect(leveled.maxHp, 28);
      expect(leveled.currentHp, 28);
      expect(leveled.baseAttack, 11);
      expect(leveled.baseDefense, 6);
      expect(leveled.availablePoints, 3);
    });

    test('applyLevelUp 对未升级结果返回原角色', () {
      final player = makeChar(level: 1, exp: 10);
      final result = GameEngine.checkLevelUp(player);
      final unchanged = GameEngine.applyLevelUp(player, result);
      expect(identical(player, unchanged), isTrue);
    });
  });
}
