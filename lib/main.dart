import 'package:flutter/material.dart';

/// THROWAWAY UI PROTOTYPE. All places, maps, figures and records are local examples.
void main() => runApp(const LocateMyApp());

enum PageId {
  home,
  map,
  analysis,
  cost,
  safety,
  social,
  infra,
  amenities,
  transport,
  saved,
  properties,
  addProperty,
  detail,
  compare,
  report,
  reports,
  account,
  login,
  register,
}

enum Place { kl, penang }

extension PlaceName on Place {
  String get name => this == Place.kl ? '吉隆坡' : '乔治市（槟城）';
  String get short => this == Place.kl ? '吉隆坡' : '乔治市';
  String get area => this == Place.kl ? '吉隆坡联邦直辖区' : '东北县，槟城';
}

class Property {
  const Property(
    this.name,
    this.price,
    this.place,
    this.score,
    this.safety,
    this.hazards,
    this.flood,
    this.note,
  );
  final String name, note;
  final int price, safety, hazards;
  final Place place;
  final double score;
  final bool flood;
}

class LocateMyApp extends StatefulWidget {
  const LocateMyApp({super.key});
  @override
  State<LocateMyApp> createState() => _LocateMyAppState();
}

class _LocateMyAppState extends State<LocateMyApp> {
  PageId page = PageId.home, previous = PageId.home;
  Place selected = Place.penang;
  Place? origin = Place.kl, destination = Place.penang;
  bool single = true, saved = false, locationDetailExpanded = false;
  // These local flags deliberately model account prerequisites; this prototype
  // does not persist an account, preferences, budget scenario, or analysis data.
  bool hasFiveAssessmentPreferences = true, hasCurrentAssessmentScenario = true;
  String safetyFilter = '全部';
  int medical = 7, education = 4, transit = 8, detail = 0;
  final compared = <int>{};
  final properties = <Property>[
    const Property(
      'Taman Seri 公寓',
      520000,
      Place.penang,
      4.2,
      76,
      1,
      false,
      '下午采光良好，主路车流在傍晚较明显。',
    ),
    const Property(
      '海景花园排屋',
      680000,
      Place.penang,
      3.8,
      72,
      2,
      true,
      '排水沟需在雨季再次实地查看。',
    ),
    const Property(
      'Bukit Bintang 住宅',
      730000,
      Place.kl,
      4.0,
      81,
      0,
      false,
      '公共交通便利，夜间环境待补充观察。',
    ),
  ];
  void go(PageId value, {bool keepBack = true}) => setState(() {
    if (keepBack) previous = page;
    page = value;
  });
  void back() => setState(() => page = previous);
  void home() => setState(() => page = PageId.home);
  void map() => setState(() => page = PageId.map);
  void addProperty() => setState(() {
    properties.add(
      const Property(
        '海风公寓（新实勘）',
        598000,
        Place.penang,
        4.1,
        76,
        1,
        false,
        '示例新增记录：阳台通风良好，浴室防水需复查。',
      ),
    );
    detail = properties.length - 1;
    page = PageId.detail;
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LocateMY 原型',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff006c68)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff7f9f8),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(),
      ),
    ),
    home: Builder(builder: view),
  );
  Widget view(BuildContext context) => switch (page) {
    PageId.home => homePage(context),
    PageId.map => mapPage(context),
    PageId.analysis => analysisPage(context),
    PageId.cost => costPage(context),
    PageId.safety => safetyPage(context),
    PageId.social => socialPage(context),
    PageId.infra => infraPage(context),
    PageId.amenities => amenitiesPage(context),
    PageId.transport => transportPage(context),
    PageId.saved => savedPage(context),
    PageId.properties => propertyList(context),
    PageId.addProperty => addPage(context),
    PageId.detail => detailPage(context),
    PageId.compare => comparePage(context),
    PageId.report => reportPage(context),
    PageId.reports => reportsPage(context),
    PageId.account => accountPage(context),
    PageId.login => loginPage(context),
    PageId.register => registerPage(context),
  };
  Scaffold shell(
    String title,
    Widget body, {
    bool up = true,
    bool nav = false,
    List<Widget>? actions,
    Widget? fab,
  }) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: up
          ? IconButton(onPressed: back, icon: const Icon(Icons.arrow_back))
          : null,
      actions: actions,
    ),
    body: SafeArea(child: body),
    floatingActionButton: fab,
    bottomNavigationBar: nav ? bottom() : null,
  );
  Widget bottom() {
    final index = page == PageId.home
        ? 0
        : page == PageId.map
        ? 1
        : 2;
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        if (i == 0) home();
        if (i == 1) map();
        if (i == 2) go(PageId.account, keepBack: false);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: '地图',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '账户',
        ),
      ],
    );
  }

  Widget homePage(BuildContext c) => shell(
    'LocateMY',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('早上好，林小姐！', style: Theme.of(c).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('您想搬到哪里？', style: Theme.of(c).textTheme.headlineSmall),
        const SizedBox(height: 16),
        search(map),
        const SizedBox(height: 14),
        action(c, Icons.map_outlined, '探索马来西亚', '寻找并分析潜在的新居', '探索地图', map),
        const SizedBox(height: 24),
        section('已保存地点', '查看全部', () => go(PageId.saved)),
        placeRow('吉隆坡', '吉隆坡联邦直辖区', '未分析', () {
          selected = Place.kl;
          locationDetailExpanded = false;
          map();
        }),
        placeRow('乔治市（槟城）', '东北县，槟城', '78/100', () {
          selected = Place.penang;
          locationDetailExpanded = false;
          map();
        }),
        const SizedBox(height: 20),
        section('马来西亚概览'),
        card(
          c,
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: Color(0xff006c68)),
                  SizedBox(width: 8),
                  Text('搬家时机', style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacer(),
                  Text('示例 72/100'),
                ],
              ),
              SizedBox(height: 9),
              Text('较适合 · 成本压力缓解，就业保持稳定'),
              Text(
                '示例数据 · 截至 2026 年 9 月',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: Metric('成本压力', '68')),
            SizedBox(width: 8),
            Expanded(child: Metric('就业稳定度', '74')),
            SizedBox(width: 8),
            Expanded(child: Metric('经济动能', '70')),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '家庭收入中位数 RM 6,338 · 2025 年｜OPR 参考值 3.00% · 非实时',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 22),
        notice(),
      ],
    ),
    up: false,
    nav: true,
    actions: [
      IconButton(onPressed: () {}, icon: const Icon(Icons.language)),
      IconButton(
        onPressed: () => go(PageId.account),
        icon: const Icon(Icons.account_circle_outlined),
      ),
    ],
  );

  Widget mapPage(BuildContext c) => shell(
    '地图探索',
    Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 7),
          child: search(() => choose(c)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.location_on_outlined),
                label: Text('单点探索'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.compare_arrows),
                label: Text('两地对比'),
              ),
            ],
            selected: {single},
            onSelectionChanged: (v) => setState(() => single = v.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: single ? oneMap(c) : twoMap(c)),
      ],
    ),
    up: false,
    nav: true,
    actions: [
      IconButton(
        onPressed: () => go(PageId.saved),
        icon: const Icon(Icons.star_border),
      ),
    ],
  );
  Widget oneMap(BuildContext c) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      mapArt(selected),
      const SizedBox(height: 12),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          ActionChip(
            label: const Text('选 吉隆坡'),
            onPressed: () => setState(() {
              selected = Place.kl;
              locationDetailExpanded = false;
            }),
          ),
          ActionChip(
            label: const Text('选 乔治市'),
            onPressed: () => setState(() {
              selected = Place.penang;
              locationDetailExpanded = false;
            }),
          ),
          ActionChip(
            avatar: const Icon(Icons.warning_amber_outlined),
            label: const Text('上报隐患'),
            onPressed: () => go(PageId.report),
          ),
        ],
      ),
      const SizedBox(height: 14),
      locationDetailCard(c),
      const SizedBox(height: 12),
      notice(),
    ],
  );

  bool get canShowSuitability =>
      hasFiveAssessmentPreferences &&
      hasCurrentAssessmentScenario &&
      selected == Place.penang;

  Widget locationDetailCard(BuildContext c) => card(
    c,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.name, style: Theme.of(c).textTheme.titleMedium),
                  Text(
                    selected.area,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: locationDetailExpanded ? '收起地点摘要' : '展开地点摘要',
              onPressed: () => setState(
                () => locationDetailExpanded = !locationDetailExpanded,
              ),
              icon: Icon(
                locationDetailExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        suitabilityStatus(c),
        if (locationDetailExpanded) ...[
          const Divider(height: 25),
          const Text(
            '地点摘要',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '以下均为原型示例／估算，保留其统计口径、日期与来源位置。',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ...locationSummaries(),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => saved = !saved),
              icon: Icon(saved ? Icons.star : Icons.star_border),
              label: Text(saved ? '已收藏' : '收藏'),
            ),
            FilledButton(
              onPressed: () => go(PageId.analysis),
              child: const Text('查看完整分析'),
            ),
            TextButton.icon(
              onPressed: () => startComparison(c),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('发起两地比较'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget suitabilityStatus(BuildContext c) {
    if (canShowSuitability) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xffeaf2ff),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.person_pin_circle_outlined, color: Color(0xff155eef)),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '个人化地点适配度 78/100',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '基于 5 项偏好与「一人租住」评估预案 · 示例估算',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '基础设施的教育覆盖为低优先级缺失，未纳入计算。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final missing = <String>[
      if (!hasFiveAssessmentPreferences) '5 项评估偏好',
      if (!hasCurrentAssessmentScenario) '当前评估预案',
      if (selected == Place.kl) '安全指数（高优先级）的可用资料',
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xfffff3d7),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xffb76e00)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '尚不能计算个人化地点适配度：请补全${missing.join('、')}。不使用默认值代替缺失资料。',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> locationSummaries() {
    final penang = selected == Place.penang;
    return [
      locationSummary(
        Icons.shield_outlined,
        '安全',
        penang ? '安全指数 76/100 · 相对良好' : '安全指数 — · 资料待补全',
        '${selected.area} · 示例公共资料 · 2026年9月1日',
      ),
      locationSummary(
        Icons.payments_outlined,
        '生活成本',
        penang ? '相对成本低 8% · 预算压力 RM 3,470/月' : '相对成本基准 100 · 预算压力待评估',
        '${selected.area} · 示例估算 · 2026年9月1日',
      ),
      locationSummary(
        Icons.storefront_outlined,
        '日常便利',
        penang ? '2 公里内 5/7 类 · 最近诊所 650 米' : '2 公里内 6/7 类 · 最近诊所 480 米',
        '固定半径 2 公里 · 示例地点资料 · 2026年9月1日',
      ),
      locationSummary(
        Icons.train_outlined,
        '公共交通可达性',
        penang ? '1.5 公里内 2 个站点 · 最近站点 540 米' : '1.5 公里内 3 个站点 · 最近站点 380 米',
        '固定半径 1.5 公里 · 示例地点资料 · 2026年9月1日',
      ),
      locationSummary(
        Icons.settings_outlined,
        '基础设施',
        penang ? '综合良好 81/100 · 缺失：教育覆盖' : '综合 79/100 · 最低分项：医疗 70',
        '${selected.area} · 示例公共资料 · 2026年9月1日',
      ),
    ];
  }

  Widget locationSummary(
    IconData icon,
    String title,
    String value,
    String metadata,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: const Color(0xff155eef)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value),
              Text(
                metadata,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> startComparison(BuildContext c) async {
    final asOrigin = await showModalBottomSheet<bool>(
      context: c,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('选择当前地点的比较角色'),
              subtitle: Text('${selected.name} 将作为哪一端？'),
            ),
            ListTile(
              leading: const Icon(Icons.trip_origin),
              title: const Text('作为原地址'),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('作为新地址'),
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );
    if (asOrigin == null || !mounted) return;
    setState(() {
      single = false;
      if (asOrigin) {
        origin = selected;
        destination = null;
      } else {
        origin = null;
        destination = selected;
      }
    });
  }

  Widget twoMap(BuildContext c) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      selector('原地址', origin, (v) => setState(() => origin = v)),
      Center(
        child: IconButton(
          onPressed: origin != null && destination != null
              ? () => setState(() {
                  final x = origin;
                  origin = destination;
                  destination = x;
                })
              : null,
          icon: const Icon(Icons.swap_vert, size: 30),
          tooltip: '交换原地址与新地址',
        ),
      ),
      selector('新地址', destination, (v) => setState(() => destination = v)),
      const SizedBox(height: 12),
      mapArt(destination ?? origin ?? selected, compare: true),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed:
            origin != null && destination != null && origin != destination
            ? () => go(PageId.cost)
            : null,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('比较生活成本'),
      ),
      const SizedBox(height: 8),
      Text(
        origin == null || destination == null
            ? '请先选择${origin == null ? '原地址' : '新地址'}，再比较生活成本。'
            : origin == destination
            ? '原地址和新地址不能相同，请重新选择其中一处。'
            : '通过地图、搜索或收藏选择地点。此原型仅使用预设地点。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ],
  );

  Widget analysisPage(BuildContext c) {
    final items = [
      (Icons.payments_outlined, '生活成本', '两地价格与预算', PageId.cost),
      (Icons.shield_outlined, '治安与犯罪', '安全指数与趋势', PageId.safety),
      (Icons.groups_outlined, '社会经济', '收入与不平等', PageId.social),
      (Icons.settings_outlined, '基础设施', '公共服务覆盖', PageId.infra),
      (Icons.local_hospital_outlined, '周边设施', '2 公里生活圈', PageId.amenities),
      (Icons.train_outlined, '公共交通', '1.5 公里站点', PageId.transport),
    ];
    return shell(
      '地点分析',
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(selected.name, style: Theme.of(c).textTheme.headlineSmall),
          Text(
            '${selected.area} · 以下均为演示数据',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.05,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: items
                .map(
                  (x) => Card(
                    child: InkWell(
                      onTap: () {
                        if (x.$4 == PageId.cost) destination = selected;
                        go(x.$4);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(x.$1, color: Theme.of(c).colorScheme.primary),
                            const Spacer(),
                            Text(
                              x.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              x.$3,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          notice(),
        ],
      ),
      actions: [
        IconButton(onPressed: map, icon: const Icon(Icons.map_outlined)),
      ],
    );
  }

  Widget costPage(BuildContext c) {
    final low = origin == Place.kl && destination == Place.penang;
    return shell(
      '生活成本比较',
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          route(),
          const SizedBox(height: 18),
          card(
            c,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('预算预案', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('一人租住 · 示例预案'),
                Divider(),
                Text('租金 RM 1,400 · 生活 RM 1,850 · 交通 RM 220'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          card(
            c,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '维持相同生活方式',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '预计每月需要 RM ${low ? '3,470' : '3,850'}',
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                Text(
                  '比现在${low ? '减少' : '增加'} RM 380 · 示例估算',
                  style: TextStyle(
                    color: low ? const Color(0xff006c68) : Colors.deepOrange,
                  ),
                ),
              ],
            ),
            color: low ? const Color(0xffe1f4ed) : const Color(0xffffebe5),
          ),
          const SizedBox(height: 18),
          section('CPI 对比 · 示例'),
          bar('住房与水电', 78, '乔治市 78'),
          bar('食品与日常', 85, '乔治市 85'),
          bar('交通', 72, '乔治市 72'),
          const SizedBox(height: 18),
          section('常用商品价格 · 示例'),
          table(const [
            ('两房租金', 'RM 1,800', 'RM 1,400'),
            ('午餐', 'RM 15', 'RM 13'),
            ('月度交通', 'RM 250', 'RM 220'),
          ]),
          const SizedBox(height: 16),
          notice(),
        ],
      ),
      actions: [
        IconButton(
          onPressed: map,
          icon: const Icon(Icons.edit_location_alt_outlined),
        ),
      ],
    );
  }

  Widget safetyPage(BuildContext c) => shell(
    '治安与犯罪',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('分析地点：${selected.name} · 示例数据截至 2025 年'),
        const SizedBox(height: 16),
        score(c, '安全指数', '76/100 · 相对良好', Icons.shield_outlined),
        const SizedBox(height: 18),
        section('隐患类型筛选'),
        Wrap(
          spacing: 8,
          children: ['全部', '治安', '交通', '水灾']
              .map(
                (x) => ChoiceChip(
                  label: Text(x),
                  selected: safetyFilter == x,
                  onSelected: (_) => setState(() => safetyFilter = x),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        chart('近 6 个月上报趋势', '示意图表 · $safetyFilter · 不代表真实犯罪率'),
        const SizedBox(height: 14),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('建议：白天与夜间分别实地观察'),
          subtitle: Text('演示提示，不构成安全结论。'),
        ),
      ],
    ),
  );
  Widget socialPage(BuildContext c) => shell(
    '社会经济',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('${selected.name} · 数据截至 2025 年 · 示例'),
        const SizedBox(height: 16),
        score(
          c,
          '家庭收入中位数',
          'RM 5,980 / 月 · 同比 +2.4%',
          Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 16),
        card(
          c,
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('地区收入结构（估算）', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('B40 38%     M40 43%     T20 19%'),
              SizedBox(height: 9),
              LinearProgressIndicator(value: .38),
              SizedBox(height: 10),
              Text('基尼系数 0.39 · 中等 · 示例资料'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        chart('家庭月收入分布（估算）', '中位数 RM 5,980 · 示例，不进行真实计算'),
        const SizedBox(height: 16),
        const TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '您的家庭月收入',
            hintText: 'RM（仅供界面审查）',
          ),
        ),
      ],
    ),
  );
  Widget infraPage(BuildContext c) => shell(
    '基础设施',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('分析地点：${selected.name} · 演示数据'),
        const SizedBox(height: 16),
        score(c, '综合覆盖指数', '81/100 · 良好', Icons.settings_outlined),
        const SizedBox(height: 16),
        section('服务覆盖'),
        bar('供水', 92, '92'),
        bar('供电', 96, '96'),
        bar('医疗', 74, '74'),
        bar('教育', 0, '暂无数据'),
        bar('公共交通', 68, '68'),
        const SizedBox(height: 16),
        section('调整您的优先级 · 演示互动'),
        slider('医疗重要性', medical, (v) => setState(() => medical = v)),
        slider('教育优先级', education, (v) => setState(() => education = v)),
        slider('交通便利性', transit, (v) => setState(() => transit = v)),
        const Text(
          '优先级仅改变此页面显示，不会进行真实推荐计算。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );
  Widget amenitiesPage(BuildContext c) => shell(
    '周边设施',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('${selected.name} · 2 公里范围 · 公开地点资料示意'),
        const SizedBox(height: 16),
        score(c, '生活圈覆盖', '已收录 26 处 · 5/7 类', Icons.place_outlined),
        const SizedBox(height: 16),
        amenity(c, '医疗健康', '槟城中央诊所', '650 米'),
        amenity(c, '教育资源', '乔治市社区学校', '820 米'),
        amenity(c, '日常生活', '湿巴刹与超市', '430 米'),
        amenity(c, '交通出行', 'KOMTAR 巴士站', '540 米'),
        amenity(c, '休闲与绿地', '海滨步道', '1.2 公里'),
        const SizedBox(height: 12),
        const Text(
          '距离和名称为示例，未查询真实地点资料。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );
  Widget transportPage(BuildContext c) => shell(
    '公共交通',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('${selected.name} · 1.5 公里范围 · 示例'),
        const SizedBox(height: 16),
        score(c, '交通连通性', '72/100 · 良好', Icons.train_outlined),
        const SizedBox(height: 16),
        chart('站点分布图', '◎ 分析中心     ● 预设站点     · 仅为示意'),
        const SizedBox(height: 16),
        amenity(c, 'KOMTAR 巴士总站', '巴士', '540 米 · 约步行 8 分钟'),
        amenity(c, '槟城渡轮码头', '渡轮', '1.1 公里 · 约步行 16 分钟'),
        OutlinedButton.icon(
          onPressed: map,
          icon: const Icon(Icons.map_outlined),
          label: const Text('在主地图中查看'),
        ),
      ],
    ),
  );
  Widget savedPage(BuildContext c) => shell(
    '已保存地点',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        search(() {}),
        const SizedBox(height: 12),
        placeRow('吉隆坡', '吉隆坡联邦直辖区', '定位', () {
          selected = Place.kl;
          map();
        }),
        placeRow('乔治市（槟城）', '东北县，槟城', saved ? '已保存' : '78/100', () {
          selected = Place.penang;
          map();
        }),
        const SizedBox(height: 28),
        const Center(
          child: Text('暂无更多地点', style: TextStyle(color: Colors.black54)),
        ),
      ],
    ),
  );

  Widget propertyList(BuildContext c) => shell(
    '房产实勘档案',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '个人看房观察，不是公开房源或评价。',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ...List.generate(properties.length, (i) => propertyItem(c, i)),
        const SizedBox(height: 70),
      ],
    ),
    actions: [
      TextButton(
        onPressed: compared.length >= 2 ? () => go(PageId.compare) : null,
        child: Text('对比 ${compared.length}/3'),
      ),
    ],
    fab: FloatingActionButton.extended(
      onPressed: () => go(PageId.addProperty),
      icon: const Icon(Icons.add),
      label: const Text('新增实勘'),
    ),
  );
  Widget addPage(BuildContext c) => shell(
    '新增房产实勘',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '以下为预设示例；保存只会加入当前内存中的演示列表。',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(labelText: '房产名称 *', hintText: '海风公寓'),
        ),
        const SizedBox(height: 12),
        const TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: '价格（RM）*', hintText: '598000'),
        ),
        const SizedBox(height: 12),
        selector('地点 *', Place.penang, (_) {}),
        const SizedBox(height: 18),
        section('现场评分'),
        ...['排水', '防水', '湿度', '照明'].map(
          (x) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(x),
            trailing: const Icon(
              Icons.star_rate_rounded,
              color: Colors.amber,
              size: 30,
            ),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: false,
          onChanged: (_) {},
          title: const Text('发现当地水灾历史或迹象'),
        ),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(labelText: '备注', hintText: '记录噪音、采光等观察…'),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: addProperty, child: const Text('保存实勘')),
      ],
    ),
    actions: [TextButton(onPressed: addProperty, child: const Text('保存'))],
  );
  Widget detailPage(BuildContext c) {
    final p = properties[detail];
    return shell(
      p.name,
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(c).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.home_work_outlined, size: 58),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'RM ${p.price}',
                  style: Theme.of(c).textTheme.headlineSmall,
                ),
              ),
              Text('${p.score}/5', style: Theme.of(c).textTheme.titleLarge),
            ],
          ),
          Text(
            '${p.place.name} · ${detail == properties.length - 1 ? '刚刚保存的演示记录' : '更新于 2026/09/11'}',
          ),
          const SizedBox(height: 20),
          section('风险摘要'),
          card(
            c,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('安全 ${p.safety}/100 · 附近隐患 ${p.hazards}'),
                const SizedBox(height: 5),
                Text('水灾迹象：${p.flood ? '有，建议复查' : '未见（示例）'}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          section('实勘评分'),
          table(const [
            ('排水', '4/5', ''),
            ('防水', '3/5', ''),
            ('湿度', '4/5', ''),
            ('照明', '4/5', ''),
          ]),
          const SizedBox(height: 16),
          section('备注'),
          Text(p.note),
          const SizedBox(height: 22),
          OutlinedButton(onPressed: () {}, child: const Text('编辑（原型未实现）')),
        ],
      ),
      actions: const [Icon(Icons.more_vert)],
    );
  }

  Widget comparePage(BuildContext c) {
    final picks = compared.map((i) => properties[i]).toList();
    return shell(
      '房产对比',
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '以下为个人实勘记录的示例对比。',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('项目')),
                  ...picks.map(
                    (p) => DataColumn(
                      label: SizedBox(width: 100, child: Text(p.name)),
                    ),
                  ),
                ],
                rows: [
                  dataRow('价格', picks.map((p) => 'RM ${p.price}')),
                  dataRow('综合评分', picks.map((p) => '${p.score}/5')),
                  dataRow('安全指数', picks.map((p) => '${p.safety}/100')),
                  dataRow('附近隐患', picks.map((p) => '${p.hazards}')),
                  dataRow('水灾迹象', picks.map((p) => p.flood ? '有' : '未见')),
                  dataRow('四项实勘', picks.map((p) => '4 · 3 · 4 · 4')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow dataRow(String name, Iterable<String> values) => DataRow(
    cells: [
      DataCell(Text(name)),
      ...values.map((value) => DataCell(Text(value))),
    ],
  );
  Widget reportPage(BuildContext c) => shell(
    '上报隐患',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('位置：${selected.name}（预设地点）'),
        const SizedBox(height: 16),
        section('隐患类型'),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: ['水灾', '治安', '交通', '基础设施', '其他']
              .map(
                (x) => FilterChip(
                  label: Text(x),
                  selected: x == '水灾',
                  onSelected: (_) {},
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(labelText: '标题 *', hintText: '简要说明发生了什么'),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: '详细描述',
            hintText: '补充有助于他人判断的资讯…',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => go(PageId.reports),
          child: const Text('提交报告（仅作页面跳转）'),
        ),
      ],
    ),
    actions: [IconButton(onPressed: back, icon: const Icon(Icons.close))],
  );
  Widget reportsPage(BuildContext c) => shell(
    '我的隐患报告',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '这些均为演示记录，未被提交到任何服务。',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        card(
          c,
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.water_drop_outlined),
            title: Text('水灾 · 2026/08/18'),
            subtitle: Text('雨后排水沟积水较多\n乔治市 · 示例报告'),
          ),
        ),
        const SizedBox(height: 8),
        card(
          c,
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.traffic_outlined),
            title: Text('交通 · 2026/08/01'),
            subtitle: Text('路口晚高峰拥堵\n吉隆坡 · 示例报告'),
          ),
        ),
      ],
    ),
  );
  Widget accountPage(BuildContext c) => shell(
    '账户',
    ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            '林小姐',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        const Center(
          child: Text(
            'lin@example.com',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        const Center(
          child: Chip(
            avatar: Icon(Icons.verified, size: 16),
            label: Text('邮箱已验证'),
          ),
        ),
        const SizedBox(height: 20),
        section('我的内容'),
        ListTile(
          leading: const Icon(Icons.home_work_outlined),
          title: const Text('房产实勘档案'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => go(PageId.properties),
        ),
        ListTile(
          leading: const Icon(Icons.warning_amber_outlined),
          title: const Text('我的隐患报告'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => go(PageId.reports),
        ),
        const Divider(),
        section('地点适配设置'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.tune),
          title: Text('评估偏好'),
          subtitle: Text('安全、成本、日常便利、公共交通、基础设施 · 示例已设置'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.account_balance_wallet_outlined),
          title: Text('当前评估预案'),
          subtitle: Text('一人租住 · 示例预案（用于地点适配度与预算压力）'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('语言'),
          subtitle: const Text('中文'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('退出登录'),
          onTap: () => go(PageId.login),
        ),
        const SizedBox(height: 18),
        notice(),
      ],
    ),
    up: false,
    nav: true,
  );
  Widget loginPage(BuildContext c) => shell(
    'LocateMY',
    Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on, size: 64, color: Color(0xff006c68)),
            const Center(
              child: Text(
                '找到更适合生活的地方',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 32),
            Text('欢迎回来', style: Theme.of(c).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '电子邮箱',
                hintText: 'name@example.com',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: '密码'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: home, child: const Text('登录（演示）')),
            TextButton(
              onPressed: () => go(PageId.register),
              child: const Text('还没有账户？创建账户'),
            ),
          ],
        ),
      ),
    ),
    up: false,
  );
  Widget registerPage(BuildContext c) => shell(
    '创建账户',
    ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const TextField(
          decoration: InputDecoration(labelText: '用户名', hintText: '输入您的姓名'),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: '电子邮箱',
            hintText: 'name@example.com',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: '密码',
            helperText: '至少 8 位，包含大小写字母、数字和符号',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: '确认密码'),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: home, child: const Text('创建账户（演示）')),
        TextButton(
          onPressed: () => go(PageId.login),
          child: const Text('已有账户？登录'),
        ),
      ],
    ),
  );

  Widget search(VoidCallback tap) => TextField(
    readOnly: true,
    onTap: tap,
    decoration: const InputDecoration(
      prefixIcon: Icon(Icons.search),
      hintText: '搜索马来西亚的城市或地区',
      suffixIcon: Icon(Icons.expand_more),
    ),
  );
  Widget selector(String label, Place? value, ValueChanged<Place> onChange) =>
      DropdownButtonFormField<Place>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, hintText: '请选择地点'),
        items: Place.values
            .map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text('${p.name} · ${p.area}'),
              ),
            )
            .toList(),
        onChanged: (p) {
          if (p != null) onChange(p);
        },
      );
  Future<void> choose(BuildContext c) async {
    final result = await showModalBottomSheet<Place>(
      context: c,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('选择预设地点')),
            ...Place.values.map(
              (p) => ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(p.name),
                subtitle: Text(p.area),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        selected = result;
        locationDetailExpanded = false;
      });
    }
  }

  Widget mapArt(Place p, {bool compare = false}) => Container(
    height: 230,
    decoration: BoxDecoration(
      color: const Color(0xffdcefe8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xff9ccdc1)),
    ),
    child: Stack(
      children: [
        const Positioned(
          left: 22,
          top: 18,
          child: Text(
            '马来西亚地图 · 示意',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Positioned(
          right: 14,
          top: 18,
          child: Text(
            '非真实比例',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
        const Center(
          child: Icon(Icons.public, size: 140, color: Color(0x3373a998)),
        ),
        if (!compare || origin != null) ...[
          Positioned(
            left: 76,
            top: 65,
            child: Icon(
              Icons.location_on,
              color: compare
                  ? const Color(0xff1758a6)
                  : const Color(0xffbd342f),
              size: 42,
            ),
          ),
          Positioned(
            left: 98,
            top: 110,
            child: Text(compare ? origin!.short : p.short),
          ),
        ],
        if (compare && destination != null) ...[
          const Positioned(
            right: 70,
            bottom: 61,
            child: Icon(Icons.location_on, color: Color(0xffbd342f), size: 42),
          ),
          Positioned(right: 28, bottom: 37, child: Text(destination!.short)),
          const Positioned(
            left: 118,
            right: 105,
            top: 96,
            child: Divider(thickness: 2, color: Color(0xff1758a6)),
          ),
        ],
      ],
    ),
  );
  Widget action(
    BuildContext c,
    IconData icon,
    String title,
    String subtitle,
    String verb,
    VoidCallback tap,
  ) => Card(
    color: Theme.of(c).colorScheme.secondaryContainer,
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
            Text(verb),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    ),
  );
  Widget section(String text, [String? trailing, VoidCallback? tap]) => Row(
    children: [
      Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const Spacer(),
      if (trailing != null) TextButton(onPressed: tap, child: Text(trailing)),
    ],
  );
  Widget placeRow(
    String title,
    String subtitle,
    String suffix,
    VoidCallback tap,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          suffix,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
    onTap: tap,
  );
  Widget card(BuildContext c, Widget child, {Color? color}) => Card(
    color: color ?? Theme.of(c).colorScheme.surfaceContainerLowest,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  Widget notice() => const DecoratedBox(
    decoration: BoxDecoration(
      color: Color(0xfffff3d7),
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    child: Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'UI 原型：所有地图、数字、趋势和记录均为本地示例，不代表真实结论。',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
  Widget route() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '原地址',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              origin?.name ?? '未选择',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      const Icon(Icons.arrow_forward),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '新地址',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              destination?.name ?? '未选择',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ],
  );
  Widget contextNote(String text) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xffe6f2ef),
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
  );
  Widget score(
    BuildContext c,
    String title,
    String value,
    IconData icon,
  ) => card(
    c,
    Row(
      children: [
        Icon(icon, color: Theme.of(c).colorScheme.primary, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value),
            ],
          ),
        ),
        const Text('示例', style: TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    ),
  );
  Widget chart(String title, String caption) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          const SizedBox(
            height: 70,
            child: CustomPaint(
              size: Size(double.infinity, 70),
              painter: LinePainter(),
            ),
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
  Widget bar(String label, int n, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(width: 88, child: Text(label)),
        Expanded(child: LinearProgressIndicator(value: n / 100)),
        const SizedBox(width: 10),
        SizedBox(
          width: 68,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
  Widget slider(String label, int value, ValueChanged<int> update) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label  $value/10'),
      Slider(
        value: value.toDouble(),
        min: 1,
        max: 10,
        divisions: 9,
        label: '$value',
        onChanged: (v) => update(v.round()),
      ),
    ],
  );
  Widget amenity(BuildContext c, String title, String name, String distance) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: card(
          c,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(title),
            subtitle: Text(name),
            trailing: Text(distance, style: const TextStyle(fontSize: 12)),
          ),
        ),
      );
  Widget table(List<(String, String, String)> rows) => Card(
    child: DataTable(
      columns: const [
        DataColumn(label: Text('项目')),
        DataColumn(label: Text('吉隆坡')),
        DataColumn(label: Text('乔治市')),
      ],
      rows: rows
          .map(
            (r) => DataRow(
              cells: [
                DataCell(Text(r.$1)),
                DataCell(Text(r.$2)),
                DataCell(Text(r.$3)),
              ],
            ),
          )
          .toList(),
    ),
  );
  Widget propertyItem(BuildContext c, int i) {
    final p = properties[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: card(
        c,
        Row(
          children: [
            Checkbox(
              value: compared.contains(i),
              onChanged: (v) => setState(() {
                if (v == true && compared.length < 3) compared.add(i);
                if (v == false) compared.remove(i);
              }),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  detail = i;
                  go(PageId.detail);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('${p.place.name} · RM ${p.price} · 评分 ${p.score}/5'),
                    Text(
                      '安全 ${p.safety}/100 · 隐患 ${p.hazards}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext c) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(c).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

class LinePainter extends CustomPainter {
  const LinePainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xff006c68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    c.drawPath(
      Path()
        ..moveTo(0, s.height * .72)
        ..lineTo(s.width * .17, s.height * .52)
        ..lineTo(s.width * .34, s.height * .62)
        ..lineTo(s.width * .52, s.height * .26)
        ..lineTo(s.width * .72, s.height * .44)
        ..lineTo(s.width, s.height * .15),
      p,
    );
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
