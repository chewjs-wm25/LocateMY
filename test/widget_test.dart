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
    await tester.scrollUntilVisible(
      find.text('RM 6,338 / 月'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('家庭收入中位数'), findsOneWidget);
    expect(find.text('RM 6,338 / 月'), findsOneWidget);
    expect(find.text('2024 年调查'), findsOneWidget);
    expect(find.text('按当年价格，未按通胀调整'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('成本压力相对较低'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('成本压力相对较低'), findsOneWidget);
    expect(find.text('OPR 参考值'), findsNothing);
    expect(find.text('3.00%'), findsNothing);
  });

  testWidgets('keeps the macro index hierarchy readable on a small screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(const LocateMyApp());

    expect(find.textContaining('搬家时机'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('成本压力'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('成本压力'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('就业稳定度'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('就业稳定度'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('经济动能'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('经济动能'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('家庭收入中位数'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('家庭收入中位数'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('周边设施'), findsOneWidget);
    expect(find.text('2 公里内覆盖 5/6 类 · 未覆盖：安全与服务'), findsOneWidget);
    expect(find.textContaining('最近诊所'), findsNothing);
    expect(find.text('公共交通可达性'), findsOneWidget);
    expect(find.text('基础设施'), findsOneWidget);
    expect(find.text('固定半径 2 公里 · 示例地点资料 · 2026年9月1日'), findsOneWidget);
  });

  testWidgets('shows complete nearby facilities coverage for Kuala Lumpur', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('探索马来西亚'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选 吉隆坡'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('展开地点摘要'));
    await tester.pumpAndSettle();

    expect(find.text('2 公里内覆盖全部 6 类'), findsOneWidget);
    expect(find.textContaining('最近诊所'), findsNothing);
  });

  testWidgets('keeps six categories and nearest facilities on the full page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('探索马来西亚'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看完整分析'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('周边设施'));
    await tester.pumpAndSettle();

    expect(find.textContaining('已收录 26 处 · 5/6 类'), findsOneWidget);
    expect(find.text('安全与服务'), findsOneWidget);
    expect(find.text('暂无已收录设施'), findsOneWidget);
    expect(find.text('槟城中央诊所 · 诊所'), findsOneWidget);
    expect(find.text('650 米'), findsOneWidget);
  });

  test(
    'does not turn empty or incomplete facility results into the wrong state',
    () {
      const empty = NearbyFacilitiesResult(
        categories: [
          NearbyFacilityCategory(name: '医疗健康', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '教育资源', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '日常生活', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '交通出行', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '安全与服务', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '休闲与绿地', facilities: [], totalCount: 0),
        ],
      );
      const incomplete = NearbyFacilitiesResult(
        categories: [
          NearbyFacilityCategory(
            name: '医疗健康',
            facilities: [],
            totalCount: 0,
            queryComplete: false,
          ),
          NearbyFacilityCategory(name: '教育资源', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '日常生活', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '交通出行', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '安全与服务', facilities: [], totalCount: 0),
          NearbyFacilityCategory(name: '休闲与绿地', facilities: [], totalCount: 0),
        ],
      );

      expect(empty.coverageSummary, '2 公里内暂无已收录周边设施');
      expect(incomplete.coverageSummary, '周边设施覆盖情况暂不可确定');
    },
  );

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
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存实勘'));
    await tester.pumpAndSettle();

    expect(find.text('海风公寓（新实勘）'), findsWidgets);
    expect(find.text('风险摘要'), findsOneWidget);
  });

  testWidgets('confirms before leaving an inspection editor without saving', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('账户'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('房产实勘档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增实勘'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('确定不保存并退出？'), findsOneWidget);

    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('新增房产实勘'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不保存退出'));
    await tester.pumpAndSettle();
    expect(find.text('房产实勘档案'), findsOneWidget);
    expect(find.text('海风公寓（新实勘）'), findsNothing);
  });

  testWidgets(
    'adds a camera photo to a new inspection and shows pending sync',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(const LocateMyApp());

      await tester.tap(find.text('账户'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('房产实勘档案'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增实勘'));
      await tester.pumpAndSettle();

      expect(find.textContaining('照片 0/20'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('相机'));
      await tester.pumpAndSettle();

      expect(find.textContaining('照片 1/20'), findsOneWidget);
      expect(find.text('待同步'), findsOneWidget);
      expect(find.textContaining('演示视觉占位'), findsOneWidget);
    },
  );

  testWidgets('editing photos supports captions, cover fallback and retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('账户'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('房产实勘档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('海景花园排屋').last);
    await tester.pumpAndSettle();

    expect(find.text('同步失败'), findsOneWidget);
    await tester.tap(find.text('重试同步'));
    await tester.pumpAndSettle();
    expect(find.text('同步完成'), findsWidgets);

    await tester.tap(find.text('编辑实勘'));
    await tester.pumpAndSettle();
    expect(find.textContaining('照片 2/20'), findsOneWidget);
    expect(find.text('封面'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '窗边采光和墙面状态正常。');
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设为封面'));
    await tester.pumpAndSettle();
    final deleteCover = find.widgetWithText(TextButton, '删除照片').last;
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(deleteCover);
    await tester.pumpAndSettle();
    expect(find.text('删除这张照片？'), findsOneWidget);
    expect(find.text('只会移除实勘副本，不影响设备相册原图。'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '删除照片'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('照片 1/20'), findsOneWidget);
    expect(find.text('已自动改用最早上传的照片作为封面'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存实勘'));
    await tester.pumpAndSettle();
    expect(find.text('照片说明：窗边采光和墙面状态正常。'), findsOneWidget);
  });

  testWidgets('blocks adding a twenty-first inspection photo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const LocateMyApp());

    await tester.tap(find.text('账户'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('房产实勘档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增实勘'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.text('相册'));
      await tester.pump();
    }
    expect(find.textContaining('照片 20/20'), findsOneWidget);
    expect(find.text('已达 20 张上限，请先删除现有照片后再添加。'), findsOneWidget);

    await tester.tap(find.text('相册'));
    await tester.pumpAndSettle();
    expect(find.text('照片已达上限 20 张，请先删除现有照片。'), findsOneWidget);
  });
}
