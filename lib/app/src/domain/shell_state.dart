import 'package:locatemy/app/application_shell.dart';

import 'shell_routes.dart';

import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

enum ShellGate { restoring, authentication, opening, opened, recovery, closing }

enum ShellTab { home, map }

final class ShellState {
  final ShellGate gate;
  final AuthenticatedAccount? account;
  final AccountScope? scope;
  final SessionSnapshot? session;
  final AccountScopeFailure? openFailure;
  final SignOutFailure? signOutFailure;
  final CloseAccountScopeOutcome? closeOutcome;
  final ShellTab selectedTab;
  final List<ShellNavigationEntry> routes;
  final Map<String, ShellContribution> slots;
  const ShellState({
    required this.gate,
    this.account,
    this.scope,
    this.session,
    this.openFailure,
    this.signOutFailure,
    this.closeOutcome,
    this.selectedTab = ShellTab.home,
    this.routes = const [],
    this.slots = const {},
  });
}
