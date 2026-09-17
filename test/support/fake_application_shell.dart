import 'dart:collection';

import 'package:locatemy/app/application_shell.dart';

/// Consumer-only fake. Production Features receive a scope-bound SHELL-001.
final class FakeApplicationShell implements ApplicationShell {
  final Queue<ShellIntentOutcome> intents;
  final Queue<ShellContributionOutcome> contributions;
  FakeApplicationShell({
    Iterable<ShellIntentOutcome> intents = const [],
    Iterable<ShellContributionOutcome> contributions = const [],
  }) : intents = Queue.of(intents),
       contributions = Queue.of(contributions);
  @override
  Future<ShellIntentOutcome> submit(ShellIntent intent) async =>
      intents.removeFirst();
  @override
  Future<ShellContributionOutcome> publish(
    ShellContribution contribution,
  ) async => contributions.removeFirst();
}
