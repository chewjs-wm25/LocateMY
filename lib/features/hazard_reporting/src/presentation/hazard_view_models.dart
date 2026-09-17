// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';

import '../domain/hazard_models.dart';

final class HazardComposerViewModel extends ChangeNotifier {
  final HazardReporting _hazards;
  bool saving = false;
  HazardWriteFailure? failure;
  HazardType? type;
  bool _disposed = false;
  HazardComposerViewModel(HazardReporting hazards) : _hazards = hazards;
  void choose(HazardType? value) {
    type = value;
    failure = null;
    notifyListeners();
  }

  Future<bool> submit(HazardCreateRequest Function(HazardType) request) async {
    if (saving) {
      return false;
    }
    if (type == null) {
      failure = HazardWriteFailure.invalidType;
      notifyListeners();
      return false;
    }
    saving = true;
    failure = null;
    notifyListeners();
    HazardCreateOutcome outcome;
    try {
      outcome = await _hazards.create(request(type!));
    } catch (_) {
      outcome = const HazardCreateRejected(
        HazardWriteFailure.retryableUnavailable,
      );
    }
    if (_disposed) {
      return false;
    }
    saving = false;
    if (outcome is HazardCreateRejected) {
      failure = outcome.failure;
    }
    notifyListeners();
    return outcome is HazardCreated;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final class HazardListViewModel extends ChangeNotifier {
  final HazardReporting _hazards;
  final HazardPageRequest request;
  List<HazardReport> reports = const [];
  String? nextCursor;
  HazardReadFailure? failure;
  DateTime? refreshedAt;
  bool loading = false;
  bool _disposed = false;
  int _generation = 0;
  HazardListViewModel(HazardReporting hazards, HazardPageRequest request)
    : _hazards = hazards,
      request = request;
  Future<void> refresh({bool more = false}) async {
    if (more && (loading || nextCursor == null)) {
      return;
    }
    final int generation = ++_generation;
    loading = true;
    failure = null;
    notifyListeners();
    MyHazardsOutcome outcome;
    try {
      outcome = await _hazards.loadMine(
        HazardPageRequest(
          viewportVersion: request.viewportVersion,
          viewport: request.viewport,
          cursor: more ? nextCursor : null,
        ),
      );
    } catch (_) {
      outcome = const MyHazardsUnavailable(
        HazardReadFailure.retryableUnavailable,
      );
    }
    if (_disposed || generation != _generation) {
      return;
    }
    loading = false;
    if (outcome is MyHazardsAvailable) {
      final List<HazardReport> updated = [];
      if (more) {
        updated.addAll(reports);
      }
      for (final HazardReport report in outcome.page.reports) {
        updated.removeWhere((HazardReport old) {
          return old.id.value == report.id.value;
        });
        updated.add(report);
      }
      reports = List.unmodifiable(updated);
      nextCursor = outcome.page.nextCursor;
      refreshedAt = DateTime.now();
    } else {
      failure = (outcome as MyHazardsUnavailable).failure;
    }
    if (failure == HazardReadFailure.scopeUnavailable ||
        failure == HazardReadFailure.authenticationRequired) {
      reports = const [];
      nextCursor = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

final class HazardDetailViewModel extends ChangeNotifier {
  final HazardReporting _hazards;
  final HazardReportId id;
  HazardReport? report;
  HazardReadFailure? failure;
  bool loading = false;
  bool _disposed = false;
  int _generation = 0;
  HazardDetailViewModel(HazardReporting hazards, HazardReportId id)
    : _hazards = hazards,
      id = id;
  Future<void> load() async {
    final int generation = ++_generation;
    loading = true;
    failure = null;
    notifyListeners();
    HazardDetailOutcome outcome;
    try {
      outcome = await _hazards.loadDetail(id);
    } catch (_) {
      outcome = const HazardDetailUnavailable(
        HazardReadFailure.retryableUnavailable,
      );
    }
    if (_disposed || generation != _generation) {
      return;
    }
    loading = false;
    if (outcome is HazardDetailAvailable) {
      report = outcome.report;
    } else {
      failure = (outcome as HazardDetailUnavailable).failure;
      if (failure == HazardReadFailure.notFound ||
          failure == HazardReadFailure.scopeUnavailable ||
          failure == HazardReadFailure.authenticationRequired) {
        report = null;
      }
    }
    notifyListeners();
  }

  Future<HazardWriteFailure?> vote(HazardVote vote) async {
    final HazardVoteOutcome outcome = await _hazards.vote(
      HazardVoteRequest(id, vote),
    );
    if (_disposed) {
      return HazardWriteFailure.scopeUnavailable;
    }
    if (outcome is HazardVoteRejected) {
      return outcome.failure;
    }
    final HazardReport? previous = report;
    final HazardVoteState authoritative = (outcome as HazardVoteChanged).state;
    if (previous != null) {
      report = HazardReport(
        id: previous.id,
        type: previous.type,
        title: previous.title,
        description: previous.description,
        location: previous.location,
        status: previous.status,
        reportedAt: previous.reportedAt,
        author: previous.author,
        vote: authoritative,
      );
      notifyListeners();
    }
    await load();
    return null;
  }

  Future<HazardWriteFailure?> status(HazardAuthorStatus status) async {
    final HazardStatusOutcome outcome = await _hazards.changeMyStatus(
      HazardStatusRequest(id, status),
    );
    if (_disposed) {
      return HazardWriteFailure.scopeUnavailable;
    }
    if (outcome is HazardStatusRejected) {
      return outcome.failure;
    }
    report = (outcome as HazardStatusChanged).report;
    notifyListeners();
    return null;
  }

  Future<HazardWriteFailure?> delete() async {
    final HazardDeleteOutcome outcome = await _hazards.deleteMine(id);
    if (_disposed) {
      return HazardWriteFailure.scopeUnavailable;
    }
    if (outcome is HazardDeleteRejected) {
      return outcome.failure;
    }
    report = null;
    notifyListeners();
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    report = null;
    super.dispose();
  }
}
