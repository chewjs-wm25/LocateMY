// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';

import '../../../authentication_session/authentication_session.dart';
import '../../../cost_of_living_budget/cost_of_living_budget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/language_controller.dart';

/// Account actions use the same online services as location analysis.
final class AccountCenterPage extends StatelessWidget {
  final AuthenticationViewModel authentication;
  final CurrentBudgetReader? currentBudget;
  final BudgetScenarioStore? budgetStore;
  final VoidCallback onMyHazards;
  final VoidCallback? onPropertyPortfolio;

  const AccountCenterPage({
    required AuthenticationViewModel authentication,
    required VoidCallback onMyHazards,
    CurrentBudgetReader? currentBudget,
    BudgetScenarioStore? budgetStore,
    VoidCallback? onPropertyPortfolio,
    super.key,
  }) : authentication = authentication,
       onMyHazards = onMyHazards,
       currentBudget = currentBudget,
       budgetStore = budgetStore,
       onPropertyPortfolio = onPropertyPortfolio;

  Future<void> _signOut(BuildContext context) async {
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(strings.confirmSignOut),
          content: Text(strings.confirmSignOutBody),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(strings.signOut),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await authentication.signOut();
    }
  }

  String _failureMessage(AppLocalizations strings) {
    switch (authentication.state.messageKey) {
      case 'sign_out_remote_rejected':
        return strings.signOutRemoteRejected;
      case 'sign_out_unsupported_client':
        return strings.signOutUnsupportedClient;
      default:
        return strings.signOutRetryableUnavailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authentication,
      builder: (BuildContext context, Widget? child) {
        final SessionSnapshot? session = authentication.state.session;
        if (session is! AuthenticatedSession) {
          return const SizedBox.shrink();
        }
        final AppLocalizations strings = AppLocalizations.of(context)!;
        final bool busy = authentication.state.isSigningOut;
        return CostBudgetAccountPanel(
          reader: currentBudget,
          store: budgetStore,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.account_circle_outlined, size: 64),
              const SizedBox(height: 16),
              Text(session.account.email, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (onPropertyPortfolio != null)
                OutlinedButton.icon(
                  key: const ValueKey<String>('account-property-portfolio'),
                  onPressed: busy ? null : onPropertyPortfolio,
                  icon: const Icon(Icons.home_work_outlined),
                  label: Text(
                    budgetText(context, 'Property inspections', '房产实勘'),
                  ),
                ),
              OutlinedButton.icon(
                key: const ValueKey<String>('account-my-hazards'),
                onPressed: busy ? null : onMyHazards,
                icon: const Icon(Icons.report_outlined),
                label: Text(budgetText(context, 'My reported hazards', '我的隐患')),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: LanguageButton(),
              ),
              if (authentication.state.messageKey != null &&
                  authentication.state.messageKey!.startsWith('sign_out_'))
                Semantics(
                  liveRegion: true,
                  child: Text(_failureMessage(strings)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy
                    ? null
                    : () {
                        _signOut(context);
                      },
                child: Text(busy ? strings.signingOut : strings.signOutDevice),
              ),
            ],
          ),
        );
      },
    );
  }
}
