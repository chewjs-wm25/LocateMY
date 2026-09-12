// PROTOTYPE: Three home metric layouts, switchable with the bottom bar.
// Every variant keeps the same hierarchy: moving-time score, three component
// scores, then household income as background data.

import 'package:flutter/material.dart';

import 'package:locatemy/core/theme/app_theme.dart';
import 'package:locatemy/widgets/common_widgets.dart';

void main() => runApp(const HomeMetricsPrototypeApp());

class HomeMetricsPrototypeApp extends StatelessWidget {
  const HomeMetricsPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: locateMyTheme(),
    home: const HomeMetricsPrototypePage(),
  );
}

class HomeMetricsPrototypePage extends StatefulWidget {
  const HomeMetricsPrototypePage({super.key});

  @override
  State<HomeMetricsPrototypePage> createState() =>
      _HomeMetricsPrototypePageState();
}

class _HomeMetricsPrototypePageState extends State<HomeMetricsPrototypePage> {
  // The focused-metrics layout is the most readable default on small screens.
  var variant = 1;

  static const names = ['A · 换行卡片', 'B · 重点指标', 'C · 纵向列表'];

  void move(int delta) {
    setState(() {
      variant = (variant + delta + names.length) % names.length;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('首页指标原型')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text('马来西亚概览', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('原型示例数据 · 只比较信息层级与小屏可读性'),
        const SizedBox(height: 20),
        switch (variant) {
          0 => const _WrappedCards(),
          1 => const _FeaturedMetrics(),
          _ => const _VerticalMetrics(),
        },
      ],
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              color: Theme.of(context).colorScheme.onInverseSurface,
              onPressed: () => move(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                names[variant],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              color: Theme.of(context).colorScheme.onInverseSurface,
              onPressed: () => move(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ),
  );
}

const _scoreMetrics = <Metric>[
  Metric(
    '成本压力',
    '68',
    score: 68,
    status: '大致稳定',
    trend: '近期变化大致稳定',
    direction: '成本压力相对较低',
    date: '示例观测：2026 年 8 月',
  ),
  Metric(
    '就业稳定度',
    '74',
    score: 74,
    status: '大致稳定',
    trend: '就业市场保持稳定',
    date: '示例观测：2026 年 7 月',
  ),
  Metric(
    '经济动能',
    '70',
    score: 70,
    status: '扩张',
    trend: '近期趋势大致稳定',
    date: '示例观测：2026 年第二季度',
  ),
];

const _incomeMetric = Metric(
  '家庭收入中位数',
  'RM 6,338 / 月',
  isScore: false,
  caption: '2024 年调查',
  direction: '按当年价格，未按通胀调整',
);

class _PrototypeHierarchy extends StatelessWidget {
  const _PrototypeHierarchy({required this.scoreLayout});
  final Widget scoreLayout;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _OverviewCard(),
      const SizedBox(height: 12),
      const Text('主要分项 · 原型示例', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      scoreLayout,
      const SizedBox(height: 12),
      const Text(
        '家庭收入背景数据 · 原型示例',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _incomeMetric,
    ],
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '搬家时机 · 原型示例',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '72/100',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
          ),
          const Text('较适合', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('原因：成本压力相对缓解'),
          const Text('原因：就业保持稳定'),
          const Text('原因：经济动能大致稳定'),
          const SizedBox(height: 8),
          Text(
            '示例观测日期：成本 2026 年 8 月 · 就业 2026 年 7 月 · 经济 2026 年第二季度',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

class _WrappedCards extends StatelessWidget {
  const _WrappedCards();

  @override
  Widget build(BuildContext context) => _PrototypeHierarchy(
    scoreLayout: LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scoreMetrics
              .map((metric) => SizedBox(width: width, child: metric))
              .toList(),
        );
      },
    ),
  );
}

class _FeaturedMetrics extends StatelessWidget {
  const _FeaturedMetrics();

  @override
  Widget build(BuildContext context) =>
      const _PrototypeHierarchy(scoreLayout: _FeaturedScoreLayout());
}

class _FeaturedScoreLayout extends StatelessWidget {
  const _FeaturedScoreLayout();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _scoreMetrics.first,
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _scoreMetrics[1]),
          const SizedBox(width: 8),
          Expanded(child: _scoreMetrics[2]),
        ],
      ),
    ],
  );
}

class _VerticalMetrics extends StatelessWidget {
  const _VerticalMetrics();

  @override
  Widget build(BuildContext context) =>
      const _PrototypeHierarchy(scoreLayout: _VerticalScoreLayout());
}

class _VerticalScoreLayout extends StatelessWidget {
  const _VerticalScoreLayout();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _scoreMetrics[0],
      const SizedBox(height: 8),
      _scoreMetrics[1],
      const SizedBox(height: 8),
      _scoreMetrics[2],
    ],
  );
}
