import 'dart:async';

import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../domain/shell_state.dart';
import '../domain/shell_routes.dart';

/// Process-scoped application use case. Features receive only ApplicationShell.
final class ShellRuntime
    implements ApplicationShell, AccountPrivacyParticipant {
  final AuthenticationSession authentication;
  final AccountPrivacy Function() _privacy;
  AccountPrivacy get privacy => _privacy();
  ShellState _state = const ShellState(gate: ShellGate.restoring);
  ShellState get state => _state;
  ApplicationShell? get applicationShell =>
      _authorized ? _ScopedShell(this, state.scope!) : null;
  final _changes = StreamController<ShellState>.broadcast();
  Stream<ShellState> get changes => _changes.stream;
  StreamSubscription<SessionSnapshot>? _subscription;
  Future<void>? _initialization;
  Future<void>? _opening;
  String? _openingAccountId;
  Future<void>? _cleanup;
  AccountScope? _oldScope;
  AccountScopeCloseReason _closeReason = AccountScopeCloseReason.signOut;
  int _revision = 0;
  bool _disposed = false;
  bool _exitPending = false;

  final List<ShellIntentBinding> _intents;
  final List<ShellContributionBinding> _contributions;
  final Map<ShellRequestContext, Map<String, ShellContribution>> _slots = {};
  final Map<ShellTab, ShellRequestContext> _tabContexts = {};
  ShellRequestContext? get currentContext => state.gate != ShellGate.opened
      ? null
      : state.routes.isNotEmpty
      ? state.routes.last.context
      : _tabContexts[state.selectedTab];
  ShellRuntime({
    required this.authentication,
    required AccountPrivacy privacy,
    List<ShellIntentBinding> intents = const [],
    List<ShellContributionBinding> contributions = const [],
  }) : _privacy = (() => privacy),
       _intents = List.unmodifiable(intents),
       _contributions = List.unmodifiable(contributions);

  // Resolves the Privacy/Shell participant registration cycle in the root.
  ShellRuntime.compose({
    required this.authentication,
    required AccountPrivacy Function() privacy,
    List<ShellIntentBinding> intents = const [],
    List<ShellContributionBinding> contributions = const [],
  }) : _privacy = (() => privacy()),
       _intents = List.unmodifiable(intents),
       _contributions = List.unmodifiable(contributions);

  void _emit(ShellState value) {
    if (_disposed) return;
    _state = value;
    _changes.add(value);
  }

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    _subscription = authentication.watchSession().listen(
      (fact) {
        _accept(fact);
      },
      onError: (Object _) {
        _accept(const SessionUnavailable(SessionFailure.retryableUnavailable));
      },
      onDone: () {
        _accept(const SessionUnavailable(SessionFailure.retryableUnavailable));
      },
    );
    await retry();
    // A watch fact can supersede restore while its same-account open is pending.
    await _opening;
    await _cleanup;
  }

  Future<void> retry() async {
    if (_disposed) return;
    if (_exitPending ||
        _oldScope != null ||
        privacy.readScope() is AccountScopeClosing) {
      if (_oldScope == null && privacy.readScope() is AccountScopeClosing) {
        _oldScope = (privacy.readScope() as AccountScopeClosing).scope;
      }
      await signOut(reason: _closeReason);
      return;
    }
    if (_cleanup != null) return _cleanup;
    if (_opening != null) return _opening;
    final revision = ++_revision;
    _emit(const ShellState(gate: ShellGate.restoring));
    SessionSnapshot fact;
    try {
      fact = await authentication.restoreSession();
    } catch (_) {
      fact = const SessionUnavailable(SessionFailure.retryableUnavailable);
    }
    if (!_disposed && revision == _revision) await _accept(fact);
  }

  Future<void> _accept(SessionSnapshot fact) async {
    if (_disposed) return;
    if (_exitPending || _oldScope != null || _cleanup != null) return;
    if (_opening != null &&
        fact is AuthenticatedSession &&
        fact.account.accountId == _openingAccountId &&
        fact.account.confirmation == EmailConfirmation.confirmed) {
      return;
    }
    final revision = ++_revision;
    final opened = _state.scope;
    final id =
        fact is AuthenticatedSession &&
            fact.account.confirmation == EmailConfirmation.confirmed
        ? fact.account.accountId
        : null;
    if (opened != null && _state.gate == ShellGate.opened) {
      final current = privacy.readScope();
      if (id == opened.accountId &&
          current is AccountScopeOpened &&
          identical(current.scope, opened)) {
        _navigation(account: (fact as AuthenticatedSession).account);
        return;
      }
      _oldScope = opened;
      await signOut(
        reason: id != null && id != opened.accountId
            ? AccountScopeCloseReason.accountSwitch
            : AccountScopeCloseReason.sessionInvalidated,
      );
      return;
    }
    if (privacy.readScope() case AccountScopeClosing(:final scope)) {
      _oldScope = scope;
      await signOut(reason: AccountScopeCloseReason.sessionInvalidated);
      return;
    }
    if (_opening != null) {
      // A late open must settle and be closed before any new identity can open.
      _emit(const ShellState(gate: ShellGate.restoring));
      return;
    }
    if (id == null || id.trim().isEmpty) {
      _emit(
        ShellState(
          gate: fact is SessionUnavailable
              ? ShellGate.recovery
              : ShellGate.authentication,
          session: fact,
        ),
      );
      return;
    }
    _emit(const ShellState(gate: ShellGate.opening));
    _openingAccountId = id;
    final work = _open((fact as AuthenticatedSession).account, revision);
    _opening = work;
    try {
      await work;
    } finally {
      if (identical(_opening, work)) {
        _opening = null;
        _openingAccountId = null;
      }
    }
  }

  Future<void> _open(AuthenticatedAccount account, int revision) async {
    OpenAccountScopeOutcome result;
    try {
      result = await privacy.open(account);
    } catch (_) {
      result = const AccountScopeOpenRejected(
        AccountScopeFailure.retryableUnavailable,
      );
    }
    if (_disposed) return;
    if (result is AccountScopeOpenedForAccount) {
      final snapshot = privacy.readScope();
      if (revision == _revision &&
          result.scope.accountId == account.accountId &&
          snapshot is AccountScopeOpened &&
          identical(snapshot.scope, result.scope)) {
        for (final tab in ShellTab.values) {
          _tabContexts[tab] = ShellRequestContext(result.scope);
        }
        _emit(
          ShellState(
            gate: ShellGate.opened,
            account: account,
            scope: result.scope,
          ),
        );
      } else {
        _oldScope = result.scope;
        if (revision != _revision) {
          if (_cleanup == null) {
            // Finish open before close begins; never await our own open future.
            scheduleMicrotask(() {
              signOut(reason: AccountScopeCloseReason.sessionInvalidated);
            });
          }
        } else {
          _emit(
            const ShellState(
              gate: ShellGate.recovery,
              openFailure: AccountScopeFailure.identityMismatch,
            ),
          );
        }
      }
    } else {
      if (privacy.readScope() case AccountScopeClosing(:final scope)) {
        _oldScope = scope;
      }
      _emit(
        ShellState(
          gate: ShellGate.recovery,
          openFailure: (result as AccountScopeOpenRejected).failure,
        ),
      );
    }
  }

  Future<void> signOut({
    AccountScopeCloseReason reason = AccountScopeCloseReason.signOut,
  }) {
    if (_disposed) return Future.value();
    if (_cleanup != null) return _cleanup!;
    ++_revision;
    _oldScope ??= _state.scope;
    if (_oldScope == null) {
      if (privacy.readScope() case AccountScopeClosing(:final scope)) {
        _oldScope = scope;
      }
    }
    _closeReason = reason;
    _exitPending = true;
    _slots.clear();
    _tabContexts.clear();
    _emit(const ShellState(gate: ShellGate.closing));
    final completion = Completer<void>();
    _cleanup = completion.future;
    Future<void>.microtask(_endSessionAndClose).then(
      (_) {
        _cleanup = null;
        completion.complete();
      },
      onError: (Object error, StackTrace trace) {
        _cleanup = null;
        _emit(const ShellState(gate: ShellGate.recovery));
        completion.complete();
      },
    );
    return completion.future;
  }

  Future<void> _endSessionAndClose() async {
    SignOutOutcome exit;
    try {
      exit = await authentication.signOut();
    } catch (_) {
      exit = const SignOutRejected(SignOutFailure.retryableUnavailable);
    }
    // Settle any pending authorization before closing its immutable old scope.
    await _opening;
    // Both operations are required, even when the Auth request fails.
    final scope = _oldScope;
    CloseAccountScopeOutcome? close;
    if (scope != null) {
      try {
        close = await privacy.close(scope, _closeReason);
      } catch (_) {
        close = AccountScopeCloseRejected(
          scope,
          AccountScopeFailure.retryableUnavailable,
        );
      }
    }
    if (_disposed) return;
    if (exit is SignOutSucceeded &&
        (scope == null ||
            close is AccountScopeClosedForAccount &&
                identical(close.scope, scope))) {
      _oldScope = null;
      _exitPending = false;
      _emit(
        const ShellState(
          gate: ShellGate.authentication,
          session: UnauthenticatedSession(),
        ),
      );
    } else {
      _emit(
        ShellState(
          gate: ShellGate.recovery,
          signOutFailure: exit is SignOutRejected ? exit.failure : null,
          closeOutcome: close,
        ),
      );
    }
  }

  bool get _authorized {
    final current = privacy.readScope();
    return !_disposed &&
        state.gate == ShellGate.opened &&
        current is AccountScopeOpened &&
        identical(current.scope, state.scope);
  }

  void _navigation({
    ShellTab? tab,
    List<ShellNavigationEntry>? routes,
    AuthenticatedAccount? account,
  }) {
    final nextRoutes = routes ?? state.routes;
    final nextTab = tab ?? state.selectedTab;
    final context = nextRoutes.isEmpty
        ? _tabContexts[nextTab]
        : nextRoutes.last.context;
    _emit(
      ShellState(
        gate: ShellGate.opened,
        account: account ?? state.account,
        scope: state.scope,
        selectedTab: nextTab,
        routes: List.unmodifiable(nextRoutes),
        slots: Map.unmodifiable(_slots[context] ?? {}),
      ),
    );
  }

  void selectTab(ShellTab tab) {
    if (_authorized && state.routes.isEmpty) _navigation(tab: tab);
  }

  void back() {
    if (!_authorized || state.routes.isEmpty) return;
    _slots.remove(state.routes.last.context);
    _navigation(routes: state.routes.sublist(0, state.routes.length - 1));
  }

  void openAccountTask() {
    if (!_authorized) return;
    _navigation(
      routes: [
        ...state.routes,
        ShellNavigationEntry(
          'account',
          null,
          ShellRequestContext(state.scope!),
        ),
      ],
    );
  }

  @override
  Future<ShellIntentOutcome> submit(ShellIntent intent) async {
    if (!_authorized) return ShellAuthenticationRequired();
    final bindings = _intents
        .where((binding) => binding.matches(intent))
        .toList();
    if (bindings.length != 1) {
      return const ShellIntentRejected(
        ShellRejectionReason.inapplicableDestination,
      );
    }
    ShellRouteRequest request;
    try {
      request = bindings.single.decode(intent);
    } catch (_) {
      return const ShellIntentRejected(ShellRejectionReason.missingInput);
    }
    if (request.rejection != null) {
      return ShellIntentRejected(request.rejection!);
    }
    if (request.context == null) {
      return const ShellIntentRejected(ShellRejectionReason.missingInput);
    }
    if (!identical(request.context!.scope, state.scope)) {
      return const ShellIntentRejected(ShellRejectionReason.scopeUnavailable);
    }
    if (!identical(request.context, currentContext)) {
      return const ShellIntentRejected(ShellRejectionReason.staleInput);
    }
    if (request.tab != null) {
      _navigation(tab: request.tab, routes: const []);
    } else if (request.destination != null &&
        request.destination!.trim().isNotEmpty) {
      _navigation(
        routes: [
          ...state.routes,
          ShellNavigationEntry(
            request.destination!,
            intent,
            ShellRequestContext(state.scope!),
          ),
        ],
      );
    } else {
      return const ShellIntentRejected(
        ShellRejectionReason.inapplicableDestination,
      );
    }
    return ShellIntentAccepted();
  }

  ShellRequestContext? beginRequest() {
    if (!_authorized) return null;
    _slots.remove(currentContext);
    final context = ShellRequestContext(state.scope!);
    if (state.routes.isEmpty) {
      _tabContexts[state.selectedTab] = context;
      _navigation();
    } else {
      final last = state.routes.last;
      _navigation(
        routes: [
          ...state.routes.take(state.routes.length - 1),
          ShellNavigationEntry(last.destination, last.intent, context),
        ],
      );
    }
    return context;
  }

  @override
  Future<ShellContributionOutcome> publish(
    ShellContribution contribution,
  ) async {
    if (!_authorized) return ShellContributionAuthenticationRequired();
    final bindings = _contributions
        .where((binding) => binding.matches(contribution))
        .toList();
    if (bindings.length != 1) {
      return const ShellContributionRejected(
        ShellRejectionReason.inapplicableDestination,
      );
    }
    ShellSlotRequest request;
    try {
      request = bindings.single.decode(contribution);
    } catch (_) {
      return const ShellContributionRejected(ShellRejectionReason.missingInput);
    }
    if (request.rejection != null) {
      return ShellContributionRejected(request.rejection!);
    }
    if (request.context == null ||
        request.slot == null ||
        request.slot!.trim().isEmpty) {
      return const ShellContributionRejected(ShellRejectionReason.missingInput);
    }
    if (!identical(request.context!.scope, state.scope)) {
      return const ShellContributionRejected(
        ShellRejectionReason.scopeUnavailable,
      );
    }
    if (!identical(request.context, currentContext)) {
      return const ShellContributionRejected(ShellRejectionReason.staleInput);
    }
    (_slots[request.context!] ??= {})[request.slot!] = contribution;
    _navigation();
    return ShellContributionAccepted();
  }

  @override
  AccountPrivacyParticipantId get participantId =>
      AccountPrivacyParticipantId.applicationShell;
  @override
  Future<PrivateStateClearOutcome> clearPrivateState(AccountScope scope) async {
    if (!identical(scope, _oldScope) || state.gate == ShellGate.opened) {
      return PrivateStateClearIncomplete(
        participantId,
        scope,
        PrivateStateClearFailure.scopeUnavailable,
      );
    }
    return PrivateStateCleared(participantId, scope);
  }

  Future<void> dispose() async {
    _disposed = true;
    ++_revision;
    _slots.clear();
    _tabContexts.clear();
    _state = const ShellState(gate: ShellGate.restoring);
    await _subscription?.cancel();
    await _changes.close();
  }
}

/// Captured by each scope's Feature ViewModels, never a global replay channel.
final class _ScopedShell implements ApplicationShell {
  final ShellRuntime _runtime;
  final AccountScope _scope;
  const _ScopedShell(this._runtime, this._scope);
  bool get _current =>
      _runtime._authorized && identical(_runtime.state.scope, _scope);
  @override
  Future<ShellIntentOutcome> submit(ShellIntent intent) => _current
      ? _runtime.submit(intent)
      : Future.value(ShellAuthenticationRequired());
  @override
  Future<ShellContributionOutcome> publish(ShellContribution contribution) =>
      _current
      ? _runtime.publish(contribution)
      : Future.value(ShellContributionAuthenticationRequired());
}
