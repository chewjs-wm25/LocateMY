// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:locatemy/app/application_shell.dart';

import '../domain/transit_models.dart';
import '../domain/transit_shell_models.dart';

final class TransitComparisonViewModel extends ChangeNotifier {
  final PublicTransportation _transportation;
  final AnalysisReturnContext a;
  final AnalysisReturnContext b;
  final ApplicationShell? _shell;
  TransitComparisonOutcome? _outcome;
  bool _loading = false;
  bool _closed = false;
  bool _reversed = false;
  bool _retained = false;
  int _revision = 0;
  ShellContributionOutcome? _publication;
  ShellIntentOutcome? _navigation;
  TransitComparisonViewModel({
    required PublicTransportation transportation,
    required AnalysisReturnContext a,
    required AnalysisReturnContext b,
    ApplicationShell? applicationShell,
  }) : _transportation = transportation,
       a = a,
       b = b,
       _shell = applicationShell;

  TransitComparisonOutcome? get outcome {
    return _outcome;
  }

  bool get loading {
    return _loading;
  }

  bool get retainedPreviousResult {
    return _retained;
  }

  bool get reversed {
    return _reversed;
  }

  ShellContributionOutcome? get publication {
    return _publication;
  }

  ShellIntentOutcome? get navigation {
    return _navigation;
  }

  Future<void> load(TransitLoadPolicy policy) async {
    if (_closed) {
      return;
    }
    final int revision = ++_revision;
    _loading = true;
    _publication = null;
    _retained = false;
    notifyListeners();
    TransitComparisonOutcome result;
    try {
      result = await _transportation.compare(
        TransitComparisonRequest(
          TransitRequest(
            location: a.location,
            analysisDate: a.analysisDate,
            policy: policy,
          ),
          TransitRequest(
            location: b.location,
            analysisDate: b.analysisDate,
            policy: policy,
          ),
        ),
      );
    } catch (_) {
      _retained = _outcome != null;
      const TransitUnavailable unavailable = TransitUnavailable(
        TransitUnavailableReason.retryableUnavailable,
        <FeedStatus>[],
      );
      result =
          _outcome ??
          const TransitIncomparable(
            unavailable,
            unavailable,
            TransitComparisonReason.sideUnavailable,
          );
    }
    if (_closed || revision != _revision) {
      return;
    }
    final TransitComparisonOutcome? previous = _outcome;
    if (policy == TransitLoadPolicy.refresh && previous != null) {
      if (previous is TransitComparable && result is TransitComparable) {
        _retained =
            _retained ||
            identical(previous.a, result.a) ||
            identical(previous.b, result.b);
      } else if (previous is TransitIncomparable &&
          result is TransitIncomparable) {
        _retained =
            _retained ||
            identical(previous.a, result.a) ||
            identical(previous.b, result.b);
      }
    }
    _outcome = result;
    _loading = false;
    notifyListeners();
    final ApplicationShell? shell = _shell;
    if (shell != null) {
      ShellContributionOutcome publication;
      try {
        publication = await shell.publish(
          PublicTransportationComparisonContribution(result, a, b),
        );
      } catch (_) {
        publication = const ShellContributionRejected(
          ShellRejectionReason.scopeUnavailable,
        );
      }
      if (_closed || revision != _revision) {
        return;
      }
      _publication = publication;
      notifyListeners();
    }
  }

  void swapDisplayOrder() {
    if (_closed) {
      return;
    }
    _reversed = !_reversed;
    notifyListeners();
  }

  Future<void> returnToMap() async {
    final ApplicationShell? shell = _shell;
    if (_closed || shell == null) {
      return;
    }
    ShellIntentOutcome navigation;
    try {
      navigation = await shell.submit(ReturnToMapIntent(a));
    } catch (_) {
      navigation = const ShellIntentRejected(
        ShellRejectionReason.scopeUnavailable,
      );
    }
    if (_closed) {
      return;
    }
    _navigation = navigation;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    ++_revision;
    _outcome = null;
    super.dispose();
  }
}
