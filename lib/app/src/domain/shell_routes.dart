import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';

import 'shell_state.dart';

/// Root-owned opaque request identity; no Feature data belongs here.
final class ShellRequestContext {
  final AccountScope scope;
  ShellRequestContext(this.scope);
}

/// Root bindings project Feature markers without changing their payload.
final class ShellRouteRequest {
  final ShellRequestContext? context;
  final String? destination;
  final ShellTab? tab;
  final ShellRejectionReason? rejection;
  const ShellRouteRequest.task({
    required this.context,
    required this.destination,
  }) : tab = null,
       rejection = null;
  const ShellRouteRequest.tab({required this.context, required this.tab})
    : destination = null,
      rejection = null;
  const ShellRouteRequest.rejected(this.rejection)
    : context = null,
      destination = null,
      tab = null;
}

final class ShellIntentBinding<T extends ShellIntent> {
  final ShellRouteRequest Function(T) _decode;
  const ShellIntentBinding(this._decode);
  bool matches(ShellIntent intent) => intent is T;
  ShellRouteRequest decode(ShellIntent intent) => _decode(intent as T);
}

final class ShellNavigationEntry {
  final String destination;
  final ShellIntent? intent;
  final ShellRequestContext context;
  const ShellNavigationEntry(this.destination, this.intent, this.context);
}

final class ShellSlotRequest {
  final ShellRequestContext? context;
  final String? slot;
  final ShellRejectionReason? rejection;
  const ShellSlotRequest({required this.context, required this.slot})
    : rejection = null;
  const ShellSlotRequest.rejected(this.rejection) : context = null, slot = null;
}

final class ShellContributionBinding<T extends ShellContribution> {
  final ShellSlotRequest Function(T) _decode;
  const ShellContributionBinding(this._decode);
  bool matches(ShellContribution input) => input is T;
  ShellSlotRequest decode(ShellContribution input) => _decode(input as T);
}
