import 'package:flutter/material.dart';
import '../domain/safety_models.dart';

class SafetyTrendChart extends StatelessWidget {
  final SafetyTrend trend;
  const SafetyTrendChart({required this.trend, super.key});

  @override
  Widget build(BuildContext context) {
    if (trend.points.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    return AspectRatio(
      aspectRatio: 2.0,
      child: CustomPaint(
        painter: _TrendPainter(trend.points),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<AnnualCrimePoint> points;

  _TrendPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF155EEF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF155EEF)
      ..style = PaintingStyle.fill;

    final maxVal = points.map((p) => p.convictedCases).reduce((a, b) => a > b ? a : b);
    final minVal = points.map((p) => p.convictedCases).reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(1, double.infinity);

    final double padding = 20.0;
    final double width = size.width - 2 * padding;
    final double height = size.height - 2 * padding;

    final double dx = width / (points.length - 1);

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = padding + i * dx;
      final y = size.height - padding - (points[i].convictedCases - minVal) / range * height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
