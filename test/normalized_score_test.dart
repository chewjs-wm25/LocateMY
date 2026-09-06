import 'package:flutter_test/flutter_test.dart';
import 'package:locate_my/core/normalized_score.dart';

void main() {
  group('minMaxNormalized', () {
    test('池为空 → null', () {
      expect(minMaxNormalized(5, []), isNull);
    });

    test('基础 min-max', () {
      expect(minMaxNormalized(20, [10, 20, 30]), closeTo(50, 1e-9));
      expect(minMaxNormalized(10, [10, 20, 30]), closeTo(0, 1e-9));
      expect(minMaxNormalized(30, [10, 20, 30]), closeTo(100, 1e-9));
    });

    test('池中极差为 0 → 100（全国各县相同，目标即最优）', () {
      expect(minMaxNormalized(7, [7, 7, 7]), closeTo(100, 1e-9));
      expect(minMaxNormalized(5, [5]), closeTo(100, 1e-9));
    });

    test('越界值收敛到 0-100', () {
      expect(minMaxNormalized(-5, [10, 20, 30]), closeTo(0, 1e-9));
      expect(minMaxNormalized(999, [10, 20, 30]), closeTo(100, 1e-9));
    });

    test('小数与乱序池', () {
      expect(minMaxNormalized(2.1, [0.4, 1.2, 3.0, 2.1]), closeTo(65.3846, 0.01));
    });
  });
}
