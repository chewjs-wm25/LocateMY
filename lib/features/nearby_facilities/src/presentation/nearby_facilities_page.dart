

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/facility_models.dart';
import 'facilities_view_model.dart';
import 'facility_text.dart';

final class NearbyFacilitiesPage extends StatefulWidget {
  final NearbyFacilities facilities;
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  const NearbyFacilitiesPage({
    required NearbyFacilities facilities,
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    super.key,
  }) : facilities = facilities,
       location = location,
       locationB = locationB;
  @override
  State<NearbyFacilitiesPage> createState() {
    return _NearbyFacilitiesPageState();
  }
}

final class _NearbyFacilitiesPageState extends State<NearbyFacilitiesPage> {
  late FacilitiesViewModel _model;
  @override
  void initState() {
    super.initState();
    _createModel();
  }

  void _createModel() {
    _model = FacilitiesViewModel(
      facilities: widget.facilities,
      location: widget.location,
      locationB: widget.locationB,
    );
    _model.load();
  }

  @override
  void didUpdateWidget(NearbyFacilitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.location, widget.location) ||
        !identical(oldWidget.locationB, widget.locationB) ||
        !identical(oldWidget.facilities, widget.facilities)) {
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
    final FacilityText text = FacilityText(context);
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'SourceSansPro',
          bodyColor: const Color(0xFF172033),
          displayColor: const Color(0xFF172033),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _model,
            builder: (BuildContext context, Widget? child) {
              return SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: <Widget>[
                    _header(context, text),
                    const SizedBox(height: 16),
                    if (_model.loading) ...<Widget>[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        text.pick('正在查询周边设施…', 'Loading nearby facilities…'),
                      ),
                    ] else if (widget.locationB != null)
                      ..._comparison(context, text)
                    else
                      ..._single(
                        context,
                        text,
                        _model.outcome,
                        widget.location,
                      ),
                    if (!_model.loading) ..._disclosure(text),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, FacilityText text) {
    final Widget back = IconButton(
      tooltip: text.pick('返回', 'Back'),
      onPressed: () {
        Navigator.maybePop(context);
      },
      icon: const Icon(Icons.chevron_left),
    );
    final Widget title = Text(
      text.pick('周边设施', 'Nearby facilities'),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    );
    final Widget refresh = TextButton(
      onPressed: _model.loading
          ? null
          : () {
              _model.load(FacilityRefreshPolicy.refresh);
            },
      child: Text(text.pick('刷新', 'Refresh')),
    );
    if (MediaQuery.textScalerOf(context).scale(22) > 30) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              back,
              Expanded(child: title),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: refresh),
        ],
      );
    }
    return Row(
      children: <Widget>[
        back,
        Expanded(child: title),
        refresh,
      ],
    );
  }

  List<Widget> _single(
    BuildContext context,
    FacilityText text,
    FacilityAnalysisOutcome? outcome,
    ValidLocationReference location,
  ) {
    final List<Widget> widgets = <Widget>[
      Text(
        location.displayName ?? text.pick('选定地点', 'Selected location'),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        text.pick('固定半径 2 公里', 'Fixed 2 km radius'),
        style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
      ),
      const SizedBox(height: 20),
    ];
    if (outcome is FacilityAnalysisAvailable) {
      widgets.addAll(_available(context, text, outcome.analysis));
    } else {
      FacilityFailure failure = FacilityFailure.retryableUnavailable;
      if (outcome is FacilityAnalysisUnavailable) {
        failure = outcome.failure;
      }
      widgets.addAll(<Widget>[
        Text(
          text.pick('资料暂不可用', 'Data unavailable'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(text.failure(failure)),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () {
              _model.load(FacilityRefreshPolicy.refresh);
            },
            child: Text(text.pick('重试', 'Retry')),
          ),
        ),
      ]);
    }
    return widgets;
  }

  List<Widget> _available(
    BuildContext context,
    FacilityText text,
    FacilityAnalysis analysis,
  ) {
    int covered = 0;
    int total = 0;
    bool complete = analysis.categories.length == 5;
    bool countsKnown = true;
    for (final FacilityCategoryResult category in analysis.categories) {
      if (category.state == FacilityCategoryState.unknown) {
        complete = false;
      }
      if (category.state == FacilityCategoryState.covered) {
        covered += 1;
      }
      if (category.count == null &&
          category.state != FacilityCategoryState.completeEmpty) {
        countsKnown = false;
      } else {
        total += category.count ?? 0;
      }
    }
    String coverage = text.pick('覆盖状态未知', 'Coverage unknown');
    if (complete) {
      coverage = text.pick('$covered / 5 类', '$covered / 5 categories');
    }
    final List<Widget> widgets = <Widget>[
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              text.pick('范围内覆盖', 'Recorded coverage'),
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              coverage,
              style: const TextStyle(
                color: Color(0xFF16865C),
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (complete && countsKnown)
              Text(
                text.pick('共 $total 个已收录设施', '$total recorded facilities'),
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        text.pick('按类别查看最近设施', 'Nearest facilities by category'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
    ];
    for (final FacilityCategoryResult category in analysis.categories) {
      widgets.add(_categoryCard(text, category));
    }
    return widgets;
  }

  Widget _categoryCard(FacilityText text, FacilityCategoryResult result) {
    const List<Color> colors = <Color>[
      Color(0xFF16865C),
      Color(0xFF155EEF),
      Color(0xFF148F83),
      Color(0xFFB76E00),
      Color(0xFF16865C),
    ];
    final List<String> nearest = <String>[];
    for (final NearbyFacility item in result.nearest) {
      String name = item.displayName;
      if (name == '未命名地点') {
        name = text.pick('未命名地点', 'Unnamed location');
      }
      nearest.add('$name ${item.distanceMetres.round()} m');
    }
    String subtitle = nearest.join(' · ');
    String count = '—';
    if (result.state == FacilityCategoryState.completeEmpty) {
      subtitle = text.pick('范围内暂无已收录设施', 'No recorded facilities in range');
      count = '0';
    } else if (result.state == FacilityCategoryState.unknown) {
      subtitle = text.pick('资料状态未知', 'Data status unknown');
    } else {
      subtitle = '${text.pick('已覆盖', 'Covered')} · $subtitle';
      if (result.count != null) {
        count = '${result.count}';
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9E0EA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[result.category.index],
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text.category(result.category),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _disclosure(FacilityText text) {
    return <Widget>[
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () async {
            final Uri url = Uri.parse(
              'https://www.openstreetmap.org/copyright',
            );
            try {
              if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
                return;
              }
            } catch (_) {
              
            }
            if (mounted) {
              await showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('© OpenStreetMap contributors'),
                    content: SelectableText(url.toString()),
                  );
                },
              );
            }
          },
          child: const Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    ];
  }

  List<Widget> _comparison(BuildContext context, FacilityText text) {
    final FacilityComparisonOutcome? result = _model.comparison;
    if (result is FacilityComparisonAvailable) {
      return <Widget>[
        Text(
          text.pick(
            'A/B 可比较 · 同半径与分类版本',
            'A/B comparable · same radius and mapping',
          ),
        ),
        const SizedBox(height: 16),
        Text('A', style: const TextStyle(fontWeight: FontWeight.w700)),
        ..._single(
          context,
          text,
          FacilityAnalysisAvailable(analysis: result.comparison.locationA),
          widget.location,
        ),
        const SizedBox(height: 24),
        Text('B', style: const TextStyle(fontWeight: FontWeight.w700)),
        ..._single(
          context,
          text,
          FacilityAnalysisAvailable(analysis: result.comparison.locationB),
          widget.locationB!,
        ),
      ];
    }
    if (result is FacilityComparisonNotComparable) {
      final String reason = text.comparisonFailure(result.failure);
      return <Widget>[
        Text('${text.pick('无法比较', 'Not comparable')}: $reason'),
        const SizedBox(height: 16),
        const Text('A'),
        ..._single(context, text, result.locationA, widget.location),
        const SizedBox(height: 24),
        const Text('B'),
        ..._single(context, text, result.locationB, widget.locationB!),
      ];
    }
    FacilityFailure failure = FacilityFailure.retryableUnavailable;
    if (result is FacilityComparisonUnavailable) {
      failure = result.failure;
    }
    return _single(
      context,
      text,
      FacilityAnalysisUnavailable(failure: failure),
      widget.location,
    );
  }
}
