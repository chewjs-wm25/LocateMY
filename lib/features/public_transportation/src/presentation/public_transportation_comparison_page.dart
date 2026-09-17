// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/transit_models.dart';
import '../domain/transit_analysis_context.dart';
import 'transit_comparison_view_model.dart';

final class PublicTransportationComparisonPage extends StatefulWidget {
  final PublicTransportation transportation;
  final AnalysisReturnContext a;
  final AnalysisReturnContext b;
  final void Function(AnalysisReturnContext)? onOpenStations;
  const PublicTransportationComparisonPage({
    required PublicTransportation transportation,
    required AnalysisReturnContext a,
    required AnalysisReturnContext b,
    void Function(AnalysisReturnContext)? onOpenStations,
    super.key,
  }) : transportation = transportation,
       a = a,
       b = b,
       onOpenStations = onOpenStations;
  @override
  State<PublicTransportationComparisonPage> createState() {
    return _TransitComparisonPageState();
  }
}

final class _TransitComparisonPageState
    extends State<PublicTransportationComparisonPage> {
  late TransitComparisonViewModel _model;
  bool get _zh {
    return Localizations.localeOf(context).languageCode == 'zh';
  }

  String _t(String zh, String en) {
    if (_zh) {
      return zh;
    }
    return en;
  }

  TextStyle _style(
    double size,
    FontWeight weight, {
    Color color = const Color(0xFF172033),
  }) {
    return TextStyle(
      fontFamily: 'SourceSansPro',
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _createModel();
  }

  void _createModel() {
    _model = TransitComparisonViewModel(
      transportation: widget.transportation,
      a: widget.a,
      b: widget.b,
    );
    _model.load(TransitLoadPolicy.cacheAllowed);
  }

  @override
  void didUpdateWidget(covariant PublicTransportationComparisonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transportation != widget.transportation ||
        oldWidget.a != widget.a ||
        oldWidget.b != widget.b ||
        false) {
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
    return ListenableBuilder(
      listenable: _model,
      builder: (BuildContext context, Widget? child) {
        final TransitComparisonOutcome? outcome = _model.outcome;
        TransitLoadOutcome? a;
        TransitLoadOutcome? b;
        if (outcome is TransitComparable) {
          a = TransitAvailable(outcome.a);
          b = TransitAvailable(outcome.b);
        } else if (outcome is TransitIncomparable) {
          a = outcome.a;
          b = outcome.b;
        }
        final List<Widget> sides = <Widget>[];
        if (a != null && b != null) {
          final Widget cardA = _side(widget.a, a);
          final Widget cardB = _side(widget.b, b);
          if (_model.reversed) {
            sides.addAll(<Widget>[cardB, const SizedBox(height: 12), cardA]);
          } else {
            sides.addAll(<Widget>[cardA, const SizedBox(height: 12), cardB]);
          }
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () {
                return _model.load(TransitLoadPolicy.refresh);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: _t('返回', 'Back'),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          _t('公共交通 A/B', 'Transportation A/B'),
                          style: _style(20, FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: _t('刷新', 'Refresh'),
                        onPressed: _model.loading
                            ? null
                            : () {
                                _model.load(TransitLoadPolicy.refresh);
                              },
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        tooltip: _t('交换显示顺序', 'Swap display order'),
                        onPressed: _model.swapDisplayOrder,
                        icon: const Icon(Icons.swap_vert),
                      ),
                    ],
                  ),
                  Text(
                    _t(
                      '固定半径 1.5 公里 · 分析日 ${_date(widget.a.analysisDate)}',
                      'Fixed radius 1.5 km · Analysis date ${_date(widget.a.analysisDate)}',
                    ),
                    style: _style(13, FontWeight.w400),
                  ),
                  const SizedBox(height: 12),
                  if (_model.loading) const LinearProgressIndicator(),
                  if (outcome is TransitComparable)
                    Text(
                      _t('可比较的覆盖读数', 'Comparable coverage readings'),
                      style: _style(14, FontWeight.w600),
                    )
                  else if (outcome is TransitIncomparable)
                    Text(
                      _comparisonReason(outcome.reason),
                      style: _style(14, FontWeight.w600),
                    ),
                  const SizedBox(height: 12),
                  if (_model.retainedPreviousResult)
                    Text(
                      _t(
                        '刷新失败，仍显示此前结果。',
                        'Refresh failed. Previous results remain visible.',
                      ),
                      style: _style(13, FontWeight.w400),
                    ),
                  ...sides,
                  const SizedBox(height: 18),
                  Text(
                    _t(
                      '公共交通覆盖读数，不评价实际通勤便利或服务质量。',
                      'Transportation coverage readings do not assess commuting convenience or service quality.',
                    ),
                    style: _style(12, FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _side(AnalysisReturnContext context, TransitLoadOutcome outcome) {
    TransitSnapshot? complete;
    TransitPartialSnapshot? partial;
    if (outcome is TransitAvailable) {
      complete = outcome.snapshot;
    } else if (outcome is TransitIncomplete) {
      partial = outcome.snapshot;
    }
    final String role = context.role == LocationRole.locationA ? 'A' : 'B';
    return Container(
      key: ValueKey<String>('transit-comparison-$role'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E0ED)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _t('地点 $role', 'Location $role'),
              style: _style(12, FontWeight.w600),
            ),
            Text(
              _t(
                '分析日 ${_date(context.analysisDate)}',
                'Analysis date ${_date(context.analysisDate)}',
              ),
              style: _style(12, FontWeight.w400),
            ),
            Text(
              context.location.displayName ?? context.location.locationId,
              style: _style(18, FontWeight.w700),
            ),
            if (complete != null) ...<Widget>[
              if (complete.score != null)
                Semantics(
                  label: _t(
                    '地点 $role 交通覆盖读数 ${complete.score!.value}，满分 100',
                    'Location $role transportation coverage reading ${complete.score!.value} out of 100',
                  ),
                  child: Text(
                    '${complete.score!.value}',
                    style: _style(
                      34,
                      FontWeight.w700,
                      color: const Color(0xFF155EEF),
                    ),
                  ),
                )
              else
                Text(
                  _service(complete.serviceOutcome),
                  style: _style(14, FontWeight.w600),
                ),
              Text(
                _counts(
                  complete.uniqueStopCount,
                  complete.uniqueRouteCount,
                  complete.nearestDistanceMeters,
                ),
                style: _style(12, FontWeight.w400),
              ),
            ],
            if (partial != null) ...<Widget>[
              Text(
                _t(
                  '资料不完整，无法生成完整交通分',
                  'Data is incomplete; a complete score is unavailable',
                ),
                style: _style(14, FontWeight.w600),
              ),
              Text(
                _counts(
                  partial.uniqueStopCount,
                  partial.uniqueRouteCount,
                  partial.nearestDistanceMeters,
                ),
                style: _style(12, FontWeight.w400),
              ),
            ],
            if (outcome is TransitUnavailable)
              Text(
                _unavailable(outcome.reason),
                style: _style(14, FontWeight.w600),
              ),
            if (widget.onOpenStations != null)
              TextButton(
                onPressed: () {
                  widget.onOpenStations!(context);
                },
                child: Text(_t('查看站点', 'View stations')),
              ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _counts(int stops, int routes, int? nearest) {
    return _t(
      '$stops 个站点 · $routes 条有效路线 · 最近 ${nearest == null ? '—' : '$nearest m'}',
      '$stops stops · $routes active routes · nearest ${nearest == null ? '—' : '$nearest m'}',
    );
  }

  String _service(TransitServiceOutcome service) {
    if (service == TransitServiceOutcome.noStops) {
      return _t('范围内没有站点；交通分暂不可用', 'No stops in radius; score unavailable');
    }
    return _t(
      '有站点，但分析日期没有有效服务路线',
      'Stops exist, but no active routes on the analysis date',
    );
  }

  String _unavailable(TransitUnavailableReason reason) {
    if (reason == TransitUnavailableReason.analysisDateOutsideServiceRange) {
      return _t('分析日期超出服务日期范围', 'Analysis date is outside the service range');
    }
    if (reason == TransitUnavailableReason.retryableUnavailable) {
      return _t('暂时无法读取，请刷新重试', 'Temporarily unavailable. Refresh to retry');
    }
    if (reason == TransitUnavailableReason.sourceUnverifiable) {
      return _t('资料不完整，交通分暂不可用', 'Data is incomplete; score unavailable');
    }
    return _t(
      '分析日期没有可用交通资料',
      'Transportation data unavailable for the analysis date',
    );
  }

  String _comparisonReason(TransitComparisonReason reason) {
    switch (reason) {
      case TransitComparisonReason.sideUnavailable:
        return _t(
          '单侧或两侧资料不可用，无法比较',
          'Cannot compare: one or both sides are unavailable',
        );
      case TransitComparisonReason.sideIncomplete:
        return _t('资料不完整，无法比较交通分', 'Cannot compare scores: data is incomplete');
      case TransitComparisonReason.analysisDateMismatch:
        return _t('分析日期不同，无法比较', 'Cannot compare: analysis dates differ');
      case TransitComparisonReason.radiusMismatch:
        return _t('分析半径不同，无法比较', 'Cannot compare: analysis radii differ');
      case TransitComparisonReason.provenanceMismatch:
        return _t('资料口径不同，无法比较', 'Cannot compare: data is incompatible');
      case TransitComparisonReason.serviceOutcomeNotScored:
        return _t(
          '包含未评分服务结果，无法比较',
          'Cannot compare: a service outcome is not scored',
        );
    }
  }
}
