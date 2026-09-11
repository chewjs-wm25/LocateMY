import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/main.dart';

void main() {
  testWidgets('shows the LocateMY Chinese prototype home page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    expect(find.text('LocateMY'), findsOneWidget);
    expect(find.text('您想搬到哪里？'), findsOneWidget);
    expect(find.text('探索马来西亚'), findsOneWidget);
  });

  testWidgets('explores a place and opens its cost analysis', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('探索马来西亚'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分析此地点'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生活成本'));
    await tester.pumpAndSettle();

    expect(find.text('生活成本比较'), findsOneWidget);
    expect(find.text('乔治市（槟城）'), findsOneWidget);
  });

  testWidgets('compares two places from the map', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('地图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('两地对比'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('比较生活成本'));
    await tester.pumpAndSettle();

    expect(find.text('原地址'), findsOneWidget);
    expect(find.text('新地址'), findsOneWidget);
  });

  testWidgets('adds an inspection record and opens its detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('账户'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('房产实勘档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增实勘'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存实勘'));
    await tester.pumpAndSettle();

    expect(find.text('海风公寓（新实勘）'), findsWidgets);
    expect(find.text('风险摘要'), findsOneWidget);
  });
}
