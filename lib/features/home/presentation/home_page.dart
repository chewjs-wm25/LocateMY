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
        const _MovingTimeCard(),
        const SizedBox(height: 10),
        const Text(
          '主要分项 · 示例数据',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Metric(
          '成本压力',
          '68',
          score: 68,
          status: '大致稳定',
          trend: '近期变化大致稳定',
          direction: '成本压力相对较低',
          date: '示例观测：2026 年 8 月',
        ),
        const SizedBox(height: 8),
        const Metric(
          '就业稳定度',
          '74',
          score: 74,
          status: '大致稳定',
          trend: '就业市场保持稳定',
          date: '示例观测：2026 年 7 月',
        ),
        const SizedBox(height: 8),
        const Metric(
          '经济动能',
          '70',
          score: 70,
          status: '扩张',
          trend: '近期趋势大致稳定',
          date: '示例观测：2026 年第二季度',
        ),
        const SizedBox(height: 16),
        const Text(
          '家庭收入背景数据 · 示例数据',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Metric(
          '家庭收入中位数',
          'RM 6,338 / 月',
          isScore: false,
          caption: '2024 年调查',
          direction: '按当年价格，未按通胀调整',
        ),
        const SizedBox(height: 22),
        notice(),
      ],
    ),
  );
}

class _MovingTimeCard extends StatelessWidget {
  const _MovingTimeCard();

  @override
  Widget build(BuildContext context) => appCard(
    context,
    const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: Color(0xff006c68)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '搬家时机 · 示例数据',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          '72/100',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
        Text('较适合', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('原因：成本压力相对缓解'),
        Text('原因：就业保持稳定'),
        Text('原因：经济动能大致稳定'),
        SizedBox(height: 8),
        Text(
          '示例观测日期：成本 2026 年 8 月 · 就业 2026 年 7 月 · 经济 2026 年第二季度',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          '分数不是政府评级，也不是对未来的保证。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );
}
