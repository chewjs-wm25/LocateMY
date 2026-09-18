// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../map_location/map_location.dart';
import '../../../../l10n/language_controller.dart';
import '../domain/socio_models.dart';
import 'socio_view_model.dart';

const Color _canvas = Color(0xFFF5F7FA);
const Color _ink = Color(0xFF172033);
const Color _muted = Color(0xFF667085);
const Color _blue = Color(0xFF155EEF);
const Color _teal = Color(0xFF148F83);
const Color _amber = Color(0xFFB76E00);

final class SocioEconomicPage extends StatefulWidget {
  final SocioEconomic socio;
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  const SocioEconomicPage({
    required SocioEconomic socio,
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    super.key,
  }) : socio = socio,
       location = location,
       locationB = locationB;
  @override
  State<SocioEconomicPage> createState() {
    return _SocioEconomicPageState();
  }
}

final class _SocioEconomicPageState extends State<SocioEconomicPage> {
  late SocioViewModel _model;
  bool get _zh {
    return Localizations.localeOf(context).languageCode == 'zh';
  }

  String _text(String en, String zh) {
    if (_zh) {
      return zh;
    }
    return en;
  }

  @override
  void initState() {
    super.initState();
    _createModel();
  }

  void _createModel() {
    _model = SocioViewModel(widget.socio, widget.location, widget.locationB);
    _model.load();
  }

  @override
  void didUpdateWidget(SocioEconomicPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.socio != widget.socio ||
        oldWidget.location != widget.location ||
        oldWidget.locationB != widget.locationB) {
      _model.dispose();
      _createModel();
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        title: Text(
          _text('Socio-economic', '社会与经济'),
          style: _style(22, FontWeight.w700),
        ),
        actions: <Widget>[
          const LanguageButton(),
          IconButton(
            tooltip: _text('Refresh', '刷新'),
            onPressed: () {
              _model.load(refresh: true);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _model,
        builder: (BuildContext context, Widget? child) {
          final List<Widget> content = <Widget>[];
          if (_model.loading) {
            content.add(
              LinearProgressIndicator(semanticsLabel: _text('Loading', '加载中')),
            );
          }
          if (_model.failed ||
              _model.a?.failure != null ||
              _model.b?.failure != null) {
            content.add(
              Text(
                _text('Temporarily unavailable. Please retry.', '暂不可用，请重试。'),
                style: _style(14),
              ),
            );
            content.add(
              TextButton(
                onPressed: () {
                  _model.load(refresh: true);
                },
                child: Text(_text('Retry', '重试')),
              ),
            );
          }
          if (_model.a != null) {
            content.add(
              _analysis(_model.a!, widget.locationB == null ? null : 'A'),
            );
          }
          if (_model.b != null) {
            content.add(const SizedBox(height: 24));
            content.add(_analysis(_model.b!, 'B'));
            content.add(_comparison(SocioComparison(_model.a!, _model.b!)));
          }
          return RefreshIndicator(
            onRefresh: () {
              return _model.load(refresh: true);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              physics: const AlwaysScrollableScrollPhysics(),
              children: content,
            ),
          );
        },
      ),
    );
  }

  Widget _analysis(SocioAnalysis result, String? role) {
    String name =
        result.location.displayName ??
        '${result.location.point.latitude}, ${result.location.point.longitude}';
    if (role != null) {
      name = '$role · $name';
    }
    final SocioReading? income = result.income;
    final SocioReading? gini = result.gini;
    final SocioStructure? structure = result.structure;
    final IncomePosition? position = result.position;
    String scope =
        result.district ??
        result.state ??
        _text('Location unresolved', '地点未解析');
    final List<Widget> content = <Widget>[
      Text(name, style: _style(20, FontWeight.w700)),
      const SizedBox(height: 6),
      Text(scope, style: _style(13, FontWeight.w400, _muted)),
      const SizedBox(height: 20),
      _card(<Widget>[
        Text(
          income?.district == null
              ? _text('Official state reference', '官方州级参考')
              : _text('Official district statistics', '官方地区读数'),
          style: _style(13, FontWeight.w600, const Color(0xFF16865C)),
        ),
        const SizedBox(height: 8),
        Text(
          _text('Household median income', '家庭收入中位数'),
          style: _style(14, FontWeight.w600, _muted),
        ),
        const SizedBox(height: 6),
        Text(
          income == null ? _text('No data', '暂无数据') : _money(income.value),
          style: _style(30, FontWeight.w700),
        ),
        if (income == null)
          Text(
            _text(
              'No matching district or state income data',
              '没有匹配的行政区或州收入数据',
            ),
            style: _style(12, FontWeight.w400, _muted),
          ),
        if (income != null)
          Text(
            '${income.district ?? income.state} · ${income.year}',
            style: _style(12, FontWeight.w400, _muted),
          ),
      ]),
      const SizedBox(height: 24),
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _text('State reference estimates', '州级参考估算'),
              style: _style(18, FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3DE),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _text('Estimate', '估算'),
              style: _style(13, FontWeight.w600, _amber),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ];
    if (structure == null) {
      content.add(
        Text(
          _text('Income structure: No data', '收入结构：暂无数据'),
          style: _style(14),
        ),
      );
    } else {
      content.add(
        Text(
          '${result.state} · ${structure.year} · ${_text('Derived from percentiles', '由百分位数据推导')}',
          style: _style(12, FontWeight.w400, _muted),
        ),
      );
      content.add(_band('B40', structure.b40, _blue));
      content.add(_band('M40', structure.m40, _teal));
      content.add(_band('T20', structure.t20, _amber));
      content.add(
        Text(
          'B40 ${_text('threshold', '门槛')}: ${_optionalMoney(structure.b40Threshold)}\nM40 ${_text('threshold', '门槛')}: ${_optionalMoney(structure.m40Threshold)}',
          style: _style(13),
        ),
      );
    }
    content.add(const SizedBox(height: 24));
    final Widget giniCard = _card(<Widget>[
      Text(
        _text('Gini coefficient', '基尼系数'),
        style: _style(13, FontWeight.w600, _muted),
      ),
      const SizedBox(height: 8),
      Text(
        gini?.value.toStringAsFixed(3) ?? _text('No data', '暂无数据'),
        style: _style(26, FontWeight.w700),
      ),
      if (gini == null)
        Text(
          _text(
            'No matching district or state inequality data',
            '没有匹配的行政区或州不平等数据',
          ),
          style: _style(12, FontWeight.w400, _muted),
        ),
      if (gini != null)
        Text(
          '${gini.district ?? gini.state} · ${gini.year}',
          style: _style(11, FontWeight.w400, _muted),
        ),
      if (result.giniChange != null)
        Text(
          '${_text('Annual change', '同比变化')}: ${result.giniChange!.toStringAsFixed(3)}',
          style: _style(12),
        ),
    ]);
    final Widget positionCard = _card(<Widget>[
      Text(
        _text('Your income position', '你的收入位置'),
        style: _style(13, FontWeight.w600, _muted),
      ),
      const SizedBox(height: 8),
      Text(_positionLabel(position), style: _style(26, FontWeight.w700, _blue)),
      if (position == null)
        Text(
          _text(
            'Requires saved household income and a complete state distribution',
            '需要已保存家庭收入及完整州分布',
          ),
          style: _style(12, FontWeight.w400, _muted),
        ),
      if (position != null)
        Text(
          '${_money(position.householdIncome)} · ${position.year}',
          style: _style(12),
        )
    ]);
    content.add(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < 350 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                giniCard,
                const SizedBox(height: 16),
                positionCard,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: giniCard),
              const SizedBox(width: 16),
              Expanded(child: positionCard),
            ],
          );
        },
      ),
    );
    content.add(const SizedBox(height: 24));
    content.add(
      _card(<Widget>[
        Text(
          _text('State income distribution reference', '州级收入分布参考'),
          style: _style(18, FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${result.state ?? scope} · ${result.distributionYear ?? '—'} · RM/${_text('month', '月')}',
          style: _style(12, FontWeight.w400, _muted),
        ),
        if (result.distributionPoints.isEmpty)
          Text(
            _text('No data: incomplete distribution', '暂无数据：分布不完整'),
            style: _style(14),
          )
        else
          Semantics(
            label: _text(
              'Observed percentiles P1 to P100. P50: ${_optionalMoney(result.distributionPoints[50])}',
              '真实百分位 P1 至 P100。P50：${_optionalMoney(result.distributionPoints[50])}',
            ),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: CustomPaint(
                painter: _DistributionPainter(result.distributionPoints),
              ),
            ),
          ),
      ]),
    );
    final Set<int> visibleYears = <int>{};
    if (income != null) {
      visibleYears.add(income.year);
    }
    if (gini != null) {
      visibleYears.add(gini.year);
    }
    if (structure != null) {
      visibleYears.add(structure.year);
    }
    if (result.distributionYear != null) {
      visibleYears.add(result.distributionYear!);
    }
    if (position != null) {
      visibleYears.add(position.year);
    }
    if (visibleYears.length > 1) {
      content.add(
        Text(
          _text(
            'Different survey years; avoid direct comparison.',
            '统计年份不同，不宜直接比较。',
          ),
          style: _style(13),
        ),
      );
    }
    content.add(const SizedBox(height: 24));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: content,
    );
  }

  Widget _comparison(SocioComparison result) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: _card(<Widget>[
        Text(
          _text('A/B differences (B − A)', 'A/B 差异（B − A）'),
          style: _style(18, FontWeight.w700),
        ),
        Text(
          '${_text('Median income', '收入中位数')}: ${_difference(result.incomeDifference, true)}',
          style: _style(14),
        ),
        Text(
          '${_text('Gini', '基尼')}: ${_difference(result.giniDifference, false)}',
          style: _style(14),
        ),
      ]),
    );
  }

  String _difference(double? value, bool money) {
    if (value == null) {
      return _text(
        'Not comparable: missing data, survey year, scope or boundary version differs',
        '不可比：数据缺失，或调查年份、层级、边界版本不同',
      );
    }
    if (money) {
      return _money(value);
    }
    return value.toStringAsFixed(3);
  }

  String _positionLabel(IncomePosition? position) {
    if (position == null) {
      return _text('Temporarily unavailable', '暂不可用');
    }
    if (position.boundary == IncomePositionBoundary.belowP1) {
      return _text('Below P1', '低于 P1');
    }
    if (position.boundary == IncomePositionBoundary.aboveP100) {
      return _text('Above P100', '高于 P100');
    }
    return 'P${NumberFormat('0.#').format(position.percentile)}';
  }

  Widget _band(String label, SocioGroup group, Color color) {
    final String share = '${(group.share * 100).toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 56,
                child: Text(label, style: _style(14, FontWeight.w700)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: group.share,
                    minHeight: 8,
                    color: color,
                    backgroundColor: const Color(0xFFEDF1F6),
                    semanticsLabel: '$label ${_text('income share', '收入份额')}',
                    semanticsValue: share,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(share, style: _style(14, FontWeight.w700, color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_text('Group mean', '组内平均收入')}: ${_money(group.mean)}',
            style: _style(12, FontWeight.w400, _muted),
          ),
        ],
      ),
    );
  }

  String _optionalMoney(double? amount) {
    if (amount == null) {
      return _text('No data', '暂无数据');
    }
    return _money(amount);
  }

  String _money(double amount) {
    return 'RM ${NumberFormat('#,##0.##').format(amount)}';
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

TextStyle _style(
  double size, [
  FontWeight weight = FontWeight.w400,
  Color color = _ink,
]) {
  return TextStyle(
    fontFamily: 'SourceSansPro',
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

final class _DistributionPainter extends CustomPainter {
  final Map<int, double> points;
  _DistributionPainter(Map<int, double> points) : points = points;
  void _label(Canvas canvas, String text, Offset offset) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: _style(11)),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    double maximum = 1;
    for (final double value in points.values) {
      if (value > maximum) {
        maximum = value;
      }
    }
    final double width = size.width - 50;
    final double height = size.height - 40;
    const double left = 40;
    final Paint line = Paint();
    line.color = _blue;
    line.strokeWidth = 2;
    line.style = PaintingStyle.stroke;
    final Path path = Path();
    final List<int> percentiles = points.keys.toList();
    percentiles.sort();
    bool first = true;
    for (final int percentile in percentiles) {
      final double x = left + ((percentile - 1) / 99) * width;
      final double y = 10 + height - (points[percentile]! / maximum) * height;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
    final double? median = points[50];
    if (median != null) {
      final Offset p50 = Offset(
        left + (49 / 99) * width,
        10 + height - (median / maximum) * height,
      );
      final Paint marker = Paint();
      marker.color = _teal;
      canvas.drawCircle(p50, 4, marker);
      _label(
        canvas,
        'P50 · RM ${NumberFormat('#,##0').format(median)}',
        Offset(left + width / 3, 10),
      );
    }
    _label(canvas, 'P1', Offset(left, height + 18));
    _label(canvas, 'P100', Offset(size.width - 32, height + 18));
    _label(canvas, '0', Offset(0, height));
    _label(canvas, NumberFormat.compact().format(maximum), Offset(0, 0));
  }

  @override
  bool shouldRepaint(covariant _DistributionPainter oldDelegate) {
    return !identical(points, oldDelegate.points);
  }
}
