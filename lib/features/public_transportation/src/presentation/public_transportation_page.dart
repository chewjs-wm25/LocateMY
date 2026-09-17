// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/transit_models.dart';
import '../domain/transit_shell_models.dart';
import 'transit_view_model.dart';

final class PublicTransportationPage extends StatefulWidget {
  final PublicTransportation transportation;
  final ValidLocationReference location;
  final DateTime analysisDate;
  final ApplicationShell? applicationShell;
  final AnalysisReturnContext? returnContext;
  final MapLayerHost? mapLayerHost;
  final MapWorkspace? mapWorkspace;
  const PublicTransportationPage({
    required PublicTransportation transportation,
    required ValidLocationReference location,
    required DateTime analysisDate,
    ApplicationShell? applicationShell,
    AnalysisReturnContext? returnContext,
    MapLayerHost? mapLayerHost,
    MapWorkspace? mapWorkspace,
    super.key,
  }) : transportation = transportation,
       location = location,
       analysisDate = analysisDate,
       applicationShell = applicationShell,
       returnContext = returnContext,
       mapLayerHost = mapLayerHost,
       mapWorkspace = mapWorkspace;
  @override
  State<PublicTransportationPage> createState() {
    return _PublicTransportationPageState();
  }
}

final class _PublicTransportationPageState
    extends State<PublicTransportationPage> {
  late TransitViewModel _model;
  bool get _zh {
    return Localizations.localeOf(context).languageCode == 'zh';
  }

  String _t(String zh, String en) {
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
    _model = TransitViewModel(
      transportation: widget.transportation,
      location: widget.location,
      analysisDate: widget.analysisDate,
      applicationShell: widget.applicationShell,
      returnContext: widget.returnContext,
      mapLayerHost: widget.mapLayerHost,
      mapWorkspace: widget.mapWorkspace,
    );
    _model.load(TransitLoadPolicy.cacheAllowed);
  }

  @override
  void didUpdateWidget(covariant PublicTransportationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transportation != widget.transportation ||
        oldWidget.applicationShell != widget.applicationShell ||
        oldWidget.returnContext != widget.returnContext ||
        oldWidget.mapLayerHost != widget.mapLayerHost ||
        oldWidget.mapWorkspace != widget.mapWorkspace) {
      _model.dispose();
      _createModel();
    } else if (oldWidget.location != widget.location ||
        oldWidget.analysisDate != widget.analysisDate) {
      _model.changeLocation(widget.location, widget.analysisDate);
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
        final TransitLoadOutcome? outcome = _model.outcome;
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () {
                return _model.load(TransitLoadPolicy.refresh);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: _t('返回', 'Back'),
                        onPressed: () {
                          if (widget.applicationShell != null &&
                              widget.returnContext != null) {
                            _model.returnToMap();
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        icon: const Icon(Icons.chevron_left),
                        padding: EdgeInsets.zero,
                      ),
                      Expanded(
                        child: Text(
                          _t('公共交通', 'Public transportation'),
                          style: _style(20, FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: _model.loading
                            ? null
                            : () {
                                _model.load(TransitLoadPolicy.refresh);
                              },
                        child: Text(_t('刷新', 'Refresh')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.location.displayName ??
                        _t('所选地点', 'Selected location'),
                    style: _style(20, FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_t('固定半径 1.5 公里 · 分析日', 'Fixed radius 1.5 km · Analysis date')} ${_date(_model.analysisDate)}',
                    style: _style(13, FontWeight.w400, const Color(0xFF667085)),
                  ),
                  const SizedBox(height: 18),
                  if (_model.loading)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Semantics(
                        label: _t('正在读取公共交通', 'Loading public transportation'),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (_model.retainedPreviousResult)
                    _notice(
                      _t(
                        '刷新失败，正在显示上次成功结果。',
                        'Refresh failed. Showing the previous successful result.',
                      ),
                    ),
                  if (_model.publicationOutcome
                      is ShellContributionAuthenticationRequired)
                    _notice(
                      _t(
                        '请重新登录后分享结果。当前结果仍保留在本页。',
                        'Sign in again to share this result. The current result remains visible.',
                      ),
                    ),
                  if (_model.publicationOutcome is ShellContributionRejected)
                    _notice(
                      _shellRejection(
                        (_model.publicationOutcome as ShellContributionRejected)
                            .reason,
                      ),
                    ),
                  if (_model.returnOutcome is ShellAuthenticationRequired)
                    _notice(
                      _t(
                        '会话不可用，请重新登录。当前结果仍保留在本页。',
                        'The session is unavailable. Sign in again; the current result remains visible.',
                      ),
                    ),
                  if (_model.returnOutcome is ShellIntentRejected)
                    _notice(
                      _shellRejection(
                        (_model.returnOutcome as ShellIntentRejected).reason,
                      ),
                    ),
                  if (outcome is TransitAvailable)
                    ..._available(outcome.snapshot),
                  if (outcome is TransitIncomplete)
                    ..._partial(outcome.snapshot),
                  if (outcome is TransitUnavailable) ...<Widget>[
                    _notice(_reason(outcome.reason)),
                    ..._feeds(outcome.feeds),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    _t(
                      '公共交通覆盖读数，不评价实际通勤便利或服务质量。距离为直线距离，步行分钟仅为粗略提示。',
                      'Transportation coverage reading; it does not assess commuting convenience or service quality. Distances are straight lines; walking minutes are rough hints.',
                    ),
                    style: _style(12, FontWeight.w400, const Color(0xFF667085)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _shellRejection(ShellRejectionReason reason) {
    if (reason == ShellRejectionReason.staleInput) {
      return _t(
        '原请求已过期。请使用系统返回手势，从地图重新打开公共交通。',
        'The original request has expired. Use the system back gesture and reopen transportation from the map.',
      );
    }
    return _t(
      '结果保留在本页，但暂时无法分享或返回地图。请使用系统返回手势重试。',
      'The result remains visible, but sharing or returning to the map is unavailable. Use the system back gesture to retry.',
    );
  }

  List<Widget> _available(TransitSnapshot snapshot) {
    final TransitScore? score = snapshot.score;
    return <Widget>[
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1F44),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _t('交通连通性', 'Transportation connectivity'),
              style: _style(14, FontWeight.w600, const Color(0xFFB9C9E8)),
            ),
            const SizedBox(height: 4),
            if (score != null)
              Semantics(
                label: _t(
                  '交通覆盖读数 ${score.value}，满分 100',
                  'Transportation coverage reading ${score.value} out of 100',
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: <Widget>[
                    Text(
                      '${score.value}',
                      style: _style(34, FontWeight.w700, Colors.white),
                    ),
                    Text(
                      '/ 100',
                      style: _style(
                        14,
                        FontWeight.w600,
                        const Color(0xFFCFD9EB),
                      ),
                    ),
                    Text(
                      _grade(score.value),
                      style: _style(
                        14,
                        FontWeight.w600,
                        const Color(0xFFCFD9EB),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                _service(snapshot.serviceOutcome),
                style: _style(18, FontWeight.w700, Colors.white),
              ),
            Text(
              _counts(
                snapshot.uniqueStopCount,
                snapshot.uniqueRouteCount,
                snapshot.nearestDistanceMeters,
              ),
              style: _style(12, FontWeight.w400, const Color(0xFFCFD9EB)),
            ),
          ],
        ),
      ),
      ..._stations(
        snapshot.location,
        snapshot.stations,
        snapshot.uniqueStopCount,
      ),
      ..._provenance(snapshot.provenance),
      ..._feeds(snapshot.feeds),
    ];
  }

  List<Widget> _partial(TransitPartialSnapshot snapshot) {
    return <Widget>[
      _notice(
        _t(
          '资料不完整，无法生成完整交通分。以下为成功读取部分。',
          'Data is incomplete; a complete transportation score is unavailable. Successfully read stations are shown.',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _counts(
          snapshot.uniqueStopCount,
          snapshot.uniqueRouteCount,
          snapshot.nearestDistanceMeters,
        ),
        style: _style(13, FontWeight.w600),
      ),
      ..._stations(
        snapshot.location,
        snapshot.stations,
        snapshot.uniqueStopCount,
      ),
      ..._provenance(snapshot.provenance),
      ..._feeds(snapshot.feeds),
    ];
  }

  List<Widget> _stations(
    ValidLocationReference location,
    List<TransitStation> stations,
    int count,
  ) {
    final TransitStation? selected = _model.selected;
    return <Widget>[
      const SizedBox(height: 24),
      Text(
        _t('站点分布图', 'Station distribution'),
        style: _style(18, FontWeight.w700),
      ),
      const SizedBox(height: 8),
      if (widget.mapLayerHost == null ||
          _model.layerOutcome is MapLayerAccepted)
        _map(location, stations)
      else if (_model.layerOutcome is MapLayerRejected)
        _notice(
          _t(
            '站点图层暂时无法显示，请刷新重试。',
            'The station layer could not be shown. Refresh to retry.',
          ),
        )
      else if (_model.layerOutcome is MapLayerHidden)
        _notice(
          _t(
            '站点图层已隐藏。站点资料仍可查看。',
            'The station layer is hidden. Station facts remain available.',
          ),
        )
      else
        _notice(_t('正在准备站点分布图…', 'Preparing station distribution…')),
      if (selected != null)
        Semantics(
          selected: true,
          liveRegion: true,
          child: _notice(
            '${_t('已选择：', 'Selected: ')}${selected.name} · ${_stationMeta(selected)}',
          ),
        ),
      const SizedBox(height: 24),
      Text(_t('最近站点', 'Nearest stations'), style: _style(18, FontWeight.w700)),
      Text(
        _t(
          '范围内 $count 个站点 · 列出最近 ${math.min(30, stations.length)} 个',
          'All $count stops in radius · nearest ${math.min(30, stations.length)} listed',
        ),
        style: _style(12, FontWeight.w400, const Color(0xFF667085)),
      ),
      const SizedBox(height: 8),
      for (final TransitStation station in stations.take(30))
        _stationRow(station),
    ];
  }

  Widget _map(ValidLocationReference location, List<TransitStation> stations) {
    return Semantics(
      label: _t(
        '局部站点分布图，中心及固定 1.5 公里圆，${stations.length} 个站点。',
        'Local station distribution, centre and fixed 1.5 kilometre circle, ${stations.length} stops.',
      ),
      child: Container(
        height: 202,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFDFEAE5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double radius = math.min(constraints.maxWidth / 2, 101) - 24;
            final double centreX = constraints.maxWidth / 2;
            const double centreY = 101;
            final double metresPerDegree = math.pi * 6371000 / 180;
            return Stack(
              children: <Widget>[
                Positioned(
                  left: centreX - radius,
                  top: centreY - radius,
                  width: radius * 2,
                  height: radius * 2,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x22155EEF),
                      border: Border.all(color: const Color(0xFF155EEF)),
                    ),
                  ),
                ),
                Positioned(
                  left: centreX - 19,
                  top: centreY - 19,
                  child: const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFFEAF2FF),
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFF155EEF),
                    ),
                  ),
                ),
                for (final TransitStation station in stations)
                  Positioned(
                    left:
                        centreX +
                        (station.point.longitude - location.point.longitude) *
                            metresPerDegree *
                            math.cos(location.point.latitude * math.pi / 180) *
                            radius /
                            1500 -
                        22,
                    top:
                        centreY -
                        (station.point.latitude - location.point.latitude) *
                            metresPerDegree *
                            radius /
                            1500 -
                        22,
                    child: Semantics(
                      button: true,
                      selected: _model.selected == station,
                      label: '${station.name} · ${_stationMeta(station)}',
                      child: IconButton(
                        key: ValueKey<String>(
                          'transit-marker-${station.feedId}:${station.stopId}',
                        ),
                        tooltip: station.name,
                        onPressed: () {
                          _model.select('${station.feedId}:${station.stopId}');
                        },
                        icon: Icon(
                          _model.selected == station
                              ? Icons.radio_button_checked
                              : Icons.circle,
                          size: 12,
                          color: _colour(station.type),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  bottom: 10,
                  child: Text(
                    _t('1.5 km 范围', '1.5 km radius'),
                    style: _style(12, FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stationRow(TransitStation station) {
    final bool selected = _model.selected == station;
    return Semantics(
      selected: selected,
      child: ListTile(
        key: ValueKey<String>(
          'transit-station-${station.feedId}:${station.stopId}',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        horizontalTitleGap: 10,
        minLeadingWidth: 10,
        selected: selected,
        selectedTileColor: const Color(0xFFEAF2FF),
        leading: Icon(Icons.circle, size: 10, color: _colour(station.type)),
        title: Text(station.name, style: _style(14, FontWeight.w700)),
        subtitle: Text(
          _stationMeta(station),
          style: _style(12, FontWeight.w400, const Color(0xFF667085)),
        ),
        onTap: () {
          _model.select('${station.feedId}:${station.stopId}');
        },
      ),
    );
  }

  List<Widget> _provenance(TransitProvenance provenance) {
    return <Widget>[
      const SizedBox(height: 12),
      Text(
        '${_t('本次结果生成', 'Result generated')} ${provenance.generatedAt.toIso8601String()}\n${_t('快照', 'Snapshot')}: ${provenance.snapshotId}\n${_t('参照网格', 'Reference grid')}: ${provenance.referenceGridVersion}',
        style: _style(12, FontWeight.w400, const Color(0xFF667085)),
      ),
    ];
  }

  List<Widget> _feeds(List<FeedStatus> feeds) {
    final List<Widget> result = <Widget>[];
    for (final FeedStatus feed in feeds) {
      String status;
      switch (feed.availability) {
        case FeedAvailability.usable:
          status = _t('可用', 'Usable');
          break;
        case FeedAvailability.stale:
          status = _t('资料可能过期', 'Data may be outdated');
          break;
        case FeedAvailability.failed:
          status = _t('读取或解析失败', 'Read or parse failed');
          break;
        case FeedAvailability.missing:
          status = _t('来源缺失', 'Source missing');
          break;
        case FeedAvailability.outOfServiceRange:
          status = _t('分析日超出服务日期范围', 'Analysis date outside service range');
          break;
      }
      result.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${feed.sourceId} · $status\n${feed.sourceUrl}\n${_t('采集时间', 'Captured')}: ${feed.capturedAt?.toIso8601String() ?? _t('未知', 'Unknown')}${feed.reason == null ? '' : '\n${feed.reason}'}',
            style: _style(12, FontWeight.w400, const Color(0xFF667085)),
          ),
        ),
      );
    }
    return result;
  }

  Widget _notice(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E0EA)),
      ),
      child: Text(text, style: _style(14, FontWeight.w600)),
    );
  }

  String _counts(int stops, int routes, int? nearest) {
    final String distance = nearest == null
        ? _t('最近距离未知', 'Nearest distance unknown')
        : _t('最近 $nearest m', 'nearest $nearest m');
    return _t(
      '$stops 个站点 · $routes 条有效路线 · $distance',
      '$stops stops · $routes active routes · $distance',
    );
  }

  String _stationMeta(TransitStation station) {
    String type;
    switch (station.type) {
      case TransitStationType.bus:
        type = _t('巴士', 'Bus');
        break;
      case TransitStationType.rail:
        type = _t('铁路', 'Rail');
        break;
      case TransitStationType.ferry:
        type = _t('渡轮', 'Ferry');
        break;
      case TransitStationType.other:
        type = _t('其他', 'Other');
        break;
    }
    final int minutes = (station.distanceMeters / 80).ceil();
    return '$type · ${station.distanceMeters} m · ${_t('约 $minutes 分钟（粗略步行）', 'about $minutes min (rough walk)')}';
  }

  String _service(TransitServiceOutcome outcome) {
    switch (outcome) {
      case TransitServiceOutcome.noStops:
        return _t(
          '范围内没有站点 · 交通分暂不可用',
          'No stops in radius · score unavailable',
        );
      case TransitServiceOutcome.noActiveRoutes:
        return _t(
          '有站点，但分析日没有有效路线 · 交通分暂不可用',
          'Stops present, no active routes on analysis date · score unavailable',
        );
      case TransitServiceOutcome.served:
        return _t('交通分暂不可用', 'Transportation score unavailable');
    }
  }

  String _reason(TransitUnavailableReason reason) {
    switch (reason) {
      case TransitUnavailableReason.noUsableFeed:
        return _t(
          '没有可用的 GTFS 来源。可刷新重试。',
          'No usable GTFS feed. Refresh to retry.',
        );
      case TransitUnavailableReason.analysisDateOutsideServiceRange:
        return _t(
          '分析日超出来源的服务日期范围。',
          'Analysis date is outside feed service ranges.',
        );
      case TransitUnavailableReason.retryableUnavailable:
        return _t(
          '暂时无法读取交通资料。恢复网络后刷新重试。',
          'Transportation data could not be read. Restore connectivity and refresh.',
        );
      case TransitUnavailableReason.sourceUnverifiable:
        return _t(
          '来源或参照网格无法核实，交通分不可用。',
          'Source or reference grid could not be verified; score unavailable.',
        );
    }
  }

  String _grade(int score) {
    if (score >= 80) {
      return _t('很好', 'Very good');
    }
    if (score >= 60) {
      return _t('良好', 'Good');
    }
    if (score >= 40) {
      return _t('一般', 'Average');
    }
    return _t('较弱', 'Weak');
  }

  Color _colour(TransitStationType type) {
    if (type == TransitStationType.bus) {
      return const Color(0xFFB76E00);
    }
    return const Color(0xFF148F83);
  }

  TextStyle _style(
    double size,
    FontWeight weight, [
    Color colour = const Color(0xFF172033),
  ]) {
    return TextStyle(
      fontFamily: 'SourceSansPro',
      fontSize: size,
      fontWeight: weight,
      color: colour,
    );
  }

  String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
