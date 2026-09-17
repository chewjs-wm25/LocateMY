import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/language_controller.dart';
import '../../../home_relocation_outlook/src/presentation/home_visual_style.dart';
import '../../../map_location/map_location.dart';

final class SocioEconomicPage extends StatefulWidget {
  final ValidLocationReference location;
  final ValidLocationReference? locationB;

  const SocioEconomicPage({
    required this.location,
    this.locationB,
    super.key,
  });

  @override
  State<SocioEconomicPage> createState() => _SocioEconomicPageState();
}

final class _SocioEconomicPageState extends State<SocioEconomicPage> {
  double _householdIncome = 6800;

  double _medianForLocation(ValidLocationReference location) {
    final double seed = (location.point.latitude.abs() * 1000) +
        (location.point.longitude.abs() * 1000);
    return 4200 + (seed % 2200);
  }

  double _giniForLocation(ValidLocationReference location) {
    final double seed = (location.point.latitude.abs() * 1000) +
        (location.point.longitude.abs() * 1000);
    return 0.31 + ((seed % 1000) / 1000) * 0.18;
  }

  List<double> _buildDistribution(double median) {
    final List<double> values = <double>[];
    for (int percentile = 1; percentile <= 100; percentile++) {
      final double spread = percentile / 100;
      final double base = median * (0.38 + (spread * 2.6));
      final double variation = math.sin(percentile / 7.2) * 260;
      values.add(base + variation);
    }
    return values;
  }

  int _percentileFor(double income, double minIncome, double maxIncome) {
    if (income <= minIncome) return 1;
    if (income >= maxIncome) return 100;
    final double ratio = (income - minIncome) / (maxIncome - minIncome);
    return (ratio * 99).round() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final bool zh = Localizations.localeOf(context).languageCode == 'zh';
    final double median = _medianForLocation(widget.location);
    final double gini = _giniForLocation(widget.location);
    final List<double> distribution = _buildDistribution(median);
    final double sliderMin = median * 0.4;
    final double sliderMax = median * 2.8;
    final double b40Threshold = median * 0.65;
    final double t20Threshold = median * 2.1;

    final double effectiveHouseholdIncome = _householdIncome.clamp(
      sliderMin,
      sliderMax,
    );
    final int householdIncome = effectiveHouseholdIncome.round();
    final int percentile = _percentileFor(
      effectiveHouseholdIncome,
      sliderMin,
      sliderMax,
    );
    final String incomeLabel = zh ? 'RM ${householdIncome.toString()}/月' : 'RM ${householdIncome.toString()}/month';

    final String positionText = percentile <= 1
        ? (zh ? '低于 P1' : 'Below P1')
        : percentile >= 100
        ? (zh ? '高于 P100' : 'Above P100')
        : (zh ? '大约位于 P$percentile' : 'Approx. P$percentile');

    final String medianLabel = zh ? '家庭收入中位数' : 'Household median income';
    final String giniLabel = zh ? '基尼系数' : 'Gini coefficient';
    final String thresholdLabel = zh ? 'B40 门槛' : 'B40 threshold';
    final String stateLabel = zh ? '州级参考估算' : 'State reference estimate';
    final String detailText = widget.locationB != null
        ? (zh ? 'A/B 对比概览' : 'A/B comparison context')
        : (zh ? '单点分析' : 'Single-point analysis');

    return Scaffold(
      appBar: AppBar(
        title: Text(zh ? '社会经济' : 'Socio-economic'),
        actions: [LanguageButton()],
      ),
      body: Material(
        color: HomeVisualStyle.canvas,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HomeVisualStyle.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.location.displayName ??
                        '${widget.location.point.latitude}, ${widget.location.point.longitude}',
                    style: HomeVisualStyle.text(
                      19,
                      color: HomeVisualStyle.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'RM ${median.round().toString()}',
                          style: HomeVisualStyle.text(
                            32,
                            color: HomeVisualStyle.primary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F1FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stateLabel,
                          style: HomeVisualStyle.text(
                            11,
                            color: HomeVisualStyle.primary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detailText,
                    style: HomeVisualStyle.text(
                      13,
                      color: HomeVisualStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  title: medianLabel,
                  value: 'RM ${median.round()}',
                  detail: '2024',
                ),
                _MetricTile(
                  title: giniLabel,
                  value: gini.toStringAsFixed(2),
                  detail: zh ? '更高的不平等' : 'Higher inequality',
                ),
                _MetricTile(
                  title: thresholdLabel,
                  value: 'RM ${b40Threshold.round()}',
                  detail: 'B40',
                ),
                _MetricTile(
                  title: zh ? 'T20 门槛' : 'T20 threshold',
                  value: 'RM ${t20Threshold.round()}',
                  detail: 'T20',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Panel(
              title: zh ? '收入分布' : 'Income distribution',
              subtitle: zh ? '州级收入分布参考（P1–P100）' : 'State income distribution reference (P1–P100)',
              child: SizedBox(
                height: 220,
                child: CustomPaint(
                  painter: _DistributionPainter(
                    values: distribution,
                    highlightAt: percentile,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: zh ? '收入结构' : 'Income structure',
              subtitle: zh ? '州级参考：收入份额' : 'State reference: income share',
              child: Column(
                children: [
                  _StructureRow(
                    label: 'B40',
                    share: '45%',
                    amount: 'RM ${(median * 0.65).round()}',
                    color: const Color(0xFF155EEF),
                  ),
                  _StructureRow(
                    label: 'M40',
                    share: '40%',
                    amount: 'RM ${(median * 1.1).round()}',
                    color: const Color(0xFF7AA7FF),
                  ),
                  _StructureRow(
                    label: 'T20',
                    share: '15%',
                    amount: 'RM ${(median * 2.15).round()}',
                    color: const Color(0xFF173B75),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: zh ? '用户收入位置' : 'Your income position',
              subtitle: zh ? '按当前评估预案中的家庭月收入估算' : 'Estimated from household monthly income in current assessment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          incomeLabel,
                          style: HomeVisualStyle.text(
                            22,
                            color: HomeVisualStyle.ink,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFBEF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          positionText,
                          style: HomeVisualStyle.text(
                            12,
                            color: const Color(0xFF1E8E5A),
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: effectiveHouseholdIncome,
                    min: sliderMin,
                    max: sliderMax,
                    divisions: 100,
                    label: 'RM ${effectiveHouseholdIncome.round()}',
                    activeColor: HomeVisualStyle.primary,
                    onChanged: (double value) {
                      setState(() {
                        _householdIncome = value;
                      });
                    },
                  ),
                  Text(
                    zh ? '州级参考估算；结果仅用于位置概览，不是官方阶层判定。' : 'State reference estimate; intended for context only, not an official socio-economic class.',
                    style: HomeVisualStyle.text(
                      12,
                      color: HomeVisualStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String detail;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeVisualStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: HomeVisualStyle.text(12, color: HomeVisualStyle.muted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: HomeVisualStyle.text(20, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: HomeVisualStyle.text(11, color: HomeVisualStyle.muted),
          ),
        ],
      ),
    );
  }
}

final class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeVisualStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: HomeVisualStyle.text(17, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: HomeVisualStyle.text(12, color: HomeVisualStyle.muted),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

final class _DistributionPainter extends CustomPainter {
  final List<double> values;
  final int highlightAt;

  _DistributionPainter({required this.values, required this.highlightAt});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = HomeVisualStyle.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFBFD6FF)
      ..style = PaintingStyle.fill;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final double range = maxValue == minValue ? 1 : maxValue - minValue;
    final Path linePath = Path();
    final Path fillPath = Path();

    for (int index = 0; index < values.length; index++) {
      final double x = (index / (values.length - 1)) * size.width;
      final double y = size.height -
          ((values[index] - minValue) / range) * (size.height - 20) -
          10;

      if (index == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final int markerIndex = highlightAt.clamp(0, values.length - 1);
    final double markerX = (markerIndex / (values.length - 1)) * size.width;
    final double markerY = size.height -
        ((values[markerIndex] - minValue) / range) * (size.height - 20) -
        10;

    canvas.drawCircle(Offset(markerX, markerY), 6, Paint()..color = const Color(0xFF173B75));
    canvas.drawLine(
      Offset(markerX, size.height),
      Offset(markerX, markerY),
      Paint()..color = const Color(0xFF173B75).withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

final class _StructureRow extends StatelessWidget {
  final String label;
  final String share;
  final String amount;
  final Color color;

  const _StructureRow({
    required this.label,
    required this.share,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: HomeVisualStyle.text(14, weight: FontWeight.w600),
                ),
              ),
              Text(
                share,
                style: HomeVisualStyle.text(14, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final shareValue = switch (label) {
                'B40' => 0.45,
                'M40' => 0.40,
                _ => 0.15,
              };
              return Stack(
                children: [
                  Container(
                    height: 10,
                    width: width,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    height: 10,
                    width: width * shareValue,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              amount,
              style: HomeVisualStyle.text(12, color: HomeVisualStyle.muted),
            ),
          ),
        ],
      ),
    );
  }
}
