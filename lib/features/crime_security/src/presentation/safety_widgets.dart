

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/safety_models.dart';
import 'safety_strings.dart';

final class SafetyResultCard extends StatelessWidget {
  final SafetyAnalysis analysis;
  const SafetyResultCard({required SafetyAnalysis analysis, super.key})
    : analysis = analysis;
  @override
  Widget build(BuildContext context) {
    final SafetyStrings s = SafetyStrings(context);
    final NumberFormat number = NumberFormat.decimalPattern(s.zh ? 'zh' : 'en');
    String state = s.text('Complete data', '完整数据');
    if (analysis.availability == SafetyAvailability.partial) {
      state = s.text('Partial data', '部分数据');
    }
    if (analysis.availability == SafetyAvailability.unavailable) {
      state = s.unavailable;
    }
    final List<Widget> children = <Widget>[
      Text(
        s.text('State safety index', '州级安全指数'),
        style: const TextStyle(
          color: Color(0xFFB9C9E8),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            analysis.score == null
                ? '—'
                : number.format(analysis.score!.round()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            '/ 100',
            style: TextStyle(color: Color(0xFFD7E0F1), fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              state,
              style: const TextStyle(
                color: Color(0xFF126C4A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
    if (analysis.year != null) {
      String latest = s.text(
        '${analysis.year} complete year',
        '${analysis.year} 年完整年度',
      );
      if (analysis.latestCount != null) {
        latest =
            '$latest · ${s.text('Convicted cases', '已定罪案件')} ${number.format(analysis.latestCount)}';
      }
      children.add(
        Text(
          latest,
          style: const TextStyle(color: Color(0xFFCFD9EB), fontSize: 13),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F44),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

final class SafetyTrendCard extends StatelessWidget {
  final List<CrimeYearCount> points;
  const SafetyTrendCard({required List<CrimeYearCount> points, super.key})
    : points = points;
  @override
  Widget build(BuildContext context) {
    final SafetyStrings s = SafetyStrings(context);
    final NumberFormat number = NumberFormat.decimalPattern(s.zh ? 'zh' : 'en');
    final List<Widget> values = <Widget>[];
    for (final CrimeYearCount p in points) {
      values.add(
        Text(
          '${p.year}: ${p.count == null ? s.unavailable : number.format(p.count)}',
          style: const TextStyle(fontSize: 13),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            s.text(
              'Convicted cases, not the actual crime rate',
              '案件数，不代表实际犯罪率',
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: CustomPaint(painter: _TrendPainter(points)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 4, children: values),
        ],
      ),
    );
  }
}

final class _TrendPainter extends CustomPainter {
  final List<CrimeYearCount> points;
  _TrendPainter(List<CrimeYearCount> points) : points = points;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }
    int max = 0;
    for (final CrimeYearCount p in points) {
      if (p.count != null && p.count! > max) {
        max = p.count!;
      }
    }
    final Paint line = Paint();
    line.color = const Color(0xFF155EEF);
    line.strokeWidth = 2;
    final Paint grid = Paint();
    grid.color = const Color(0xFFD9E0EA);
    grid.strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 4),
      Offset(size.width, size.height - 4),
      grid,
    );
    Offset? previous;
    for (int i = 0; i < points.length; i++) {
      final int? count = points[i].count;
      if (count == null) {
        previous = null;
        continue;
      }
      final double x =
          12 +
          (size.width - 24) * i / (points.length > 1 ? points.length - 1 : 1);
      double fraction = 0;
      if (max > 0) {
        fraction = count / max;
      }
      final Offset point = Offset(
        x,
        size.height - 4 - fraction * (size.height - 12),
      );
      if (previous != null) {
        canvas.drawLine(previous, point, line);
      }
      canvas.drawCircle(point, 4, line);
      previous = point;
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
