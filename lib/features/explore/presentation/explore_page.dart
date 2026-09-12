import 'package:flutter/material.dart';

import 'package:locatemy/core/app_state.dart';
import 'package:locatemy/core/models/location.dart';
import 'package:locatemy/core/widgets/app_scaffold.dart';
import 'package:locatemy/core/widgets/common_widgets.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({required this.state, super.key});
  final LocateMyState state;

  Future<void> choose(BuildContext context) async {
    final result = await showModalBottomSheet<Place>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('选择预设地点')),
            ...Place.values.map(
              (place) => ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(place.name),
                subtitle: Text(place.area),
                onTap: () => Navigator.pop(sheetContext, place),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) state.selectPlace(result);
  }

  Future<void> startComparison(BuildContext context) async {
    final asLocationA = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('选择当前地点的比较角色'),
              subtitle: Text('${state.selected.name} 将作为地点 A 或地点 B？'),
            ),
            ListTile(
              leading: const Icon(Icons.trip_origin),
              title: const Text('作为地点 A'),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('作为地点 B'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );
    if (asLocationA == null) return;
    state.single = false;
    if (asLocationA) {
      state.setLocationA(state.selected);
      state.setLocationB(null);
    } else {
      state.setLocationA(null);
      state.setLocationB(state.selected);
    }
  }

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: '地图探索',
    up: false,
    nav: true,
    actions: [
      IconButton(
        onPressed: () => state.go(PageId.saved),
        icon: const Icon(Icons.star_border),
      ),
    ],
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 7),
          child: searchField(() => choose(context)),
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
            selected: {state.single},
            onSelectionChanged: (values) => state.setSingle(values.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.single
              ? _OnePlaceMap(state: state, onCompare: startComparison)
              : _TwoPlaceMap(state: state),
        ),
      ],
    ),
  );
}

class _OnePlaceMap extends StatelessWidget {
  const _OnePlaceMap({required this.state, required this.onCompare});
  final LocateMyState state;
  final Future<void> Function(BuildContext) onCompare;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      mapArt(state, state.selected),
      const SizedBox(height: 12),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          ActionChip(
            label: const Text('选 吉隆坡'),
            onPressed: () => state.selectPlace(Place.kl),
          ),
          ActionChip(
            label: const Text('选 乔治市'),
            onPressed: () => state.selectPlace(Place.penang),
          ),
          ActionChip(
            avatar: const Icon(Icons.warning_amber_outlined),
            label: const Text('上报隐患'),
            onPressed: () => state.go(PageId.report),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _LocationDetailCard(state: state, onCompare: onCompare),
      const SizedBox(height: 12),
      notice(),
    ],
  );
}

class _LocationDetailCard extends StatelessWidget {
  const _LocationDetailCard({required this.state, required this.onCompare});
  final LocateMyState state;
  final Future<void> Function(BuildContext) onCompare;

  bool get canShowSuitability =>
      state.hasFiveAssessmentPreferences &&
      state.hasCurrentAssessmentScenario &&
      state.selected == Place.penang;

  @override
  Widget build(BuildContext context) => appCard(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.selected.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    state.selected.area,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: state.locationDetailExpanded ? '收起地点摘要' : '展开地点摘要',
              onPressed: state.toggleLocationSummary,
              icon: Icon(
                state.locationDetailExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _suitabilityStatus(),
        if (state.locationDetailExpanded) ...[
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
          ..._summaries(),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: state.toggleSaved,
              icon: Icon(state.saved ? Icons.star : Icons.star_border),
              label: Text(state.saved ? '已收藏' : '收藏'),
            ),
            FilledButton(
              onPressed: () => state.go(PageId.analysis),
              child: const Text('查看完整分析'),
            ),
            TextButton.icon(
              onPressed: () => onCompare(context),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('发起两地比较'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _suitabilityStatus() {
    if (canShowSuitability) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xffeaf2ff),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
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
      if (!state.hasFiveAssessmentPreferences) '5 项评估偏好',
      if (!state.hasCurrentAssessmentScenario) '当前评估预案',
      if (state.selected == Place.kl) '安全指数（高优先级）的可用资料',
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

  List<Widget> _summaries() {
    final penang = state.selected == Place.penang;
    final cost = state.selectedCostReport;
    final facilities = state.nearbyFacilities;
    final costSummary = cost.hasCompleteIndex
        ? '指数 ${cost.costIndex!.toStringAsFixed(0)} · ${_rm(cost.scenarioSpend!)}'
        : '部分篮子 ${_rm(cost.scenarioSpend ?? cost.observedSpend)} · 指数待补全';
    return [
      _summary(
        Icons.shield_outlined,
        '安全',
        penang ? '安全指数 76/100 · 相对良好' : '安全指数 — · 资料待补全',
        '${state.selected.area} · 示例公共资料 · 2026年9月1日',
      ),
      _summary(
        Icons.payments_outlined,
        '生活成本',
        costSummary,
        '${state.selected.area} · 示例估算 · 2026年9月1日',
      ),
      _summary(
        Icons.storefront_outlined,
        '周边设施',
        facilities.coverageSummary,
        '固定半径 2 公里 · 示例地点资料 · 2026年9月1日',
      ),
      _summary(
        Icons.train_outlined,
        '公共交通可达性',
        penang ? '1.5 公里内 2 个站点 · 最近站点 540 米' : '1.5 公里内 3 个站点 · 最近站点 380 米',
        '固定半径 1.5 公里 · 示例地点资料 · 2026年9月1日',
      ),
      _summary(
        Icons.settings_outlined,
        '基础设施',
        penang ? '综合良好 81/100 · 缺失：教育覆盖' : '综合 79/100 · 最低分项：医疗 70',
        '${state.selected.area} · 示例公共资料 · 2026年9月1日',
      ),
    ];
  }

  String _rm(double value) => 'RM ${value.round()} / 月';

  Widget _summary(IconData icon, String title, String value, String metadata) =>
      Padding(
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
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
}

class _TwoPlaceMap extends StatelessWidget {
  const _TwoPlaceMap({required this.state});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      selector('地点 A', state.locationA, state.setLocationA),
      Center(
        child: IconButton(
          onPressed: state.locationA != null && state.locationB != null
              ? state.swapLocations
              : null,
          icon: const Icon(Icons.swap_vert, size: 30),
          tooltip: '交换地点 A 与地点 B',
        ),
      ),
      selector('地点 B', state.locationB, state.setLocationB),
      if (state.locationA != null && state.locationA == state.locationB)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            '地点 A 与地点 B不能相同，请为地点 B 选择另一处。',
            style: TextStyle(fontSize: 12, color: Color(0xffc9362b)),
          ),
        ),
      const SizedBox(height: 12),
      mapArt(
        state,
        state.locationB ?? state.locationA ?? state.selected,
        compare: true,
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: state.hasValidComparison
            ? () => state.go(PageId.analysis)
            : null,
        icon: const Icon(Icons.compare_arrows),
        label: const Text('查看地点比较'),
      ),
      const SizedBox(height: 8),
      Text(
        state.locationA == null || state.locationB == null
            ? '请先选择${state.locationA == null ? '地点 A' : '地点 B'}，再查看地点比较。'
            : state.locationA == state.locationB
            ? '地点相同，无法进入比较总览。'
            : 'A/B 只表示呈现顺序，不表示搬迁方向。此原型仅使用预设地点。',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ],
  );
}
