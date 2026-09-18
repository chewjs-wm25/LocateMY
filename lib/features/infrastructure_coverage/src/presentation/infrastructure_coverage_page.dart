

import 'package:flutter/material.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../application/infrastructure_service.dart';
import '../domain/infrastructure_models.dart';
import 'infrastructure_view_model.dart';

final class InfrastructureCoveragePage extends StatefulWidget {
  final InfrastructureService service;
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  final DateTime analysisDate;
  const InfrastructureCoveragePage({
    required InfrastructureService service,
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    required DateTime analysisDate,
    super.key,
  }) : service = service,
       location = location,
       locationB = locationB,
       analysisDate = analysisDate;
  @override
  State<InfrastructureCoveragePage> createState() {
    return _InfrastructureCoveragePageState();
  }
}

final class _InfrastructureCoveragePageState
    extends State<InfrastructureCoveragePage> {
  late final InfrastructureViewModel _model;
  late final InfrastructureViewModel? _second;
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
    _model = InfrastructureViewModel(
      service: widget.service,
      location: widget.location,
      analysisDate: widget.analysisDate,
    );
    final ValidLocationReference? b = widget.locationB;
    if (b == null) {
      _second = null;
      _model.readWeights();
    } else {
      _second = InfrastructureViewModel(
        service: widget.service,
        location: b,
        analysisDate: widget.analysisDate,
      );
      _second?.load();
    }
    _model.load();
  }

  @override
  void didUpdateWidget(covariant InfrastructureCoveragePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
        oldWidget.analysisDate != widget.analysisDate) {
      _model.changeLocation(widget.location, widget.analysisDate);
    }
    if (widget.locationB != null &&
        _second != null &&
        (oldWidget.locationB != widget.locationB ||
            oldWidget.analysisDate != widget.analysisDate)) {
      _second.changeLocation(widget.locationB!, widget.analysisDate);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _second?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _model.load(InfrastructureLoadPolicy.refresh);
    await _second?.load(InfrastructureLoadPolicy.refresh);
  }

  @override
  Widget build(BuildContext context) {
    final List<Listenable> models = <Listenable>[_model];
    if (_second != null) {
      models.add(_second);
    }
    return ListenableBuilder(
      listenable: Listenable.merge(models),
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F8FB),
            surfaceTintColor: Colors.transparent,
            title: Text(_t('基础设施', 'Infrastructure')),
            actions: <Widget>[
              const LanguageButton(),
              TextButton(
                onPressed: _model.loading ? null : _refresh,
                child: Text(_t('刷新', 'Refresh')),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: <Widget>[
                ..._analysis(_model, _second == null ? null : 'A'),
                if (_second != null) ..._analysis(_second, 'B'),
                if (_second == null) _priorities(),
                if (_second != null)
                  _note(
                    _t(
                      '对比采用中性权重 5。',
                      'Comparison uses neutral priorities of 5.',
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _analysis(InfrastructureViewModel model, String? side) {
    final InfrastructureLoadOutcome? outcome = model.outcome;
    InfrastructureCoverage? snapshot;
    if (outcome is InfrastructureAvailable) {
      snapshot = outcome.snapshot;
    }
    if (outcome is InfrastructurePartial) {
      snapshot = outcome.snapshot;
    }
    final List<Widget> result = <Widget>[
      Text(
        '${side == null ? '' : '$side · '}${model.location.displayName ?? _t('所选地点', 'Selected location')}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF172033),
        ),
      ),
      const SizedBox(height: 4),
    ];
    if (snapshot?.district != null) {
      result.add(
        Text(
          '${snapshot!.state} · ${snapshot.district}',
          style: const TextStyle(color: Color(0xFF667085)),
        ),
      );
    }
    if (snapshot != null) {
      final String years = _yearNotes(snapshot);
      if (years.isNotEmpty) {
        result.add(
          Text(
            years,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
        );
      }
    }
    result.add(const SizedBox(height: 18));
    if (model.loading) {
      result.add(
        Semantics(
          label: _t('正在读取基础设施', 'Loading infrastructure'),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (model.retainedPreviousResult || outcome is InfrastructureUnavailable) {
      result.add(_note(_t('读取失败，请重试。', 'Could not load. Please retry.')));
    }
    if (snapshot != null) {
      if (snapshot.transitPartial) {
        String zh = '交通资料不完整；ICI 使用部分交通分。';
        String en =
            'Transit data is incomplete; ICI uses a partial transportation score.';
        if (snapshot.transitDistanceOnly) {
          zh += '交通分仅含距离项。';
          en += ' Transportation score includes distance only.';
        }
        result.add(_note(_t(zh, en)));
      }
      final int? score = snapshot.score;
      result.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F44),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _t('基础设施覆盖 ICI', 'Infrastructure coverage ICI'),
                style: const TextStyle(color: Color(0xFFB9C9E8), fontSize: 14),
              ),
              const SizedBox(height: 6),
              Semantics(
                label: score == null
                    ? _t('综合读数暂不可用', 'Aggregate unavailable')
                    : _t('综合读数 $score，满分100', 'Coverage $score out of 100'),
                child: Text(
                  score == null ? _t('暂不可用', 'Unavailable') : '$score / 100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                score == null
                    ? _t('可用分项少于三项', 'Fewer than three available components')
                    : _grade(score),
                style: const TextStyle(color: Color(0xFFCFD9EB)),
              ),
            ],
          ),
        ),
      );
      result.add(const SizedBox(height: 20));
      result.add(
        Text(
          _t('分项覆盖', 'Coverage components'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      );
      result.add(const SizedBox(height: 12));
      for (final InfrastructureCategoryScore category in snapshot.categories) {
        result.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9E0EA)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _zh ? category.labelZh : category.labelEn,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        category.key == 'transit'
                            ? _t('地点周围1.5公里', 'Within 1.5 km')
                            : _t('行政区统计', 'District statistics'),
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      category.score == null
                          ? '—'
                          : '${category.score!.round()}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: category.score == null
                            ? const Color(0xFFB76E00)
                            : const Color(0xFF16865C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    if (snapshot != null && snapshot.missingCategories.isNotEmpty) {
      final List<String> labels = <String>[];
      for (final InfrastructureCategoryScore category in snapshot.categories) {
        if (category.missing) {
          labels.add(_zh ? category.labelZh : category.labelEn);
        }
      }
      result.add(
        Text(
          '${_t('缺少资料', 'Missing observations')}: ${labels.join('、')}',
          style: const TextStyle(color: Color(0xFFB76E00), fontSize: 12),
        ),
      );
    }
    result.add(const SizedBox(height: 16));
    return result;
  }

  String _yearNotes(InfrastructureCoverage snapshot) {
    final Map<String, String> labels = <String, String>{
      'water': _t('供水', 'Water'),
      'power': _t('供电', 'Electricity'),
      'health': _t('医疗', 'Healthcare'),
      'schools': _t('学校', 'Schools'),
      'teachers': _t('教师', 'Teachers'),
      'enrolment': _t('学生', 'Students'),
    };
    final Map<int, List<String>> groups = <int, List<String>>{};
    for (final String key in labels.keys) {
      final int? year = snapshot.sourceYears[key];
      if (year != null) {
        groups
            .putIfAbsent(year, () {
              return <String>[];
            })
            .add(labels[key]!);
      }
    }
    final List<String> notes = <String>[];
    if (groups.length == 1) {
      notes.add('${_t('统计年份', 'Statistics')}: ${groups.keys.first}');
    } else if (groups.isNotEmpty) {
      final List<String> readings = <String>[];
      for (final MapEntry<int, List<String>> group in groups.entries) {
        readings.add('${group.value.join(' / ')} ${group.key}');
      }
      notes.add('${_t('统计年份', 'Statistics')}: ${readings.join('; ')}');
    }
    for (final String component in <String>['health', 'education']) {
      final int? population = snapshot.populationYears[component];
      final int? indicator =
          snapshot.sourceYears[component == 'health' ? 'health' : 'schools'];
      if (population != null && indicator != null && population != indicator) {
        final String name = component == 'health'
            ? _t('医疗', 'Healthcare')
            : _t('学校', 'Schools');
        notes.add(
          _t('$name采用$population年人口', '$name uses population $population'),
        );
      }
    }
    return notes.join(' · ');
  }

  String _grade(int score) {
    if (score < 40) {
      return _t('较弱', 'Weak');
    }
    if (score < 60) {
      return _t('一般', 'Fair');
    }
    if (score < 80) {
      return _t('良好', 'Good');
    }
    return _t('很好', 'Very good');
  }

  Widget _note(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }

  Widget _priorities() {
    final InfrastructureWeightSettings weights = _model.weights;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _t('基础设施权重', 'Infrastructure priorities'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFB76E00),
            ),
          ),
          Text(
            _model.preview
                ? _t('未保存预览', 'Unsaved preview')
                : _t(
                    '仅影响本页单点综合读数',
                    'Applies only to this single location aggregate',
                  ),
          ),
          if (_model.weightsFailed)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(_t('权重读取失败', 'Could not read priorities')),
                ),
                TextButton(
                  onPressed: _model.readWeights,
                  child: Text(_t('重试', 'Retry')),
                ),
              ],
            ),
          if (_model.saveFailed)
            Text(
              _t(
                '保存失败，尚未保存。请重试。',
                'Save failed. Changes remain unsaved. Please retry.',
              ),
            ),
          _slider(_t('医疗', 'Healthcare'), weights.health, (double value) {
            _model.updateWeights(health: value.round());
          }),
          _slider(_t('教育', 'Education'), weights.education, (double value) {
            _model.updateWeights(education: value.round());
          }),
          _slider(_t('公共交通', 'Public transportation'), weights.transit, (
            double value,
          ) {
            _model.updateWeights(transit: value.round());
          }),
          Wrap(
            spacing: 12,
            children: <Widget>[
              FilledButton(
                onPressed:
                    _model.weightsLoaded && _model.preview && !_model.saving
                    ? _model.saveWeights
                    : null,
                child: Text(
                  _model.saving
                      ? _t('保存中', 'Saving')
                      : _t('保存权重', 'Save priorities'),
                ),
              ),
              TextButton(
                onPressed: _model.preview && !_model.saving
                    ? _model.restoreWeights
                    : null,
                child: Text(_t('恢复已保存', 'Restore saved')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, int value, ValueChanged<double> changed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label · $value'),
        Semantics(
          label: label,
          child: Slider(
            key: ValueKey<String>(label),
            min: 1,
            max: 10,
            divisions: 9,
            value: value.toDouble(),
            label: '$value',
            onChanged: _model.weightsLoaded && !_model.saving ? changed : null,
          ),
        ),
      ],
    );
  }
}
