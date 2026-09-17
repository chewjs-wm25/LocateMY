// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:locatemy/l10n/language_controller.dart';

import '../domain/shell_state.dart';
import 'shell_view_model.dart';

/// Only the root registers presentation of provider-owned markers.
final class ShellTaskView<T extends ShellIntent> {
  final String destination;
  final Widget Function(BuildContext, T) _build;
  const ShellTaskView(
    String destination,
    Widget Function(BuildContext, T) build,
  ) : destination = destination,
      _build = build;

  bool matches(String target, ShellIntent? input) {
    return target == destination && input is T;
  }

  Widget build(BuildContext context, ShellIntent input) {
    return _build(context, input as T);
  }
}

final class ShellContributionView<T extends ShellContribution> {
  final Widget Function(BuildContext, T) _build;
  const ShellContributionView(Widget Function(BuildContext, T) build)
    : _build = build;

  bool matches(ShellContribution input) {
    return input is T;
  }

  Widget build(BuildContext context, ShellContribution input) {
    return _build(context, input as T);
  }
}

final class ShellViews {
  final Widget Function(BuildContext, ApplicationShell)? home;
  final Widget Function(BuildContext, ApplicationShell)? map;
  final List<ShellTaskView> tasks;
  final List<ShellContributionView> contributions;
  const ShellViews({
    this.home,
    this.map,
    this.tasks = const [],
    this.contributions = const [],
  });
}

final class ShellHost extends StatelessWidget {
  final ShellViewModel viewModel;
  final Widget authentication;
  final ShellViews views;
  const ShellHost({
    required ShellViewModel viewModel,
    required Widget authentication,
    required ShellViews views,
    super.key,
  }) : viewModel = viewModel,
       authentication = authentication,
       views = views;

  @override
  Widget build(BuildContext context) {
    final ShellState state = viewModel.state;
    final AppLocalizations l = AppLocalizations.of(context)!;
    if (state.gate == ShellGate.authentication) {
      return authentication;
    }
    if (state.gate != ShellGate.opened) {
      final busy = state.gate != ShellGate.recovery;
      return Scaffold(
        appBar: AppBar(
          title: const Text('LocateMY'),
          actions: const [LanguageButton()],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(busy ? l.shellPreparing : l.shellRecovery),
                  ),
                  if (!busy) ...[
                    const SizedBox(height: 16),
                    if (state.signOutFailure != null)
                      Text(_signOutFailureMessage(state.signOutFailure!, l)),
                    if (state.closeOutcome is AccountScopeCloseIncomplete ||
                        state.closeOutcome is AccountScopeCloseRejected)
                      Text(l.shellCleanupPending)
                    else if (state.signOutFailure == null)
                      Text(
                        state.session is SessionUnavailable
                            ? l.sessionUnavailable
                            : l.shellScopeUnavailable,
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: viewModel.retry,
                      child: Text(l.retry),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    return _PrivateNavigation(
      key: ValueKey(state.scope),
      viewModel: viewModel,
      views: views,
    );
  }
}

String _signOutFailureMessage(
  SignOutFailure failure,
  AppLocalizations localizations,
) {
  switch (failure) {
    case SignOutFailure.retryableUnavailable:
      return localizations.signOutRetryableUnavailable;
    case SignOutFailure.remoteRejected:
      return localizations.signOutRemoteRejected;
    case SignOutFailure.unsupportedClient:
      return localizations.signOutUnsupportedClient;
  }
}

final class _PrivateNavigation extends StatefulWidget {
  final ShellViewModel viewModel;
  final ShellViews views;
  const _PrivateNavigation({
    required ShellViewModel viewModel,
    required ShellViews views,
    super.key,
  }) : viewModel = viewModel,
       views = views;
  @override
  State<_PrivateNavigation> createState() => _PrivateNavigationState();
}

final class _PrivateNavigationState extends State<_PrivateNavigation> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    final ShellViewModel viewModel = widget.viewModel;
    final ShellViews views = widget.views;
    final ShellState state = viewModel.state;
    final AppLocalizations l = AppLocalizations.of(context)!;
    // Removing this Navigator also removes private dialogs and retained pages.
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) {
        _navigator.currentState?.maybePop();
      },
      child: Navigator(
        key: _navigator,
        pages: [
          MaterialPage(
            key: ValueKey(state.scope),
            child: _Tabs(viewModel: viewModel, views: views),
          ),
          for (final entry in state.routes)
            MaterialPage(
              key: ValueKey(entry.context),
              child: Builder(
                builder: (BuildContext context) {
                  ShellTaskView? task;
                  for (final ShellTaskView candidate in views.tasks) {
                    if (candidate.matches(entry.destination, entry.intent)) {
                      task = candidate;
                      break;
                    }
                  }
                  return Scaffold(
                    appBar: AppBar(
                      leading: BackButton(onPressed: viewModel.back),
                      title: Text(
                        entry.destination == 'account'
                            ? l.shellAccount
                            : l.shellTask,
                      ),
                      actions: const [LanguageButton()],
                    ),
                    body: Column(
                      children: [
                        Expanded(
                          child: entry.destination == 'account'
                              ? _AccountTask(viewModel: viewModel)
                              : task != null
                              ? task.build(context, entry.intent!)
                              : Center(child: Text(l.shellFutureTask)),
                        ),
                        if (identical(
                              entry.context,
                              state.routes.last.context,
                            ) &&
                            state.slots.isNotEmpty)
                          Flexible(
                            child: _ContributionArea(
                              contributions: state.slots.values,
                              views: views,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
        onDidRemovePage: (page) {
          if (viewModel.state.routes.isNotEmpty &&
              page.key == ValueKey(viewModel.state.routes.last.context)) {
            viewModel.back();
          }
        },
      ),
    );
  }
}

final class _Tabs extends StatefulWidget {
  final ShellViewModel viewModel;
  final ShellViews views;
  const _Tabs({required this.viewModel, required this.views});
  @override
  State<_Tabs> createState() => _TabsState();
}

final class _TabsState extends State<_Tabs> {
  // Capture scope-bound Shell once. Old ViewModels never inherit a new scope.
  late final ApplicationShell shell =
      widget.viewModel.runtime.applicationShell!;
  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: vm.state.selectedTab == ShellTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.selectTab(ShellTab.home);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F8FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          title: Text(
            vm.state.selectedTab == ShellTab.home ? 'LocateMY' : l.shellMap,
            style: const TextStyle(
              fontFamily: 'SourceSansPro',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
          actions: [
            const LanguageButton(),
            Tooltip(
              message: l.shellAccount,
              child: TextButton(
                key: const ValueKey('shell-account'),
                onPressed: vm.openAccountTask,
                child: Text(
                  l.shellAccount,
                  style: const TextStyle(
                    fontFamily: 'SourceSansPro',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF155EEF),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: vm.state.selectedTab.index,
                children: [
                  Builder(
                    builder: (context) =>
                        widget.views.home?.call(context, shell) ??
                        _Slot(title: l.shellHome, message: l.shellHomePending),
                  ),
                  Builder(
                    builder: (context) =>
                        widget.views.map?.call(context, shell) ??
                        _Slot(title: l.shellMap, message: l.shellMapPending),
                  ),
                ],
              ),
            ),
            if (vm.state.routes.isEmpty && vm.state.slots.isNotEmpty)
              Flexible(
                child: _ContributionArea(
                  contributions: vm.state.slots.values,
                  views: widget.views,
                ),
              ),
          ],
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (context, constraints) {
            final compact = MediaQuery.textScalerOf(context).scale(14) <= 19;
            Widget tab(IconData icon, String label, bool selected) {
              final color = selected
                  ? const Color(0xFF155EEF)
                  : const Color(0xFF667085);
              return compact
                  ? ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18, color: color),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'SourceSansPro',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Icon(icon, size: 18, color: color);
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFD9E0EA))),
              ),
              child: Stack(
                children: [
                  NavigationBar(
                    height: compact ? 74 : 96,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: Colors.transparent,
                    labelBehavior: compact
                        ? NavigationDestinationLabelBehavior.alwaysHide
                        : NavigationDestinationLabelBehavior.alwaysShow,
                    selectedIndex: vm.state.selectedTab.index,
                    onDestinationSelected: (index) =>
                        vm.selectTab(ShellTab.values[index]),
                    destinations: [
                      NavigationDestination(
                        icon: tab(Icons.home_outlined, l.shellHome, false),
                        selectedIcon: tab(
                          Icons.home_outlined,
                          l.shellHome,
                          true,
                        ),
                        label: l.shellHome,
                      ),
                      NavigationDestination(
                        icon: tab(Icons.map_outlined, l.shellMap, false),
                        selectedIcon: tab(Icons.map_outlined, l.shellMap, true),
                        label: l.shellMap,
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left:
                        constraints.maxWidth *
                            (vm.state.selectedTab.index + .5) /
                            2 -
                        41,
                    child: const SizedBox(
                      width: 82,
                      height: 3,
                      child: ColoredBox(color: Color(0xFF155EEF)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _Slot extends StatelessWidget {
  final String title;
  final String message;
  const _Slot({required this.title, required this.message});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

final class _AccountTask extends StatelessWidget {
  final ShellViewModel viewModel;
  const _AccountTask({required this.viewModel});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.shellAccountPending),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  useRootNavigator: false,
                  builder: (context) {
                    final l = AppLocalizations.of(context)!;
                    return AlertDialog(
                      title: Text(l.confirmSignOut),
                      content: Text(l.confirmSignOutBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l.signOut),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true && context.mounted) {
                  await viewModel.signOut();
                }
              },
              child: Text(l.signOutDevice),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ContributionArea extends StatelessWidget {
  final Iterable<ShellContribution> contributions;
  final ShellViews views;
  const _ContributionArea({required this.contributions, required this.views});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        for (final input in contributions)
          Builder(
            builder: (context) {
              final binding = views.contributions
                  .where((binding) => binding.matches(input))
                  .firstOrNull;
              return binding?.build(context, input) ??
                  Text(AppLocalizations.of(context)!.shellFutureTask);
            },
          ),
      ],
    ),
  );
}
