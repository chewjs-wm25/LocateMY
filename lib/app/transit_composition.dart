// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import 'package:locatemy/app/application_shell.dart';

import 'src/presentation/shell_host.dart';

import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

import 'src/application/shell_runtime.dart';
import 'src/domain/shell_routes.dart';
import 'src/domain/shell_state.dart';

bool _sameTransitLocation(ValidLocationReference a, ValidLocationReference b) {
  return a.locationId == b.locationId &&
      a.point.latitude == b.point.latitude &&
      a.point.longitude == b.point.longitude;
}

bool _sameTransitDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// Compare immutable inputs across phases: the opening intent has the parent
// request, while the page captures the newly allocated task request.
bool _sameTransitInput(AnalysisReturnContext a, AnalysisReturnContext b) {
  return a.role == b.role &&
      _sameTransitLocation(a.location, b.location) &&
      _sameTransitDate(a.analysisDate, b.analysisDate);
}

ShellRejectionReason? _transitTaskFailure(
  ShellRuntime shell,
  AnalysisReturnContext context,
) {
  if (context.originalRequestIdentity is! ShellRequestContext) {
    return ShellRejectionReason.missingInput;
  }
  if (!identical(context.originalRequestIdentity, shell.currentContext)) {
    return ShellRejectionReason.staleInput;
  }
  if (shell.state.routes.isEmpty) {
    return ShellRejectionReason.inapplicableDestination;
  }
  final ShellIntent? intent = shell.state.routes.last.intent;
  if (intent is OpenPublicTransportationIntent &&
      _sameTransitInput(intent.returnContext, context)) {
    return null;
  }
  if (intent is OpenPublicTransportationComparisonIntent) {
    if ((context.role == LocationRole.locationA &&
            _sameTransitInput(intent.a, context)) ||
        (context.role == LocationRole.locationB &&
            _sameTransitInput(intent.b, context))) {
      return null;
    }
  }
  return ShellRejectionReason.staleInput;
}

bool _transitOutcomeMatches(
  TransitLoadOutcome outcome,
  AnalysisReturnContext context,
) {
  if (outcome is TransitAvailable) {
    return _sameTransitLocation(outcome.snapshot.location, context.location) &&
        _sameTransitDate(outcome.snapshot.analysisDate, context.analysisDate);
  }
  if (outcome is TransitIncomplete) {
    return _sameTransitLocation(outcome.snapshot.location, context.location) &&
        _sameTransitDate(outcome.snapshot.analysisDate, context.analysisDate);
  }
  return true;
}

List<ShellIntentBinding> transitShellBindings(
  ShellRuntime Function() runtime, {
  required LocationCoordinator Function() locations,
}) {
  return <ShellIntentBinding>[
    ShellIntentBinding<OpenPublicTransportationIntent>((
      OpenPublicTransportationIntent intent,
    ) {
      final AnalysisReturnContext input = intent.returnContext;
      final LocationRoleSnapshot selected = locations().read(input.role);
      if (selected is! LocationPresent ||
          !_sameTransitLocation(selected.location, input.location) ||
          input.originalRequestIdentity is! ShellRequestContext) {
        return const ShellRouteRequest.rejected(
          ShellRejectionReason.missingInput,
        );
      }
      return ShellRouteRequest.task(
        context: input.originalRequestIdentity as ShellRequestContext,
        destination: 'public-transportation',
      );
    }),
    ShellIntentBinding<OpenPublicTransportationComparisonIntent>((
      OpenPublicTransportationComparisonIntent intent,
    ) {
      final AnalysisReturnContext a = intent.a;
      final AnalysisReturnContext b = intent.b;
      final LocationRoleSnapshot selectedA = locations().read(
        LocationRole.locationA,
      );
      final LocationRoleSnapshot selectedB = locations().read(
        LocationRole.locationB,
      );
      if (a.role != LocationRole.locationA ||
          b.role != LocationRole.locationB ||
          selectedA is! LocationPresent ||
          selectedB is! LocationPresent ||
          !_sameTransitLocation(a.location, selectedA.location) ||
          !_sameTransitLocation(b.location, selectedB.location) ||
          _sameTransitLocation(a.location, b.location) ||
          !_sameTransitDate(a.analysisDate, b.analysisDate) ||
          !identical(a.originalRequestIdentity, b.originalRequestIdentity) ||
          a.originalRequestIdentity is! ShellRequestContext) {
        return const ShellRouteRequest.rejected(
          ShellRejectionReason.missingInput,
        );
      }
      return ShellRouteRequest.task(
        context: a.originalRequestIdentity as ShellRequestContext,
        destination: 'public-transportation-comparison',
      );
    }),
    ShellIntentBinding<ReturnToMapIntent>((ReturnToMapIntent intent) {
      final ShellRejectionReason? failure = _transitTaskFailure(
        runtime(),
        intent.returnContext,
      );
      if (failure != null) {
        return ShellRouteRequest.rejected(failure);
      }
      return ShellRouteRequest.tab(
        context:
            intent.returnContext.originalRequestIdentity as ShellRequestContext,
        tab: ShellTab.map,
      );
    }),
  ];
}

List<ShellContributionBinding> transitShellContributions(
  ShellRuntime Function() runtime,
) {
  return <ShellContributionBinding>[
    ShellContributionBinding<PublicTransportationComparisonContribution>((
      PublicTransportationComparisonContribution input,
    ) {
      final ShellRejectionReason? failureA = _transitTaskFailure(
        runtime(),
        input.a,
      );
      final ShellRejectionReason? failureB = _transitTaskFailure(
        runtime(),
        input.b,
      );
      if (failureA != null || failureB != null) {
        return ShellSlotRequest.rejected(failureA ?? failureB!);
      }
      if (input.a.role != LocationRole.locationA ||
          input.b.role != LocationRole.locationB ||
          !_sameTransitDate(input.a.analysisDate, input.b.analysisDate) ||
          !identical(
            input.a.originalRequestIdentity,
            input.b.originalRequestIdentity,
          )) {
        return const ShellSlotRequest.rejected(ShellRejectionReason.staleInput);
      }
      final TransitComparisonOutcome outcome = input.outcome;
      bool matches;
      if (outcome is TransitComparable) {
        matches =
            _transitOutcomeMatches(TransitAvailable(outcome.a), input.a) &&
            _transitOutcomeMatches(TransitAvailable(outcome.b), input.b);
      } else if (outcome is TransitIncomparable) {
        matches =
            _transitOutcomeMatches(outcome.a, input.a) &&
            _transitOutcomeMatches(outcome.b, input.b);
      } else {
        matches = false;
      }
      if (!matches) {
        return const ShellSlotRequest.rejected(ShellRejectionReason.staleInput);
      }
      return ShellSlotRequest(
        context: input.a.originalRequestIdentity as ShellRequestContext,
        slot: 'public-transportation-comparison',
      );
    }),
    ShellContributionBinding<PublicTransportationContribution>((
      PublicTransportationContribution input,
    ) {
      final AnalysisReturnContext context = input.returnContext;
      final ShellRejectionReason? failure = _transitTaskFailure(
        runtime(),
        context,
      );
      if (failure != null) {
        return ShellSlotRequest.rejected(failure);
      }
      final TransitLoadOutcome outcome = input.outcome;
      if (outcome is TransitAvailable &&
          (!_sameTransitLocation(outcome.snapshot.location, context.location) ||
              !_sameTransitDate(
                outcome.snapshot.analysisDate,
                context.analysisDate,
              ))) {
        return const ShellSlotRequest.rejected(ShellRejectionReason.staleInput);
      }
      if (outcome is TransitIncomplete &&
          (!_sameTransitLocation(outcome.snapshot.location, context.location) ||
              !_sameTransitDate(
                outcome.snapshot.analysisDate,
                context.analysisDate,
              ))) {
        return const ShellSlotRequest.rejected(ShellRejectionReason.staleInput);
      }
      return ShellSlotRequest(
        context: context.originalRequestIdentity as ShellRequestContext,
        slot: 'public-transportation-${context.role.name}',
      );
    }),
  ];
}

/// Root keeps each task's immutable context and local Map host stable across publications.
List<ShellTaskView> transitTaskViews(
  PublicTransportation transportation,
  MapLocationRuntime map,
  ShellRuntime Function() runtime,
) {
  final Expando<_TransitTaskSession> sessions = Expando<_TransitTaskSession>();
  _TransitTaskSession session(
    ShellIntent intent,
    AnalysisReturnContext input,
    AnalysisReturnContext? second,
  ) {
    final ShellRuntime shell = runtime();
    final ShellNavigationEntry entry = shell.state.routes.firstWhere((
      ShellNavigationEntry entry,
    ) {
      return identical(entry.intent, intent);
    });
    final _TransitTaskSession? previous = sessions[entry.context];
    if (previous != null) {
      return previous;
    }
    AnalysisReturnContext taskContext(AnalysisReturnContext source) {
      return AnalysisReturnContext(
        location: source.location,
        role: source.role,
        analysisDate: source.analysisDate,
        originalRequestIdentity: entry.context,
      );
    }

    final LocationCoordinator local = createLocationCoordinator(
      scope: entry.context.scope,
      readScope: map.readScope,
      validatePoint: map.validatePoint,
    );
    final _TransitTaskSession value = _TransitTaskSession(
      taskContext(input),
      second == null ? null : taskContext(second),
      shell.applicationShell!,
      local,
    );
    sessions[entry.context] = value;
    return value;
  }

  return <ShellTaskView>[
    ShellTaskView<OpenPublicTransportationIntent>('public-transportation', (
      BuildContext context,
      OpenPublicTransportationIntent intent,
    ) {
      final _TransitTaskSession current = session(
        intent,
        intent.returnContext,
        null,
      );
      return PublicTransportationPage(
        transportation: transportation,
        location: current.a.location,
        analysisDate: current.a.analysisDate,
        returnContext: current.a,
        applicationShell: current.shell,
        mapLayerHost: locationLayerHost(current.local),
        mapWorkspace: locationWorkspace(current.local),
      );
    }, ownsScaffold: true),
    ShellTaskView<OpenPublicTransportationComparisonIntent>(
      'public-transportation-comparison',
      (BuildContext context, OpenPublicTransportationComparisonIntent intent) {
        final _TransitTaskSession current = session(intent, intent.a, intent.b);
        return PublicTransportationComparisonPage(
          transportation: transportation,
          a: current.a,
          b: current.b!,
          applicationShell: current.shell,
          onOpenStations: (AnalysisReturnContext input) {
            current.shell.submit(OpenPublicTransportationIntent(input));
          },
        );
      },
      ownsScaffold: true,
    ),
  ];
}

final class _TransitTaskSession {
  final AnalysisReturnContext a;
  final AnalysisReturnContext? b;
  final ApplicationShell shell;
  final LocationCoordinator local;
  _TransitTaskSession(
    AnalysisReturnContext a,
    AnalysisReturnContext? b,
    ApplicationShell shell,
    LocationCoordinator local,
  ) : a = a,
      b = b,
      shell = shell,
      local = local;
}

/// The generic analysis destination lets users choose a provider and explicit date.
final class TransportationAnalysisMenu extends StatefulWidget {
  final ValidLocationReference a;
  final ValidLocationReference? b;
  final ShellRuntime runtime;
  final ShellRequestContext request;
  final VoidCallback onNearby;
  const TransportationAnalysisMenu({
    required ValidLocationReference a,
    ValidLocationReference? b,
    required ShellRuntime runtime,
    required ShellRequestContext request,
    required VoidCallback onNearby,
    super.key,
  }) : a = a,
       b = b,
       runtime = runtime,
       request = request,
       onNearby = onNearby;
  @override
  State<TransportationAnalysisMenu> createState() {
    return _TransportationAnalysisMenuState();
  }
}

final class _TransportationAnalysisMenuState
    extends State<TransportationAnalysisMenu> {
  late DateTime _date;
  ShellIntentOutcome? _navigation;
  bool get _zh {
    return Localizations.localeOf(context).languageCode == 'zh';
  }

  String _t(String zh, String en) {
    if (_zh) {
      return zh;
    }
    return en;
  }

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (mounted && selected != null) {
      setState(() {
        _date = selected;
      });
    }
  }

  Future<void> _open() async {
    AnalysisReturnContext input(
      ValidLocationReference location,
      LocationRole role,
    ) {
      return AnalysisReturnContext(
        location: location,
        role: role,
        analysisDate: _date,
        originalRequestIdentity: widget.request,
      );
    }

    final ValidLocationReference? b = widget.b;
    final ShellIntent intent;
    if (b == null) {
      intent = OpenPublicTransportationIntent(
        input(widget.a, LocationRole.single),
      );
    } else {
      intent = OpenPublicTransportationComparisonIntent(
        input(widget.a, LocationRole.locationA),
        input(b, LocationRole.locationB),
      );
    }
    final ShellIntentOutcome outcome = await widget.runtime.submit(intent);
    if (mounted) {
      setState(() {
        _navigation = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: _t('返回', 'Back'),
                  onPressed: widget.runtime.back,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _t('地点分析', 'Location analysis'),
                    style: const TextStyle(
                      fontFamily: 'SourceSansPro',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(widget.a.displayName ?? widget.a.locationId),
            if (widget.b != null)
              Text(widget.b!.displayName ?? widget.b!.locationId),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t('公共交通分析日期', 'Transportation analysis date')),
              subtitle: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            FilledButton(
              onPressed: _open,
              child: Text(_t('公共交通', 'Public transportation')),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onNearby,
              child: Text(_t('周边设施', 'Nearby facilities')),
            ),
            if (_navigation is ShellAuthenticationRequired ||
                _navigation is ShellIntentRejected)
              Text(
                _t(
                  '无法打开分析。请返回地图重新选择地点；必要时重新登录。',
                  'Unable to open analysis. Return to the map and select locations again; sign in if needed.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
