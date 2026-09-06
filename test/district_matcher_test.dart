import 'package:flutter_test/flutter_test.dart';
import 'package:locate_my/core/district_matcher.dart';

void main() {
  group('DistrictMatcher.matches 跨源县名匹配', () {
    test('完全一致', () {
      expect(DistrictMatcher.matches('Petaling', 'Petaling'), isTrue);
      expect(DistrictMatcher.matches('Klang', 'Klang'), isTrue);
    });

    test('括号后缀(医院口径)', () {
      expect(DistrictMatcher.matches('Petaling', 'Petaling (Subang Jaya)'), isTrue);
      expect(DistrictMatcher.matches('Timur Laut', 'Timur Laut (Georgetown)'), isTrue);
      expect(DistrictMatcher.matches('Gombak', 'Gombak (Rawang)'), isTrue);
      expect(DistrictMatcher.matches('Larut & Matang', 'Larut & Matang (Taiping)'), isTrue);
    });

    test('拆县(旧县名 → 新拆分县行)', () {
      expect(DistrictMatcher.matches('Petaling', 'Petaling Perdana'), isTrue);
      expect(DistrictMatcher.matches('Petaling', 'Petaling Utama'), isTrue);
      expect(DistrictMatcher.matches('Kinta', 'Kinta Selatan'), isTrue);
    });

    test('并县条目:行名前缀或组成县命中', () {
      expect(DistrictMatcher.matches('Tatau', 'Tatau/Sebauh'), isTrue);
      expect(DistrictMatcher.matches('Sebauh', 'Tatau/Sebauh'), isTrue);
      expect(DistrictMatcher.matches('Kulim', 'Kulim/Bandar Baharu'), isTrue);
      expect(DistrictMatcher.matches('Bandar Baharu', 'Kulim/Bandar Baharu'), isTrue);
    });

    test('缩写别名 S.P.* → Seberang Perai *', () {
      expect(DistrictMatcher.matches('S.P. Selatan', 'Seberang Perai Selatan'), isTrue);
      expect(DistrictMatcher.matches('S.P.Tengah', 'Seberang Perai Tengah'), isTrue);
      expect(DistrictMatcher.matches('S.P.Utara', 'Seberang Perai Utara'), isTrue);
    });

    test('Ulu/Hulu 用字差异', () {
      expect(DistrictMatcher.matches('Ulu Langat', 'Hulu Langat'), isTrue);
      expect(DistrictMatcher.matches('Ulu Selangor', 'Hulu Selangor'), isTrue);
      expect(DistrictMatcher.matches('Hulu Langat', 'Hulu Langat (Bangi)'), isTrue);
    });

    test('联邦直辖区 W.P. 前缀差异', () {
      expect(DistrictMatcher.matches('Kuala Lumpur', 'W.P. Kuala Lumpur'), isTrue);
      expect(DistrictMatcher.matches('W.P. Kuala Lumpur', 'Kuala Lumpur'), isTrue);
      expect(DistrictMatcher.matches('Putrajaya', 'W.P. Putrajaya'), isTrue);
      expect(DistrictMatcher.matches('Labuan', 'W.P. Labuan'), isTrue);
    });

    test('连接词 dan/and 差异', () {
      expect(DistrictMatcher.matches('Larut dan Matang', 'Larut & Matang (Taiping)'), isTrue);
      expect(DistrictMatcher.matches('Larut & Matang', 'Larut dan Matang'), isTrue);
    });

    test('Kulaijaya / Kulai', () {
      expect(DistrictMatcher.matches('Kulai', 'Kulaijaya'), isTrue);
      expect(DistrictMatcher.matches('Kulaijaya', 'Kulai'), isTrue);
    });

    test('不相关县名不误匹配', () {
      expect(DistrictMatcher.matches('Klang', 'Kuching'), isFalse);
      expect(DistrictMatcher.matches('Perak', 'Kuala Lumpur'), isFalse);
      expect(DistrictMatcher.matches('Pulau Pinang', 'Timur Laut'), isFalse);
      expect(DistrictMatcher.matches('Siburan', 'Petaling'), isFalse);
    });

    test('行名是查询名前缀 ≠ 子县聚合(Sibu 不是 Siburan)', () {
      expect(DistrictMatcher.matches('Siburan', 'Sibu'), isFalse);
      expect(DistrictMatcher.matches('Siburan', 'Sibu (Sibu)'), isFalse);
      expect(DistrictMatcher.matches('Kalabakan', 'Kalabakan'), isTrue);
    });

    test('大小写与多余空白不敏感', () {
      expect(DistrictMatcher.matches('  petaling  ', 'PETALING (SUBANG JAYA)'), isTrue);
    });
  });
}
