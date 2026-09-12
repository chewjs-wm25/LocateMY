// PROTOTYPE: Three home metric layouts, switchable with the bottom bar.
// Question: should income median and OPR use the same visual treatment as
// cost pressure without making the home page too dense on a small screen?

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
  var variant = 0;

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
        const Text('同一组示例数据 · 只比较信息层级与小屏可读性'),
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

const _metrics = [
  Metric('成本压力', '68'),
  Metric('就业稳定度', '74'),
  Metric('经济动能', '70'),
  Metric('家庭收入中位数', 'RM 6,338', caption: '2025 年'),
  Metric('OPR 参考值', '3.00%', caption: '非实时'),
];

class _WrappedCards extends StatelessWidget {
  const _WrappedCards();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 16) / 3;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _metrics
            .map((metric) => SizedBox(width: width, child: metric))
            .toList(),
      );
    },
  );
}

class _FeaturedMetrics extends StatelessWidget {
  const _FeaturedMetrics();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(child: _metrics[3]),
          const SizedBox(width: 8),
          Expanded(child: _metrics[4]),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _metrics
            .take(3)
            .map((metric) => SizedBox(width: 104, child: metric))
            .toList(),
      ),
    ],
  );
}

class _VerticalMetrics extends StatelessWidget {
  const _VerticalMetrics();

  @override
  Widget build(BuildContext context) => Column(
    children: _metrics
        .map(
          (metric) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: metric,
              ),
            ),
          ),
        )
        .toList(),
  );
}
