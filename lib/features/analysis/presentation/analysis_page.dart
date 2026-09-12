import 'package:flutter/material.dart';

import 'package:locatemy/core/app_state.dart';
import 'package:locatemy/core/models/location.dart';
import 'package:locatemy/core/models/nearby_facilities.dart';
import 'package:locatemy/core/widgets/app_scaffold.dart';
import 'package:locatemy/core/widgets/common_widgets.dart';
import 'package:locatemy/features/analysis/domain/cost_of_living.dart';

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
      '生活成本' => _costComparisonOverview(),
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

  (String, String) _costComparisonOverview() {
    final a = state.locationA;
    final b = state.locationB;
    if (a == null || b == null) return ('资料待补全', '资料待补全');
    final reportA = state.costReportFor(a);
    final reportB = state.costReportFor(b);
    return (
      reportA.hasCompleteIndex
          ? '指数 ${reportA.costIndex!.toStringAsFixed(0)} · ${_rm(reportA.scenarioSpend!)}'
          : '指数暂不可用 · ${reportA.coverageText} 覆盖',
      reportB.hasCompleteIndex
          ? '指数 ${reportB.costIndex!.toStringAsFixed(0)} · ${_rm(reportB.scenarioSpend!)}'
          : '指数暂不可用 · ${reportB.coverageText} 覆盖',
    );
  }

  String _rm(double value) => 'RM ${value.round()} / 月';
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
    final report = state.selectedCostReport;
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
          contextNote(
            '分析地点：${state.selected.name} · ${state.selected.area}\n'
            '默认对象：单身成年人 1 人 · 所有数值均为原型示例',
          ),
          const SizedBox(height: 14),
          _indexCard(context, report),
          const SizedBox(height: 12),
          _basketCard(context, report),
          const SizedBox(height: 14),
          _localPrices(context, report),
          const SizedBox(height: 14),
          _budgetScenario(context, report),
          const SizedBox(height: 14),
          _budgetPressure(context, report),
          const SizedBox(height: 14),
          _dataBoundary(context, report),
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
          '以相同的统一生活篮子和预算场景并列两个单点报告；只有资料可比时才显示差异。',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        _comparisonMetrics(context),
        const SizedBox(height: 14),
        _comparisonPrices(context),
        const SizedBox(height: 12),
        const Text(
          '生活成本指数相对于固定全国单身成年人基准篮子 = 100；不是 CPI、政府评级或地点排名。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        notice(),
      ],
    ),
  );

  Widget _indexCard(BuildContext context, CostReport report) => appCard(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('生活成本指数', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (report.hasCompleteIndex)
          Text(
            '${report.costIndex!.toStringAsFixed(0)} · 固定基准 100',
            style: Theme.of(context).textTheme.titleLarge,
          )
        else
          const Text(
            '暂不可用 · 资料条件未满足',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 6),
        Text(
          report.hasCompleteIndex
              ? '指数是辅助读数，RM/月是主结果。示例估算 · 2026年9月1日'
              : _qualityReason(report),
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _basketCard(BuildContext context, CostReport report) => appCard(
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
          _rm(report.scenarioSpend ?? report.observedSpend),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          report.scenarioSpend == null
              ? '最近 12 个月平均 · 部分篮子估算 · 住房或交通未计入'
              : report.meetsDataQuality
              ? '最近 12 个月平均 · 包含住房、交通与可用篮子项目 · 示例估算'
              : '最近 12 个月平均 · 部分篮子估算 · 不代表完整月支出',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('篮子覆盖率'),
            const SizedBox(width: 8),
            Text(
              report.coverageText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                '${report.availableMonths}/12 个月有可用观测',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: report.coverage),
      ],
    ),
    color: const Color(0xffeaf2ff),
  );

  Widget _localPrices(BuildContext context, CostReport report) {
    final observed = report.availableItems
        .where((item) => item.source == CostSource.officialObservation)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('本地价格 · 示例'),
        appCard(
          context,
          Column(
            children: [
              ...observed.map((item) => _priceRow(context, report.place, item)),
              if (report.missingItems.isNotEmpty) ...[
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '缺少商品：${report.missingItems.map((item) => item.name).join('、')}（已从金额剔除）',
                    style: const TextStyle(
                      color: Color(0xff9b2c2c),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '观测日期：2026年9月1日 · 代表性价格为原型示例，不是实时官方数据。',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, Place place, CostBasketItem item) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text('${item.name} · ${item.unit}')),
            Text(_rm(item.unitPriceFor(place)!)),
            const SizedBox(width: 8),
            const Text(
              '官方观测',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      );

  Widget _budgetScenario(BuildContext context, CostReport report) => appCard(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '预算场景与输入',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: state.hasCurrentAssessmentScenario
                  ? state.clearCurrentAssessmentScenario
                  : state.restoreDemoAssessmentScenario,
              child: Text(
                state.hasCurrentAssessmentScenario ? '清除预案' : '使用演示预案',
              ),
            ),
          ],
        ),
        const Text('住房与交通没有公共数据默认值；空白与 RM 0 是两种不同状态。'),
        const SizedBox(height: 12),
        _amountField(
          controller: state.housingController,
          label: '住房月支出',
          onChanged: state.setHousingMonthly,
          value: state.housingMonthly,
        ),
        const SizedBox(height: 10),
        _amountField(
          controller: state.transportController,
          label: '交通月支出',
          onChanged: state.setTransportMonthly,
          value: state.transportMonthly,
        ),
        const SizedBox(height: 10),
        _amountField(
          controller: state.monthlyNetIncomeController,
          label: '月净收入（可选）',
          onChanged: state.setMonthlyNetIncome,
          value: state.monthlyNetIncome,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Text('篮子数量／频次调整')),
            IconButton(
              onPressed: () => state.setBasketQuantityMultiplier(
                state.basketQuantityMultiplier - .1,
              ),
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: '减少篮子数量／频次',
            ),
            Text('${state.basketQuantityMultiplier.toStringAsFixed(1)}x'),
            IconButton(
              onPressed: () => state.setBasketQuantityMultiplier(
                state.basketQuantityMultiplier + .1,
              ),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: '增加篮子数量／频次',
            ),
          ],
        ),
        Text(
          state.hasCurrentAssessmentScenario
              ? '当前预案为页面内存演示；调整会立即更新金额。'
              : '尚未设置当前评估预案，预算压力不可计算。',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _amountField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    required int? value,
  }) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      prefixText: 'RM ',
      helperText: value == null
          ? '未填写（不会按 RM 0 计算）'
          : value == 0
          ? '已明确选择 RM 0'
          : '用户输入 · RM/月',
    ),
  );

  Widget _budgetPressure(BuildContext context, CostReport report) {
    final available = state.hasCompleteBudgetInputs && report.meetsDataQuality;
    return appCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('预算压力', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (!state.hasCurrentAssessmentScenario)
            const Text('预算压力尚不可计算：请先设置当前评估预案。')
          else if (!report.hasScenarioInputs)
            const Text('预算压力尚不可计算：住房和交通都需要填写，或明确选择 RM 0。')
          else if (!available)
            const Text('预算压力尚不可计算：目前只有部分篮子资料，不能把部分金额当作完整支出。')
          else ...[
            _pressureRow('地点基线', report.locationBudgetBurden, '行政区家庭收入中位数'),
            const SizedBox(height: 8),
            _pressureRow(
              '个人压力',
              report.personalBudgetBurden(state.monthlyNetIncome?.toDouble()),
              state.monthlyNetIncome == null ? '月净收入未填写' : '用户月净收入',
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            '只显示连续百分比，不自动标记低／中／高。地点基线与个人压力不是同一个指标。',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _pressureRow(String label, double? value, String source) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(value == null ? '尚不可计算' : '${value.toStringAsFixed(1)}%'),
      const SizedBox(width: 8),
      Text(source, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ],
  );

  Widget _dataBoundary(BuildContext context, CostReport report) => appCard(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('数据口径与缺失说明', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 7),
        const Text('官方观测：本地商品代表价格；模型假设：篮子项目数量与非市场项目；用户输入：住房、交通和月净收入。'),
        const SizedBox(height: 7),
        Text(_qualityReason(report)),
        if (state.costDataShortage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: state.toggleCostDataShortage,
            icon: const Icon(Icons.restore),
            label: const Text('恢复完整示例资料'),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: state.toggleCostDataShortage,
            icon: const Icon(Icons.warning_amber_outlined),
            label: const Text('演示覆盖率不足状态'),
          ),
      ],
    ),
  );

  Widget _comparisonMetrics(BuildContext context) {
    final a = state.locationA;
    final b = state.locationB;
    if (a == null || b == null) {
      return const Text('地点资料不足，无法比较。');
    }
    final reportA = state.costReportFor(a);
    final reportB = state.costReportFor(b);
    final comparable =
        state.comparisonScenarioMatches &&
        reportA.hasCompleteIndex &&
        reportB.hasCompleteIndex;
    if (!comparable) {
      final reason = !state.comparisonScenarioMatches
          ? '预算场景不一致：住房、交通或篮子调整必须相同，不能显示纯地点差异。'
          : '资料不足：两地都需要满足至少 6/12 个月观测、80% 篮子覆盖率及完整住房／交通输入。';
      return appCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '生活成本差异暂不可用',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(reason),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: state.toggleComparisonScenario,
              child: Text(
                state.comparisonScenarioMatches ? '演示不同预算场景' : '恢复相同预算场景',
              ),
            ),
          ],
        ),
      );
    }
    final difference = reportA.scenarioSpend! - reportB.scenarioSpend!;
    return Column(
      children: [
        _metric(
          context,
          '生活成本指数',
          reportA.costIndex!.toStringAsFixed(0),
          reportB.costIndex!.toStringAsFixed(0),
          '固定全国单身成年人基准篮子 = 100 · 同一预算场景',
        ),
        const SizedBox(height: 12),
        _metric(
          context,
          '统一生活篮子估算月支出',
          _rm(reportA.scenarioSpend!),
          _rm(reportB.scenarioSpend!),
          '口径可比 · 差异 ${_rm(difference.abs())}（A − B）',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: state.toggleComparisonScenario,
            child: const Text('演示不同预算场景'),
          ),
        ),
      ],
    );
  }

  Widget _comparisonPrices(BuildContext context) {
    final a = state.locationA;
    final b = state.locationB;
    if (a == null || b == null) return const SizedBox.shrink();
    final items = costBasketItems
        .where((item) => item.source == CostSource.officialObservation)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('同名商品价格对照 · 示例'),
        appCard(
          context,
          Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Text('项目')),
                  Expanded(child: Text('地点 A · ${a.short}')),
                  Expanded(child: Text('地点 B · ${b.short}')),
                ],
              ),
              const Divider(),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.name)),
                      Expanded(child: Text(_rm(item.unitPriceFor(a)!))),
                      Expanded(child: Text(_rm(item.unitPriceFor(b)!))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '观测日期：2026年9月1日 · 地点比较沿用同一预算场景。',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _qualityReason(CostReport report) {
    final reasons = <String>[];
    if (report.availableMonths < 6) {
      reasons.add('12个月内只有${report.availableMonths}个月有可用观测');
    }
    if (report.coverage < .8) {
      reasons.add('篮子覆盖率低于80%');
    }
    if (report.housingMonthly == null) {
      reasons.add('住房月支出未填写');
    }
    if (report.transportMonthly == null) {
      reasons.add('交通月支出未填写');
    }
    return reasons.isEmpty
        ? '已满足覆盖率、观测月份和预算输入条件；指数仍只是模型辅助读数。'
        : '当前状态：${reasons.join('；')}。仍显示部分金额，不显示完整总指数。';
  }

  String _rm(double value) =>
      'RM ${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} / 月';

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
