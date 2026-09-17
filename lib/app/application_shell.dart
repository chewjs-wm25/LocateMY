/// SHELL-001: the only interface consumed by Features.
abstract interface class ApplicationShell {
  Future<ShellIntentOutcome> submit(ShellIntent intent);
  Future<ShellContributionOutcome> publish(ShellContribution contribution);
}

abstract interface class ShellIntent {}

abstract interface class ShellContribution {}

sealed class ShellIntentOutcome {
  const ShellIntentOutcome();
}

final class ShellIntentAccepted extends ShellIntentOutcome {}

final class ShellAuthenticationRequired extends ShellIntentOutcome {}

final class ShellIntentRejected extends ShellIntentOutcome {
  const ShellIntentRejected(this.reason);
  final ShellRejectionReason reason;
}

sealed class ShellContributionOutcome {
  const ShellContributionOutcome();
}

final class ShellContributionAccepted extends ShellContributionOutcome {}

final class ShellContributionAuthenticationRequired
    extends ShellContributionOutcome {}

final class ShellContributionRejected extends ShellContributionOutcome {
  const ShellContributionRejected(this.reason);
  final ShellRejectionReason reason;
}

enum ShellRejectionReason {
  missingInput,
  staleInput,
  inapplicableDestination,
  scopeUnavailable,
}
