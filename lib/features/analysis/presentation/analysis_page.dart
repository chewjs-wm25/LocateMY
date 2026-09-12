import 'package:flutter/material.dart';

import 'package:locatemy/core/app_state.dart';
import 'package:locatemy/core/models/location.dart';
import 'package:locatemy/core/models/nearby_facilities.dart';
import 'package:locatemy/core/widgets/app_scaffold.dart';
import 'package:locatemy/core/widgets/common_widgets.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({required this.state, super.key});
  final LocateMyState state;

  static const categories = [
    (Icons.payments_outlined, '生活成本', '成本指数与月支出', PageId.cost),
    (Icons.shield_outlined, '治安与犯罪', '安全指数与趋势', PageId.safety),
    (Icons.groups_outlined, '社会经济', '收入与不平等', PageId.social),
    (Icons.settings_outlined, '基础设施', '公共服务覆盖', PageId.infra),
    (Icons.local_hospital_outlined, '周边设施', '2 公里生活圈', PageId.amenities),
    (Icons.train_outlined, '公共交通', '1.5 公里站点', PageId.transport),
  ];

  @override
  Widget build(BuildContext context) {
    if (state.isComparisonAnalysis) {
      return LocateMyScaffold(
        state: state,
        title: '地点比较总览',
        actions: [
          IconButton(
            onPressed: state.map,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            route(state),
            const SizedBox(height: 12),
            const Text(
              '并列展示六类地点分析；示例数据的来源、日期与估算状态均在卡片中标明。',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ...categories.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    onTap: () => state.go(item.$4),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(item.$1, color: const Color(0xff155eef)),
                              const SizedBox(width: 10),
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _comparisonOverview(item.$2),
                          const SizedBox(height: 6),
                          const Text(
                            '示例资料 · 2026年9月1日 · 部分为估算',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xfffff3d7),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '个人化地点适配度暂不显示：地点 A 缺少安全指数这一高优先级资料。两个地点均满足评估偏好、当前预案与资料前提后才会并列显示。',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            notice(),
          ],
        ),
      );
    }
    return LocateMyScaffold(
      state: state,
      title: '地点分析',
      actions: [
        IconButton(onPressed: state.map, icon: const Icon(Icons.map_outlined)),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            state.selected.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '${state.selected.area} · 以下均为演示数据',
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
            children: categories
                .map(
                  (item) => Card(
                    child: InkWell(
                      onTap: () => state.go(item.$4),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.$1,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const Spacer(),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.$3,
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
    );
  }

  Widget _comparisonOverview(String category) {
    final values = switch (category) {
      '生活成本' => ('指数 100 · RM 3,850/月', '指数 92 · RM 3,470/月'),
      '治安与犯罪' => ('安全指数 —', '安全指数 76/100'),
      '社会经济' => ('家庭收入 RM 6,420 · 基尼 0.41', '家庭收入 RM 5,980 · 基尼 0.39'),
      '基础设施' => ('综合覆盖 79/100', '综合覆盖 81/100 · 教育缺失'),
      '周边设施' => ('6/6 类 · 31 处', '5/6 类 · 26 处'),
      _ => ('连通性 80/100 · 3 站', '连通性 72/100 · 2 站'),
    };
    return Row(
      children: [
        Expanded(child: Text('地点 A\n${values.$1}')),
        const SizedBox(width: 12),
        Expanded(child: Text('地点 B\n${values.$2}')),
      ],
    );
  }
}

class AnalysisDetailPage extends StatelessWidget {
  const AnalysisDetailPage({
    required this.state,
    required this.page,
    super.key,
  });
  final LocateMyState state;
  final PageId page;

  @override
  Widget build(BuildContext context) {
    if (state.isComparisonAnalysis) {
      final values = switch (page) {
        PageId.safety => (
          '治安与犯罪',
          '安全指数 — · 资料待补全',
          '安全指数 76/100 · 相对良好',
          '地点 A 缺少可用的安全指数；资料不完整，不能计算差异。',
        ),
        PageId.social => (
          '社会经济',
          '家庭收入 RM 6,420 · 基尼 0.41',
          '家庭收入 RM 5,980 · 基尼 0.39',
          '示例官方统计口径相同；收入与基尼是不同读数，不合成为总分。',
        ),
        PageId.infra => (
          '基础设施',
          '综合覆盖 79/100 · 最低：医疗 70',
          '综合覆盖 81/100 · 教育覆盖缺失',
          '地点 B 缺少教育覆盖资料；覆盖项不一致，不能计算综合差异。',
        ),
        PageId.amenities => (
          '周边设施',
          '2 公里内 6/6 类 · 31 处',
          '2 公里内 5/6 类 · 26 处',
          '固定半径 2 公里 · 类别口径可比 · 示例地点资料。',
        ),
        _ => (
          '公共交通',
          '连通性 80/100 · 1.5 公里内 3 站',
          '连通性 72/100 · 1.5 公里内 2 站',
          '固定半径 1.5 公里 · 示例估算口径可比。',
        ),
      };
      return _comparisonPage(
        context,
        values.$1,
        values.$2,
        values.$3,
        values.$4,
      );
    }
    return switch (page) {
      PageId.safety => _safetyPage(context),
      PageId.social => _socialPage(context),
      PageId.infra => _infraPage(context),
      PageId.amenities => _amenitiesPage(context),
      _ => _transportPage(context),
    };
  }

  Widget _comparisonPage(
    BuildContext context,
    String category,
    String a,
    String b,
    String note,
  ) => LocateMyScaffold(
    state: state,
    title: '$category 对比',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        route(state),
        const SizedBox(height: 14),
        _metricCard(context, category, a, b, note),
        const SizedBox(height: 12),
        const Text(
          '来源：示例公共／地点资料 · 统计日期 2026年9月1日 · 原型展示，不构成结论。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        notice(),
      ],
    ),
  );

  Widget _safetyPage(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '治安与犯罪',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('分析地点：${state.selected.name} · 示例数据截至 2025 年'),
        const SizedBox(height: 16),
        score(context, '安全指数', '76/100 · 相对良好', Icons.shield_outlined),
        const SizedBox(height: 18),
        section('隐患类型筛选'),
        Wrap(
          spacing: 8,
          children: ['全部', '治安', '交通', '水灾']
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: state.safetyFilter == value,
                  onSelected: (_) => state.setSafetyFilter(value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        chart('近 6 个月上报趋势', '示意图表 · ${state.safetyFilter} · 不代表真实犯罪率'),
        const SizedBox(height: 14),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('建议：白天与夜间分别实地观察'),
          subtitle: Text('演示提示，不构成安全结论。'),
        ),
      ],
    ),
  );

  Widget _socialPage(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '社会经济',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('${state.selected.name} · 数据截至 2025 年 · 示例'),
        const SizedBox(height: 16),
        score(
          context,
          '家庭收入中位数',
          'RM 5,980 / 月 · 同比 +2.4%',
          Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 16),
        appCard(
          context,
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

  Widget _infraPage(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '基础设施',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('分析地点：${state.selected.name} · 演示数据'),
        const SizedBox(height: 16),
        score(context, '综合覆盖指数', '81/100 · 良好', Icons.settings_outlined),
        const SizedBox(height: 16),
        section('服务覆盖'),
        bar('供水', 92, '92'),
        bar('供电', 96, '96'),
        bar('医疗', 74, '74'),
        bar('教育', 0, '暂无数据'),
        bar('公共交通', 68, '68'),
        const SizedBox(height: 16),
        section('调整您的优先级 · 演示互动'),
        slider('医疗重要性', state.medical, state.setMedical),
        slider('教育优先级', state.education, state.setEducation),
        slider('交通便利性', state.transit, state.setTransit),
        const Text(
          '优先级仅改变此页面显示，不会进行真实推荐计算。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _amenitiesPage(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '周边设施',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('${state.selected.name} · 2 公里范围 · 公开地点资料示意'),
        const SizedBox(height: 16),
        _facilityCoverageScore(context),
        const SizedBox(height: 16),
        ...state.nearbyFacilities.categories.map(
          (category) => _facilityCategory(context, category),
        ),
        const SizedBox(height: 12),
        const Text(
          '距离和名称为示例，未查询真实地点资料。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _facilityCoverageScore(BuildContext context) {
    final facilities = state.nearbyFacilities;
    final value = facilities.hasUnknownCoverage
        ? '覆盖情况暂不可确定'
        : '已收录 ${facilities.totalFacilityCount} 处 · '
              '${facilities.coveredCategoryCount}/6 类';
    return score(context, '周边设施覆盖', value, Icons.place_outlined);
  }

  Widget _facilityCategory(
    BuildContext context,
    NearbyFacilityCategory category,
  ) {
    final nearest = category.nearest;
    final name = category.isUnknown
        ? '覆盖情况暂不可确定'
        : nearest == null
        ? '暂无已收录设施'
        : '${nearest.name} · ${nearest.type}';
    final distance = category.isUnknown
        ? '资料不完整，无法确定最近设施'
        : nearest?.distance ?? '资料完整，当前范围未发现该类';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        amenity(context, category.name, name, distance),
        if (category.remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(
              '另有 ${category.remainingCount} 处已收录设施',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  Widget _transportPage(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '公共交通',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        contextNote('${state.selected.name} · 1.5 公里范围 · 示例'),
        const SizedBox(height: 16),
        score(context, '交通连通性', '72/100 · 良好', Icons.train_outlined),
        const SizedBox(height: 16),
        chart('站点分布图', '◎ 分析中心     ● 预设站点     · 仅为示意'),
        const SizedBox(height: 16),
        amenity(context, 'KOMTAR 巴士总站', '巴士', '540 米 · 约步行 8 分钟'),
        amenity(context, '槟城渡轮码头', '渡轮', '1.1 公里 · 约步行 16 分钟'),
        OutlinedButton.icon(
          onPressed: state.map,
          icon: const Icon(Icons.map_outlined),
          label: const Text('在主地图中查看'),
        ),
      ],
    ),
  );

  Widget _metricCard(
    BuildContext context,
    String title,
    String a,
    String b,
    String note,
  ) => appCard(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text('地点 A\n$a')),
            Expanded(child: Text('地点 B\n$b')),
          ],
        ),
        const SizedBox(height: 8),
        Text(note, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    ),
  );
}

class CostPage extends StatelessWidget {
  const CostPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) =>
      state.isComparisonAnalysis ? _comparison(context) : _single(context);

  Widget _single(BuildContext context) {
    final isPenang = state.selected == Place.penang;
    return LocateMyScaffold(
      state: state,
      title: '单点生活成本报告',
      actions: [
        IconButton(
          onPressed: state.map,
          icon: const Icon(Icons.edit_location_alt_outlined),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            state.selected.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          contextNote('分析地点：${state.selected.name} · ${state.selected.area}'),
          const SizedBox(height: 14),
          appCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '生活成本指数',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(isPenang ? '92 · 相对于固定基准 100' : '100 · 固定基准'),
                const SizedBox(height: 5),
                const Text('示例估算 · 基准口径：马来西亚城市生活篮子 · 2026年9月1日'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          appCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '统一生活篮子估算月支出',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'RM ${isPenang ? '3,470' : '3,850'} / 月',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text('包含住房、水电、食品与本地交通 · 示例估算 · 2026年9月1日'),
              ],
            ),
            color: const Color(0xffeaf2ff),
          ),
          const SizedBox(height: 14),
          section('本地价格 · 示例'),
          dataTable(
            isPenang
                ? const [
                    ('两房租金', 'RM 1,400', ''),
                    ('午餐', 'RM 13', ''),
                    ('月度交通', 'RM 220', ''),
                  ]
                : const [
                    ('两房租金', 'RM 1,800', ''),
                    ('午餐', 'RM 15', ''),
                    ('月度交通', 'RM 250', ''),
                  ],
          ),
          const SizedBox(height: 14),
          appCard(
            context,
            state.hasCurrentAssessmentScenario
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '预算压力',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text('一人租住预案下的估算负担：RM 3,470/月'),
                      Text(
                        '当前评估预案 · 示例估算 · 不构成建议',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '预算压力尚不可计算',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      const Text('请先在账户中设置当前评估预案；不会以默认金额代替。'),
                      TextButton(
                        onPressed: () => state.go(PageId.account),
                        child: const Text('前往设置预案'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          notice(),
        ],
      ),
    );
  }

  Widget _comparison(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '生活成本比较',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        route(state),
        const SizedBox(height: 14),
        const Text(
          '以相同的生活篮子口径并列两个单点报告；只有口径可比时才显示差异。',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        _metric(context, '生活成本指数', '100', '92', '固定基准 100 · 示例估算 · 2026年9月1日'),
        const SizedBox(height: 12),
        _metric(
          context,
          '统一生活篮子估算月支出',
          'RM 3,850/月',
          'RM 3,470/月',
          '口径可比 · 差异 RM 380/月',
        ),
        const SizedBox(height: 14),
        section('同名商品价格对照 · 示例'),
        dataTable(const [
          ('两房租金', 'RM 1,800', 'RM 1,400'),
          ('午餐', 'RM 15', 'RM 13'),
          ('月度交通', 'RM 250', 'RM 220'),
        ]),
        const SizedBox(height: 12),
        const Text(
          '来源：示例本地价格资料 · 统计日期 2026年9月1日 · 所有数值均为原型估算。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        notice(),
      ],
    ),
  );

  Widget _metric(
    BuildContext context,
    String title,
    String a,
    String b,
    String note,
  ) => appCard(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text('地点 A\n$a')),
            Expanded(child: Text('地点 B\n$b')),
          ],
        ),
        const SizedBox(height: 8),
        Text(note, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    ),
  );
}
