

import 'package:flutter/material.dart';

import 'cost_visual_style.dart';

import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/l10n/language_controller.dart';

import '../../cost_of_living_budget.dart';
import 'cost_view_model.dart';

final class CostBudgetPage extends StatefulWidget {
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  final CostOfLivingBudget service;
  final BudgetScenarioStore? budgetStore;
  final CurrentBudgetReader? currentBudget;
  final Object? returnContext;
  const CostBudgetPage({
    required ValidLocationReference location,
    required CostOfLivingBudget service,
    ValidLocationReference? locationB,
    BudgetScenarioStore? budgetStore,
    CurrentBudgetReader? currentBudget,
    Object? returnContext,
    super.key,
  }) : location = location,
       service = service,
       locationB = locationB,
       budgetStore = budgetStore,
       currentBudget = currentBudget,
       returnContext = returnContext;
  @override
  State<CostBudgetPage> createState() {
    return _CostBudgetPageState();
  }
}

final class _CostBudgetPageState extends State<CostBudgetPage> {
  late final CostViewModel _model = CostViewModel(
    service: widget.service,
    location: widget.location,
    locationB: widget.locationB,
    budget: widget.currentBudget,
  );
  @override
  void initState() {
    super.initState();
    _model.load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _t(String en, String zh) {
    if (Localizations.localeOf(context).languageCode == 'zh') {
      return zh;
    }
    return en;
  }

  String _rm(double? value) {
    if (value == null) {
      return _t('Unavailable', '暂无资料');
    }
    return 'RM ${value.toStringAsFixed(2)}';
  }

  Future<void> _budgets() async {
    if (widget.budgetStore == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return BudgetScenariosPage(store: widget.budgetStore!);
        },
      ),
    );
    if (mounted) {
      _model.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CostVisualStyle.canvas,
      appBar: AppBar(
        backgroundColor: CostVisualStyle.canvas,
        title: Text(
          _t('Cost of living', '生活成本'),
          style: CostVisualStyle.text(20, weight: FontWeight.w700),
        ),
        actions: <Widget>[
          if (widget.budgetStore != null)
            TextButton(onPressed: _budgets, child: Text(_t('Budgets', '预案'))),
          const LanguageButton(),
        ],
      ),
      body: ListenableBuilder(
        listenable: _model,
        builder: (BuildContext context, Widget? child) {
          if (_model.loading &&
              _model.outcome == null &&
              _model.comparison == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Widget> reports = <Widget>[];
          if (widget.locationB == null) {
            final CostAnalysisOutcome? result = _model.outcome;
            if (result is CostAnalysisAvailable) {
              reports.add(_report(result.analysis));
            }
            if (result is CostAnalysisPartial) {
              reports.add(_report(result.analysis));
            }
          } else {
            final CostComparisonOutcome? result = _model.comparison;
            CostComparison? comparison;
            if (result is CostComparisonAvailable) {
              comparison = result.comparison;
            }
            if (result is CostComparisonPartial) {
              comparison = result.comparison;
            }
            if (comparison != null) {
              if (!comparison.comparable) {
                reports.add(
                  Text(
                    _t(
                      'Locations are not comparable: incomplete basket or different data dates.',
                      '两地点不可比较：篮子资料不完整或统计日期不同。',
                    ),
                    style: CostVisualStyle.text(15),
                  ),
                );
              }
              reports.add(_report(comparison.analysisA));
              reports.add(const SizedBox(height: 20));
              reports.add(_report(comparison.analysisB));
              if (comparison.comparable) {
                reports.add(
                  Text(
                    '${_t('Monthly basket difference', '每月篮子差额')}: ${_rm(comparison.analysisB.observedSpend12! - comparison.analysisA.observedSpend12!)}',
                  ),
                );
              }
            }
          }
          if (reports.isEmpty) {
            reports.add(
              Text(
                _t('Unable to load cost data. Please retry.', '暂无法读取生活成本，请重试。'),
                style: CostVisualStyle.text(16),
              ),
            );
          }
          reports.add(const SizedBox(height: 16));
          reports.add(
            OutlinedButton(
              onPressed: () {
                _model.load(refresh: true);
              },
              child: Text(_t('Retry / refresh', '重试 / 刷新')),
            ),
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: reports,
            ),
          );
        },
      ),
    );
  }

  Widget _card(List<Widget> children, {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: color == Colors.white
            ? Border.all(color: CostVisualStyle.border)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _report(CostAnalysis a) {
    final String observedItems =
        '${_t('Observed items', '可观测项目')} ${a.indexedItemCount} / 11';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          a.location.displayName ?? _t('Selected location', '选定地点'),
          style: CostVisualStyle.text(20, weight: FontWeight.w700),
        ),
        Text(
          '${a.district?.name ?? ''} · ${_t('Single adult estimate', '单身成年人估算')}',
          style: CostVisualStyle.text(14, color: CostVisualStyle.muted),
        ),
        const SizedBox(height: 16),
        _card(<Widget>[
          Text(
            a.isPartialBasket
                ? _t('Partial basket index', '部分篮子指数')
                : _t('Cost index', '生活成本指数'),
            style: CostVisualStyle.text(14, color: CostVisualStyle.muted),
          ),
          Text(
            a.costIndex?.toStringAsFixed(1) ?? _t('Unavailable', '不可计算'),
            style: CostVisualStyle.text(40, weight: FontWeight.w700),
          ),
          Text(
            a.isPartialBasket
                ? _t(
                    'Matched observed-item national baseline = 100',
                    '同组可观测项目全国基准 = 100',
                  )
                : _t('Fixed national baseline = 100', '固定全国基准 = 100'),
            style: CostVisualStyle.text(13, color: CostVisualStyle.muted),
          ),
        ]),
        const SizedBox(height: 16),
        _card(<Widget>[
          Text(
            a.isPartialBasket
                ? _t('Partial goods basket reference amount', '部分商品篮子参考金额')
                : _t('Fixed goods basket reference amount', '固定商品篮子参考金额'),
            style: CostVisualStyle.text(14, color: CostVisualStyle.heroLabel),
          ),
          Text(
            '${_rm(a.observedSpend12)} ${_t('/month', '/月')}',
            style: CostVisualStyle.text(
              30,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
          Text(
            '$observedItems · ${a.availableMonths} ${_t('months', '个月')}',
            style: CostVisualStyle.text(13, color: CostVisualStyle.heroUnit),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'Estimated costs for a fixed goods list only; not a complete monthly living budget.',
              '仅估算固定清单中的商品费用，不代表完整月生活费。',
            ),
            style: CostVisualStyle.text(14, color: CostVisualStyle.heroUnit),
          ),
          if (a.isPartialBasket)
            Text(
              _t('Items without price data are excluded.', '缺少价格的商品未计入。'),
              style: CostVisualStyle.text(14, color: Colors.white),
            ),
        ], color: CostVisualStyle.hero),
        const SizedBox(height: 20),
        Text(
          _t('Main components', '主要分项'),
          style: CostVisualStyle.text(19, weight: FontWeight.w700),
        ),
        Text(
          _t(
            'Official observations · fixed model quantities · user budget inputs',
            '官方观测 · 固定模型数量 · 用户预算输入',
          ),
          style: CostVisualStyle.text(13, color: CostVisualStyle.muted),
        ),
        const SizedBox(height: 12),
        _card(<Widget>[
          Text(
            '${_t('Including current scenario', '包含当前预案')}: ${_rm(a.scenarioSpend12)} ${_t('/month', '/月')}',
          ),
          const SizedBox(height: 8),
          Text(
            '${a.isPartialBasket ? _t('Partial basket personal budget pressure', '部分篮子个人预算压力') : _t('Personal budget pressure', '个人预算压力')}: ${a.personalBudgetBurden?.toStringAsFixed(1) ?? '—'}%',
          ),
          Text(
            '${a.isPartialBasket ? _t('Partial basket district income pressure', '部分篮子行政区收入压力') : _t('District household income baseline', '行政区家庭收入基线')}: ${a.locationBudgetBurden?.toStringAsFixed(1) ?? '—'}%',
          ),
          if (a.personalBudgetBurden == null)
            Text(
              _t(
                'Choose a saved scenario with housing, transport and positive monthly net income.',
                '请选择已保存且填写住房、交通及正月净收入的预案。',
              ),
            ),
          if (widget.budgetStore != null)
            TextButton(
              onPressed: _budgets,
              child: Text(_t('Manage budget scenarios', '管理预算预案')),
            ),
        ], color: const Color(0xFFEAF2FF)),
      ],
    );
  }
}
