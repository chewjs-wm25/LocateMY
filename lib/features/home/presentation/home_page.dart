import 'package:flutter/material.dart';

import 'package:locatemy/core/app_state.dart';
import 'package:locatemy/core/models/location.dart';
import 'package:locatemy/core/widgets/app_scaffold.dart';
import 'package:locatemy/core/widgets/common_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => LocateMyScaffold(
    state: state,
    title: 'LocateMY',
    up: false,
    nav: true,
    actions: [
      IconButton(onPressed: () {}, icon: const Icon(Icons.language)),
      IconButton(
        onPressed: () => state.go(PageId.account),
        icon: const Icon(Icons.account_circle_outlined),
      ),
    ],
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('早上好，林小姐！', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('您想搬到哪里？', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        searchField(state.map),
        const SizedBox(height: 14),
        actionCard(
          context,
          Icons.map_outlined,
          '探索马来西亚',
          '寻找并分析潜在的新居',
          '探索地图',
          state.map,
        ),
        const SizedBox(height: 24),
        section('已保存地点', '查看全部', () => state.go(PageId.saved)),
        placeRow('吉隆坡', '吉隆坡联邦直辖区', '未分析', () {
          state.selectPlace(Place.kl);
          state.map();
        }),
        placeRow('乔治市（槟城）', '东北县，槟城', '78/100', () {
          state.selectPlace(Place.penang);
          state.map();
        }),
        const SizedBox(height: 20),
        section('马来西亚概览'),
        appCard(
          context,
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
        LayoutBuilder(
          builder: (context, constraints) {
            final metricWidth = (constraints.maxWidth - 16) / 3;
            const metrics = [
              Metric('成本压力', '68'),
              Metric('就业稳定度', '74'),
              Metric('经济动能', '70'),
              Metric('家庭收入中位数', 'RM 6,338', caption: '2025 年'),
              Metric('OPR 参考值', '3.00%', caption: '非实时'),
            ];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics
                  .map((metric) => SizedBox(width: metricWidth, child: metric))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 22),
        notice(),
      ],
    ),
  );
}
