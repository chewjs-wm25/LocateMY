import 'package:flutter/material.dart';
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

  testWidgets('opens a single-place cost report without a comparison', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('探索马来西亚'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看完整分析'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生活成本'));
    await tester.pumpAndSettle();

    expect(find.text('单点生活成本报告'), findsOneWidget);
    expect(find.text('乔治市（槟城）'), findsOneWidget);
    expect(find.text('统一生活篮子估算月支出'), findsOneWidget);
    expect(find.text('地点 A'), findsNothing);
  });

  testWidgets('expands the location card into the five defined summaries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('探索马来西亚'));
    await tester.pumpAndSettle();

    expect(find.text('个人化地点适配度 78/100'), findsOneWidget);
    expect(find.text('地点摘要'), findsNothing);

    await tester.tap(find.byTooltip('展开地点摘要'));
    await tester.pumpAndSettle();

    expect(find.text('地点摘要'), findsOneWidget);
    expect(find.text('安全'), findsOneWidget);
    expect(find.text('生活成本'), findsOneWidget);
    expect(find.text('日常便利'), findsOneWidget);
    expect(find.text('公共交通可达性'), findsOneWidget);
    expect(find.text('基础设施'), findsOneWidget);
    expect(find.text('固定半径 2 公里 · 示例地点资料 · 2026年9月1日'), findsOneWidget);
  });

  testWidgets(
    'shows an honest pending state when a required score input is missing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(const LocateMyApp());

      await tester.tap(find.text('探索马来西亚'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选 吉隆坡'));
      await tester.pumpAndSettle();

      expect(find.text('个人化地点适配度 78/100'), findsNothing);
      expect(find.textContaining('尚不能计算个人化地点适配度'), findsOneWidget);
      expect(find.textContaining('安全指数（高优先级）的可用资料'), findsOneWidget);
    },
  );

  testWidgets(
    'asks for the current place comparison role before entering comparison',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(const LocateMyApp());

      await tester.tap(find.text('地图'));
      await tester.pumpAndSettle();
      final comparisonButton = find.widgetWithText(TextButton, '发起两地比较');
      await tester.drag(find.byType(ListView), const Offset(0, -320));
      await tester.pumpAndSettle();
      await tester.ensureVisible(comparisonButton);
      await tester.tap(comparisonButton);
      await tester.pumpAndSettle();

      expect(find.text('选择当前地点的比较角色'), findsOneWidget);
      await tester.tap(find.text('作为地点 A'));
      await tester.pumpAndSettle();

      expect(find.text('两地对比'), findsOneWidget);
      expect(find.textContaining('请先选择地点 B'), findsOneWidget);
    },
  );

  testWidgets('opens the six-category A/B comparison overview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('地图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('两地对比'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看地点比较'));
    await tester.pumpAndSettle();

    expect(find.text('地点比较总览'), findsOneWidget);
    expect(find.text('地点 A'), findsWidgets);
    expect(find.text('地点 B'), findsWidgets);
    for (final category in ['生活成本', '治安与犯罪', '社会经济', '基础设施', '周边设施', '公共交通']) {
      await tester.scrollUntilVisible(find.text(category), 120);
      expect(find.text(category), findsOneWidget);
    }

    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生活成本'));
    await tester.pumpAndSettle();
    expect(find.text('生活成本比较'), findsOneWidget);
    expect(find.text('口径可比 · 差异 RM 380/月'), findsOneWidget);
  });

  testWidgets('does not allow the same place in A and B to be compared', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('地图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('两地对比'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Place>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('吉隆坡 · 吉隆坡联邦直辖区').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('地点 A 与地点 B不能相同'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '查看地点比较'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '查看地点比较'))
          .onPressed,
      isNull,
    );
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
