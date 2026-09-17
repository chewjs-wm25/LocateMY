// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';

import '../../cost_of_living_budget.dart';

final class CostBudgetAccountPanel extends StatelessWidget {
  final CurrentBudgetReader? reader;
  final BudgetScenarioStore? store;
  final BudgetJsonFiles? files;
  final Widget child;
  const CostBudgetAccountPanel({
    CurrentBudgetReader? reader,
    BudgetScenarioStore? store,
    BudgetJsonFiles? files,
    required Widget child,
    super.key,
  }) : reader = reader,
       store = store,
       files = files,
       child = child;
  @override
  Widget build(BuildContext context) {
    if (reader == null || store == null) {
      return child;
    }
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: child),
          SafeArea(
            top: false,
            child: StreamBuilder<BudgetScenariosOutcome>(
              stream: reader!.watchCurrent(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<BudgetScenariosOutcome> snapshot,
                  ) {
                    String name = budgetText(
                      context,
                      'No current scenario',
                      '没有当前评估预案',
                    );
                    final BudgetScenariosOutcome? outcome = snapshot.data;
                    if (outcome is BudgetScenariosUnavailable) {
                      name = budgetText(
                        context,
                        'Unable to read current scenario',
                        '暂无法读取当前预案',
                      );
                    }
                    if (outcome is BudgetScenariosAvailable &&
                        outcome.current is CurrentBudgetScenarioAvailable) {
                      name = (outcome.current as CurrentBudgetScenarioAvailable)
                          .scenario
                          .name;
                    }
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton(
                        key: const ValueKey<String>('account-current-budget'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) {
                                return BudgetScenariosPage(
                                  store: store!,
                                  files: files,
                                );
                              },
                            ),
                          );
                        },
                        child: Text(
                          '${budgetText(context, 'Current assessment scenario', '当前评估预案')}: $name',
                        ),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}
