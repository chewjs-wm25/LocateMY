import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import '../domain/home_trends.dart';
import 'home_visual_style.dart';

final class HomeTrendChart extends StatelessWidget {
  final List<HomeTrendPoint> points;
  final bool compact;
  const HomeTrendChart(this.points, {this.compact = false, super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (points.length < 2) {
      return Text(
        l.homeTrendUnavailable,
        style: HomeVisualStyle.text(11, color: HomeVisualStyle.muted),
      );
    }
    final List<String> summaries = <String>[];
    for (final HomeTrendPoint point in points) {
      summaries.add(
        '${DateFormat.yMMM(Localizations.localeOf(context).languageCode).format(point.observedAt)}: ${point.score} / 100',
      );
    }
    final String summary = summaries.join('; ');
    return Semantics(
      label: summary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.homeTrendSummary(points.length),
            style: HomeVisualStyle.text(
              compact ? 11 : 13,
              color: HomeVisualStyle.muted,
            ),
          ),
          ExcludeSemantics(
            child: SizedBox(
              height: compact ? 44 : 72,
              child: CustomPaint(
                painter: _TrendPainter(points, HomeVisualStyle.primary),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat.yMMM(
                      Localizations.localeOf(context).languageCode,
                    ).format(points.first.observedAt),
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerRight,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat.yMMM(
                      Localizations.localeOf(context).languageCode,
                    ).format(points.last.observedAt),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _TrendPainter extends CustomPainter {
  final List<HomeTrendPoint> points;
  final Color color;
  _TrendPainter(this.points, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    paint.color = color;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    final path = Path();
    final int first = points.first.observedAt.millisecondsSinceEpoch;
    final int last = points.last.observedAt.millisecondsSinceEpoch;
    for (int i = 0; i < points.length; i++) {
      final double x =
          (points[i].observedAt.millisecondsSinceEpoch - first) /
          (last - first) *
          size.width;
      final double y = size.height * (1 - points[i].score / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) {
    return old.points != points || old.color != color;
  }
}
