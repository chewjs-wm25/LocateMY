import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/infrastructure_models.dart';
import 'infrastructure_view_model.dart';

final class InfrastructureCoveragePage extends StatefulWidget {
  final ValidLocationReference location;
  final DateTime analysisDate;

  const InfrastructureCoveragePage({
    required this.location,
    required this.analysisDate,
    super.key,
  });

  @override
  State<InfrastructureCoveragePage> createState() =>
      _InfrastructureCoveragePageState();
}

final class _InfrastructureCoveragePageState extends State<InfrastructureCoveragePage> {
  late final InfrastructureViewModel _model;

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';

  String _t(String zh, String en) => _zh ? zh : en;

  @override
  void initState() {
    super.initState();
    _model = InfrastructureViewModel(
      location: widget.location,
      analysisDate: widget.analysisDate,
    );
    _model.load(InfrastructureLoadPolicy.cacheAllowed);
  }

  @override
  void didUpdateWidget(covariant InfrastructureCoveragePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
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
        final InfrastructureLoadOutcome? outcome = _model.outcome;
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _model.load(InfrastructureLoadPolicy.refresh),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: _t('返回', 'Back'),
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.chevron_left),
                        padding: EdgeInsets.zero,
                      ),
                      Expanded(
                        child: Text(
                          _t('基础设施覆盖', 'Infrastructure coverage'),
                          style: _style(20, FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: _model.loading
                            ? null
                            : () => _model.load(InfrastructureLoadPolicy.refresh),
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
                        label: _t('正在读取基础设施覆盖', 'Loading infrastructure coverage'),
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
                  if (outcome is InfrastructureAvailable)
                    ..._available(outcome.snapshot),
                  if (outcome is InfrastructurePartial)
                    ..._partial(outcome.snapshot),
                  if (outcome is InfrastructureUnavailable)
                    _notice(_reason(outcome.reason)),
                  const SizedBox(height: 16),
                  _weightsCard(),
                  const SizedBox(height: 14),
                  Text(
                    _t(
                      '基础设施覆盖读数为综合指标，仅表示记录覆盖，不代表服务质量。',
                      'Infrastructure coverage reading is an aggregate indicator representing recorded coverage only; it does not assess service quality.',
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

  List<Widget> _available(InfrastructureCoverage snapshot) {
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
              _t('综合基础设施覆盖', 'Infrastructure coverage score'),
              style: _style(14, FontWeight.w600, const Color(0xFFB9C9E8)),
            ),
            const SizedBox(height: 4),
            Semantics(
              label: _t(
                '基础设施覆盖读数 ${snapshot.score}，满分 100',
                'Infrastructure coverage score ${snapshot.score} out of 100',
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: <Widget>[
                  Text(
                    '${snapshot.score}',
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
                    _grade(snapshot.score),
                    style: _style(
                      14,
                      FontWeight.w600,
                      const Color(0xFFCFD9EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ..._categoryList(snapshot.categories),
    ];
  }

  List<Widget> _partial(InfrastructureCoverage snapshot) {
    return <Widget>[
      _notice(
        _t(
          '资料不完整，无法生成完整覆盖分数。',
          'Data is incomplete; a complete coverage score is unavailable.',
        ),
      ),
      const SizedBox(height: 8),
      ..._categoryList(snapshot.categories),
    ];
  }

  List<Widget> _categoryList(List<InfrastructureCategoryScore> categories) {
    return <Widget>[
      Text(
        _t('分项覆盖', 'Coverage by item'),
        style: _style(18, FontWeight.w700),
      ),
      const SizedBox(height: 8),
      for (final InfrastructureCategoryScore category in categories)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9E0EA)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _categoryColour(category.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _zh ? category.labelZh : category.labelEn,
                  style: _style(14, FontWeight.w600),
                ),
              ),
              Text(
                category.missing ? '—' : '${category.score}',
                style: _style(14, FontWeight.w700, const Color(0xFF155EEF)),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _weightsCard() {
    final InfrastructureWeightSettings weights = _model.weights;
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
            _t('基础设施权重', 'Infrastructure weights'),
            style: _style(18, FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _sliderRow(
            labelZh: '医疗',
            labelEn: 'Health',
            value: weights.health,
            onChanged: (double value) => _model.updateWeights(
              health: value.round(),
            ),
          ),
          _sliderRow(
            labelZh: '教育',
            labelEn: 'Education',
            value: weights.education,
            onChanged: (double value) => _model.updateWeights(
              education: value.round(),
            ),
          ),
          _sliderRow(
            labelZh: '交通',
            labelEn: 'Transit',
            value: weights.transit,
            onChanged: (double value) => _model.updateWeights(
              transit: value.round(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String labelZh,
    required String labelEn,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _zh ? labelZh : labelEn,
                  style: _style(14, FontWeight.w600),
                ),
              ),
              Text(
                '$value',
                style: _style(13, FontWeight.w700, const Color(0xFF155EEF)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbColor: const Color(0xFF155EEF),
              activeTrackColor: const Color(0xFF155EEF),
              inactiveTrackColor: const Color(0xFFDBE5FF),
            ),
            child: Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: value.toDouble(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
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

  String _reason(String reason) {
    return _t('暂无可用基础设施资料。', 'Infrastructure data unavailable.') +
        ' ' +
        reason;
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

  Color _categoryColour(String key) {
    switch (key) {
      case 'water':
        return const Color(0xFF4A90E2);
      case 'power':
        return const Color(0xFFF5A623);
      case 'health':
        return const Color(0xFF17A589);
      case 'education':
        return const Color(0xFF9B5DE5);
      case 'transit':
        return const Color(0xFFEF476F);
      default:
        return const Color(0xFF155EEF);
    }
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
