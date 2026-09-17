import 'package:flutter/material.dart';
import 'infrastructure_view_model.dart';
import '../domain/infrastructure_models.dart';
import 'package:locatemy/features/map_location/map_location.dart';

final class InfrastructureCoveragePage extends StatefulWidget {
  final ValidLocationReference location;
  final DateTime analysisDate;
  const InfrastructureCoveragePage({required this.location, required this.analysisDate, super.key});

  @override
  State<InfrastructureCoveragePage> createState() => _InfrastructureCoveragePageState();
}

final class _InfrastructureCoveragePageState extends State<InfrastructureCoveragePage> {
  late InfrastructureViewModel _model;

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';
  String _t(String zh, String en) => _zh ? zh : en;

  @override
  void initState() {
    super.initState();
    _model = InfrastructureViewModel(location: widget.location, analysisDate: widget.analysisDate);
    _model.load();
  }

  @override
  void didUpdateWidget(covariant InfrastructureCoveragePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location || oldWidget.analysisDate != widget.analysisDate) {
      _model.changeLocation(widget.location, widget.analysisDate);
      _model.load();
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
                        child: Text(_t('基础设施覆盖', 'Infrastructure coverage'), style: _style(20, FontWeight.w700)),
                      ),
                      TextButton(
                        onPressed: _model.loading ? null : () => _model.load(InfrastructureLoadPolicy.refresh),
                        child: Text(_t('刷新', 'Refresh')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(widget.location.displayName ?? _t('所选地点', 'Selected location'), style: _style(20, FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${_t('固定半径 1.5 公里 · 分析日', 'Fixed radius 1.5 km · Analysis date')} ${_date(_model.analysisDate)}', style: _style(13, FontWeight.w400, const Color(0xFF667085))),
                  const SizedBox(height: 18),
                  if (_model.loading)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Semantics(
                        label: _t('正在读取基础设施覆盖', 'Loading infrastructure coverage'),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (outcome is InfrastructureAvailable) ..._available(outcome.snapshot),
                  if (outcome is InfrastructurePartial) ..._partial(outcome.snapshot),
                  if (outcome is InfrastructureUnavailable) _notice(_service(outcome.reason)),
                  const SizedBox(height: 14),
                  Text(_t('基础设施覆盖读数为综合指标，仅表示记录覆盖，不代表服务质量。', 'Infrastructure coverage reading is an aggregate indicator representing recorded coverage only; it does not assess service quality.'), style: _style(12, FontWeight.w400, const Color(0xFF667085))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _available(InfrastructureCoverage snapshot) {
    final int? score = snapshot.score;
    return <Widget>[
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF0B1F44), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(_t('综合基础设施覆盖', 'Infrastructure coverage score'), style: _style(14, FontWeight.w600, const Color(0xFFB9C9E8))),
          const SizedBox(height: 4),
          if (score != null)
            Semantics(
              label: _t(
                '基础设施覆盖读数 ${score}，满分 100',
                'Infrastructure coverage score ${score} out of 100',
              ),
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: <Widget>[
                Text('$score', style: _style(34, FontWeight.w700, Colors.white)),
                Text('/ 100', style: _style(14, FontWeight.w600, const Color(0xFFCFD9EB))),
              ]),
            )
          else
            Text(_t('分数不可用', 'Score unavailable'), style: _style(18, FontWeight.w700, Colors.white)),
        ]),
      ),
    ];
  }

  List<Widget> _partial(InfrastructureCoverage snapshot) {
    return <Widget>[
      _notice(_t('资料不完整，无法生成完整覆盖分数。', 'Data is incomplete; a complete coverage score is unavailable.')),
      const SizedBox(height: 8),
    ];
  }

  Widget _notice(String text) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD9E0EA))), child: Text(text, style: _style(14, FontWeight.w600)));
  }

  String _service(String reason) {
    return _t('暂无可用基础设施资料。', 'Infrastructure data unavailable.') + ' ' + reason;
  }

  TextStyle _style(double size, FontWeight weight, [Color colour = const Color(0xFF172033)]) {
    return TextStyle(fontFamily: 'SourceSansPro', fontSize: size, fontWeight: weight, color: colour);
  }

  String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
}
