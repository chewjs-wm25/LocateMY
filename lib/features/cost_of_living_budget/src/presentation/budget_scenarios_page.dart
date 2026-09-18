import 'package:flutter/material.dart';

import 'cost_visual_style.dart';

import 'package:locatemy/l10n/language_controller.dart';

import '../../cost_of_living_budget.dart';
import 'budget_view_model.dart';

String budgetText(BuildContext context, String en, String zh) {
  if (Localizations.localeOf(context).languageCode == 'zh') {
    return zh;
  }
  return en;
}

final class BudgetScenariosPage extends StatefulWidget {
  final BudgetScenarioStore store;
  const BudgetScenariosPage({required BudgetScenarioStore store, super.key})
    : store = store;
  @override
  State<BudgetScenariosPage> createState() {
    return _BudgetScenariosPageState();
  }
}

final class _BudgetScenariosPageState extends State<BudgetScenariosPage> {
  late final BudgetViewModel _model = BudgetViewModel(widget.store);
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
    return budgetText(context, en, zh);
  }

  Future<void> _edit([BudgetScenario? scenario]) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return BudgetEditorPage(store: widget.store, scenario: scenario);
        },
      ),
    );
    if (saved == true) {
      _model.saved = true;
    }
    if (mounted) {
      _model.load();
    }
  }

  Future<void> _delete(BudgetScenario scenario) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return _BudgetDeleteDialog(scenario.name);
      },
    );
    if (confirmed == true && mounted) {
      await _model.mutate(() {
        return widget.store.delete(scenario.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CostVisualStyle.canvas,
      appBar: AppBar(
        title: Text(_t('Budget scenarios', '预算预案')),
        actions: const <Widget>[LanguageButton()],
      ),
      body: ListenableBuilder(
        listenable: _model,
        builder: (BuildContext context, Widget? child) {
          final List<Widget> children = <Widget>[
            FilledButton.icon(
              key: const ValueKey<String>('budget-add'),
              onPressed: _model.busy ? null : _edit,
              icon: const Icon(Icons.add),
              label: Text(_t('New scenario', '新增预案')),
            ),
            const SizedBox(height: 16),
          ];
          if (_model.loading) {
            children.add(const LinearProgressIndicator());
          }
          if (_model.failure != null ||
              _model.outcome is BudgetScenariosUnavailable) {
            children.add(
              Text(
                _t(
                  'Unable to save or read. Your saved selection is unchanged. Retry online.',
                  '暂无法保存或读取，已保存的选择保持不变，请联网重试。',
                ),
              ),
            );
          }
          if (_model.saved) {
            children.add(Text(_t('Saved successfully', '保存成功')));
          }
          final BudgetScenariosOutcome? outcome = _model.outcome;
          if (outcome is BudgetScenariosAvailable) {
            if (outcome.current is NoCurrentBudgetScenario) {
              children.add(
                Text(
                  _t(
                    'No current scenario. Choose one explicitly.',
                    '没有当前评估预案，请明确选择一份。',
                  ),
                ),
              );
            }
            if (outcome.scenarios.isEmpty) {
              children.add(Text(_t('No saved scenarios', '尚无已保存预案')));
            }
            for (final BudgetScenario scenario in outcome.scenarios) {
              children.add(
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CostVisualStyle.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        scenario.name,
                        style: CostVisualStyle.text(
                          20,
                          weight: FontWeight.w700,
                        ),
                      ),
                      if (scenario.isCurrent)
                        Text(
                          _t('Current assessment scenario', '当前评估预案'),
                          style: CostVisualStyle.text(
                            15,
                            color: CostVisualStyle.primary,
                          ),
                        ),
                      ...budgetAmountWidgets(context, scenario),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          TextButton(
                            key: ValueKey<String>(
                              'budget-select-${scenario.id}',
                            ),
                            onPressed: _model.busy || scenario.isCurrent
                                ? null
                                : () {
                                    _model.mutate(() {
                                      return widget.store.selectCurrent(
                                        scenario.id,
                                      );
                                    });
                                  },
                            child: Text(_t('Use current', '选为当前')),
                          ),
                          TextButton(
                            onPressed: _model.busy
                                ? null
                                : () {
                                    _edit(scenario);
                                  },
                            child: Text(_t('Edit / rename', '编辑 / 重命名')),
                          ),
                          TextButton(
                            onPressed: _model.busy
                                ? null
                                : () {
                                    _delete(scenario);
                                  },
                            child: Text(_t('Delete', '删除')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
          }
          children.add(
            OutlinedButton(
              onPressed: _model.busy ? null : _model.load,
              child: Text(_t('Retry / refresh', '重试 / 刷新')),
            ),
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
        },
      ),
    );
  }
}

List<Widget> budgetAmountWidgets(
  BuildContext context,
  BudgetScenario scenario,
) {
  final List<String> labels = <String>[
    budgetText(context, 'Extra living expenses', '额外生活开销'),
    budgetText(context, 'Housing', '住房支出'),
    budgetText(context, 'Transport', '交通支出'),
    budgetText(context, 'Monthly net income', '月净收入'),
    budgetText(context, 'Household monthly gross income', '家庭月度总收入'),
  ];
  final List<double?> values = <double?>[
    scenario.additionalLivingExpenseRm,
    scenario.housingExpenseRm,
    scenario.transportExpenseRm,
    scenario.monthlyNetIncomeRm,
    scenario.householdMonthlyIncomeRm,
  ];
  final List<Widget> result = <Widget>[];
  for (int i = 0; i < labels.length; i++) {
    String amount = budgetText(context, 'Not entered', '未填写');
    if (values[i] != null) {
      amount = 'RM ${values[i]!.toStringAsFixed(2)}';
    }
    result.add(
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('${labels[i]}: $amount', style: CostVisualStyle.text(15)),
      ),
    );
  }
  return result;
}

final class _BudgetDeleteDialog extends StatelessWidget {
  final String name;
  const _BudgetDeleteDialog(String name) : name = name;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(budgetText(context, 'Delete scenario?', '删除预案？')),
      content: Text(
        '$name\n${budgetText(context, 'Deleting current leaves no selection.', '删除当前预案后不会自动选择其他预案。')}',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(budgetText(context, 'Cancel', '取消')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(budgetText(context, 'Delete', '删除')),
        ),
      ],
    );
  }
}

final class BudgetEditorPage extends StatefulWidget {
  final BudgetScenarioStore store;
  final BudgetScenario? scenario;
  const BudgetEditorPage({
    required BudgetScenarioStore store,
    BudgetScenario? scenario,
    super.key,
  }) : store = store,
       scenario = scenario;
  @override
  State<BudgetEditorPage> createState() {
    return _BudgetEditorPageState();
  }
}

final class _BudgetEditorPageState extends State<BudgetEditorPage> {
  final List<TextEditingController> _fields = <TextEditingController>[];
  final List<FocusNode> _focus = <FocusNode>[];
  bool _busy = false;
  int? _invalid;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    final BudgetScenario? s = widget.scenario;
    final List<double?> values = <double?>[
      s?.additionalLivingExpenseRm,
      s?.housingExpenseRm,
      s?.transportExpenseRm,
      s?.monthlyNetIncomeRm,
      s?.householdMonthlyIncomeRm,
    ];
    _fields.add(TextEditingController(text: s?.name ?? ''));
    _focus.add(FocusNode());
    for (final double? value in values) {
      _fields.add(TextEditingController(text: value?.toString() ?? ''));
      _focus.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final TextEditingController field in _fields) {
      field.dispose();
    }
    for (final FocusNode node in _focus) {
      node.dispose();
    }
    super.dispose();
  }

  String _t(String en, String zh) {
    return budgetText(context, en, zh);
  }

  Future<void> _save() async {
    int? invalid;
    if (_fields[0].text.trim().isEmpty || _fields[0].text.trim().length > 120) {
      invalid = 0;
    }
    final List<double?> amounts = <double?>[];
    for (int i = 1; i < _fields.length; i++) {
      final String raw = _fields[i].text.trim();
      final double? amount = double.tryParse(raw);
      amounts.add(amount);
      if (raw.isNotEmpty &&
          (amount == null || !amount.isFinite || amount < 0)) {
        invalid ??= i;
      }
    }
    if (invalid != null) {
      setState(() {
        _invalid = invalid;
      });
      _focus[invalid].requestFocus();
      return;
    }
    setState(() {
      _busy = true;
      _invalid = null;
      _failed = false;
    });
    final BudgetScenarioDraft draft = BudgetScenarioDraft(
      name: _fields[0].text,
      additionalLivingExpenseRm: amounts[0],
      housingExpenseRm: amounts[1],
      transportExpenseRm: amounts[2],
      monthlyNetIncomeRm: amounts[3],
      householdMonthlyIncomeRm: amounts[4],
    );
    BudgetScenarioMutationOutcome result;
    if (widget.scenario == null) {
      result = await widget.store.create(draft);
    } else {
      result = await widget.store.update(
        BudgetScenarioUpdate(scenarioId: widget.scenario!.id, values: draft),
      );
    }
    if (!mounted) {
      return;
    }
    if (result is BudgetScenarioMutationSaved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      _t('Name', '名称'),
      _t('Extra living expenses (RM/month)', '额外生活开销 (RM/月)'),
      _t('Housing (RM/month)', '住房支出 (RM/月)'),
      _t('Transport (RM/month)', '交通支出 (RM/月)'),
      _t('Monthly net income (personal pressure)', '月净收入（个人压力）'),
      _t('Household monthly gross income (income position)', '家庭月度总收入（收入位置）'),
    ];
    final List<Widget> children = <Widget>[
      Text(
        _t(
          'Blank means not entered; zero is an explicit RM 0. Incomes have separate uses.',
          '留空表示未填写；零表示明确 RM 0。两项收入分别用于不同读数。',
        ),
      ),
    ];
    for (int i = 0; i < labels.length; i++) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: TextField(
            key: ValueKey<String>('budget-field-$i'),
            controller: _fields[i],
            focusNode: _focus[i],
            enabled: !_busy,
            keyboardType: i == 0
                ? TextInputType.text
                : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: labels[i],
              errorText: _invalid == i
                  ? (i == 0
                        ? _t('Enter 1–120 characters', '请输入 1–120 个字符')
                        : _t('Enter a finite nonnegative amount', '请输入有效的非负金额'))
                  : null,
            ),
          ),
        ),
      );
    }
    if (_failed) {
      children.add(Text(_t('Not saved. Retry online.', '尚未保存，请联网重试。')));
    }
    if (_busy) {
      children.add(const LinearProgressIndicator());
    }
    children.add(
      FilledButton(
        key: const ValueKey<String>('budget-save'),
        onPressed: _busy ? null : _save,
        child: Text(_t('Save online', '在线保存')),
      ),
    );
    return Scaffold(
      backgroundColor: CostVisualStyle.canvas,
      appBar: AppBar(
        title: Text(_t('Edit budget scenario', '编辑预算预案')),
        actions: const <Widget>[LanguageButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
