import 'package:flutter_test/flutter_test.dart';
import 'package:locate_my/core/ici_score.dart';

void main() {
  group('computeIciScore 公平口径', () {
    test('五项齐全、有坐标 → 各项等权均值', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': 80,
        'education': 60,
        'transit': 100,
      };
      expect(computeIciScore(s, transitApplicable: true), closeTo(88.0, 1e-9));
    });

    test('缺医疗/教育数据(源缺失) → 按 0 计入,分母不变,不再虚高到 100', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': null,
        'education': null,
        'transit': 100,
      };
      // 旧逻辑:均值只看存在的 3 项 → 100;公平口径: 80。
      expect(computeIciScore(s, transitApplicable: true), closeTo(60.0, 1e-9));
    });

    test('缺失 1 项、其余满分 → 80(旧逻辑为 100)', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': null,
        'education': 100,
        'transit': 100,
      };
      expect(computeIciScore(s, transitApplicable: true), closeTo(80.0, 1e-9));
    });

    test('transit 未评估(无坐标)→ 该项权重与分数一并剔除,不惩罚该地', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': 100,
        'education': 100,
        'transit': null,
      };
      expect(
        computeIciScore(s, transitApplicable: false),
        closeTo(100.0, 1e-9),
        reason: '四核心项均满分时不应受未选点影响',
      );
    });

    test('有坐标但附近无站点 → transit 视为 0 分计入', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': 100,
        'education': 100,
        'transit': null,
      };
      expect(
        computeIciScore(s, transitApplicable: true),
        closeTo(80.0, 1e-9),
        reason: 'transit 可评估但无数据 → 0 分,分母仍为 5 项',
      );
    });

    test('完全无数据 → null', () {
      expect(computeIciScore(const {}, transitApplicable: false), isNull);
      expect(
        computeIciScore({
          'water': null,
          'power': null,
          'healthcare': null,
          'education': null,
          'transit': null,
        }, transitApplicable: false),
        isNull,
      );
    });

    test('分数越界被收敛到 0-100', () {
      final s = {
        'water': 150,
        'power': -10,
        'healthcare': 100,
        'education': 100,
        'transit': 100,
      };
      final v = computeIciScore(s, transitApplicable: true)!;
      expect(v, inInclusiveRange(0, 100));
    });

    test('自定义权重生效', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': 100,
        'education': 100,
        'transit': 100,
      };
      final heavyHealth = computeIciScore(
        s,
        transitApplicable: true,
        wHealth: 0.6,
        wWater: 0.1,
        wPower: 0.1,
        wEdu: 0.1,
        wTransit: 0.1,
      );
      expect(heavyHealth, closeTo(100.0, 1e-9));
      // 医疗差(0分)但权重高达 0.6 时,整体被明显拉低: 0.6*0 + 0.1*100*3 + 0.1*100 = 40。
      final s2 = {
        'water': 100,
        'power': 100,
        'healthcare': 0,
        'education': 100,
        'transit': 100,
      };
      final heavyHealth2 = computeIciScore(
        s2,
        transitApplicable: true,
        wHealth: 0.6,
        wWater: 0.1,
        wPower: 0.1,
        wEdu: 0.1,
        wTransit: 0.1,
      );
      expect(heavyHealth2, closeTo(40.0, 1e-9));
    });
  });

  group('missingSourceItems', () {
    test('全部有数据 → 空清单', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': 100,
        'education': 100,
        'transit': 100,
      };
      expect(missingSourceItems(s, transitApplicable: true), isEmpty);
    });

    test('缺医疗与教育(有坐标)→ 两者被列出', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': null,
        'education': null,
        'transit': 100,
      };
      expect(
        missingSourceItems(s, transitApplicable: true),
        containsAll(['healthcare', 'education']),
      );
    });

    test('transit 未评估(无坐标)不算“缺失”', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': 100,
        'education': 100,
        'transit': null,
      };
      expect(missingSourceItems(s, transitApplicable: false), isEmpty);
    });

    test('transit 可评估但无数据 → 计入缺失', () {
      final s = {
        'water': 100,
        'power': 100,
        'healthcare': 100,
        'education': 100,
        'transit': null,
      };
      expect(
        missingSourceItems(s, transitApplicable: true),
        contains('transit'),
      );
    });
  });
}
