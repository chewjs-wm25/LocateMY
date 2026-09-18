// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';

import '../../cost_of_living_budget.dart';

final class CostBudgetAccountPanel extends StatefulWidget {
  final CurrentBudgetReader? reader;
  final BudgetScenarioStore? store;
  final Widget child;
  const CostBudgetAccountPanel({
    CurrentBudgetReader? reader,
    BudgetScenarioStore? store,
    required Widget child,
    super.key,
  }) : reader = reader,
       store = store,
       child = child;
  @override
  State<CostBudgetAccountPanel> createState() {
    return _CostBudgetAccountPanelState();
  }
}

final class _CostBudgetAccountPanelState extends State<CostBudgetAccountPanel> {
  late Stream<BudgetScenariosOutcome>? _current = widget.reader?.watchCurrent();
  @override
  void didUpdateWidget(CostBudgetAccountPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reader != widget.reader) {
      _current = widget.reader?.watchCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            widget.child,
            if (widget.reader != null && widget.store != null)
              StreamBuilder<BudgetScenariosOutcome>(
                stream: _current,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<BudgetScenariosOutcome> snapshot,
                    ) {
                      String name = budgetText(
                        context,
                        'Loading current scenario…',
                        '正在读取当前预案…',
                      );
                      BudgetScenario? scenario;
                      final BudgetScenariosOutcome? outcome = snapshot.data;
                      if (snapshot.hasError ||
                          outcome is BudgetScenariosUnavailable) {
                        name = budgetText(
                          context,
                          'Unable to read current scenario',
                          '暂无法读取当前预案',
                        );
                      } else if (outcome is BudgetScenariosAvailable) {
                        final CurrentBudgetScenarioSnapshot current =
                            outcome.current;
                        if (current is CurrentBudgetScenarioAvailable) {
                          scenario = current.scenario;
                          name = scenario.name;
                        } else {
                          name = budgetText(
                            context,
                            'No current scenario',
                            '没有当前评估预案',
                          );
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 24),
                          OutlinedButton(
                            key: const ValueKey<String>(
                              'account-current-budget',
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (BuildContext context) {
                                    return BudgetScenariosPage(
                                      store: widget.store!,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Text(
                              '${budgetText(context, 'Current assessment scenario', '当前评估预案')}: $name',
                            ),
                          ),
                          if (scenario != null) ...<Widget>[
                            _amount(
                              context,
                              'Additional living expense',
                              '额外生活开销',
                              scenario.additionalLivingExpenseRm,
                            ),
                            _amount(
                              context,
                              'Housing expense',
                              '住房支出',
                              scenario.housingExpenseRm,
                            ),
                            _amount(
                              context,
                              'Transport expense',
                              '交通支出',
                              scenario.transportExpenseRm,
                            ),
                            _amount(
                              context,
                              'Monthly net income',
                              '月净收入',
                              scenario.monthlyNetIncomeRm,
                            ),
                            _amount(
                              context,
                              'Household monthly income',
                              '家庭月度总收入',
                              scenario.householdMonthlyIncomeRm,
                            ),
                          ],
                        ],
                      );
                    },
              ),
          ],
        ),
      ),
    );
  }

  Widget _amount(BuildContext context, String en, String zh, double? amount) {
    String value = budgetText(context, 'Not provided', '未填写');
    if (amount != null) {
      value =
          'RM ${amount.toStringAsFixed(2)} / ${budgetText(context, 'month', '月')}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text('${budgetText(context, en, zh)}: $value'),
    );
  }
}
