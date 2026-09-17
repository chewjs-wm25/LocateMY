// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/app/application_shell.dart';

final class OpenHazardComposerIntent implements ShellIntent {
  final ValidLocationReference location;
  final String returnContextId;
  const OpenHazardComposerIntent({
    required ValidLocationReference location,
    required String returnContextId,
  }) : location = location,
       returnContextId = returnContextId;
}

final class OpenHazardDetailIntent implements ShellIntent {
  final HazardReportId id;
  final String returnContextId;
  const OpenHazardDetailIntent({
    required HazardReportId id,
    required String returnContextId,
  }) : id = id,
       returnContextId = returnContextId;
}

final class OpenMyHazardsIntent implements ShellIntent {
  final String returnContextId;
  const OpenMyHazardsIntent(String returnContextId)
    : returnContextId = returnContextId;
}

abstract interface class HazardReporting {
  Future<HazardCreateOutcome> create(HazardCreateRequest request);
  Future<HazardPageOutcome> loadPublic(HazardPageRequest request);
  Future<HazardDetailOutcome> loadDetail(HazardReportId id);
  Future<MyHazardsOutcome> loadMine(HazardPageRequest request);
  Future<HazardStatusOutcome> changeMyStatus(HazardStatusRequest request);
  Future<HazardDeleteOutcome> deleteMine(HazardReportId id);
  Future<HazardVoteOutcome> vote(HazardVoteRequest request);
}

abstract interface class HazardRiskCounter {
  Future<HazardNearbyCountOutcome> countPending(
    HazardNearbyCountRequest request,
  );
}

enum HazardType { flood, crime, traffic, infrastructure, other }

enum HazardAuthorStatus { pending, resolved }

enum HazardVote { up, down, none }

enum HazardAuthorView { mine, other }

enum HazardReadFailure {
  authenticationRequired,
  invalidViewport,
  notFound,
  retryableUnavailable,
  incompletePage,
  scopeUnavailable,
}

enum HazardWriteFailure {
  invalidType,
  emptyTitle,
  titleTooLong,
  descriptionTooLong,
  invalidLocation,
  authenticationRequired,
  permissionDenied,
  conflict,
  notFound,
  retryableUnavailable,
  scopeUnavailable,
  immutableContent,
}

enum HazardNearbyCountFailure {
  invalidLocation,
  authenticationRequired,
  partialResult,
  retryableUnavailable,
  scopeUnavailable,
}

final class HazardReportId {
  final String value;
  const HazardReportId(String value) : value = value;
}

final class HazardCreateRequest {
  final ValidLocationReference location;
  final HazardType type;
  final String title;
  final String? description;
  const HazardCreateRequest({
    required ValidLocationReference location,
    required HazardType type,
    required String title,
    String? description,
  }) : location = location,
       type = type,
       title = title,
       description = description;
}

final class HazardViewport {
  final GeographicPoint southWest;
  final GeographicPoint northEast;
  const HazardViewport(GeographicPoint southWest, GeographicPoint northEast)
    : southWest = southWest,
      northEast = northEast;
}

final class HazardPageRequest {
  final String viewportVersion;
  final HazardViewport viewport;
  final String? cursor;
  const HazardPageRequest({
    required String viewportVersion,
    required HazardViewport viewport,
    String? cursor,
  }) : viewportVersion = viewportVersion,
       viewport = viewport,
       cursor = cursor;
}

final class HazardStatusRequest {
  final HazardReportId id;
  final HazardAuthorStatus status;
  const HazardStatusRequest(HazardReportId id, HazardAuthorStatus status)
    : id = id,
      status = status;
}

final class HazardVoteRequest {
  final HazardReportId id;
  final HazardVote vote;
  const HazardVoteRequest(HazardReportId id, HazardVote vote)
    : id = id,
      vote = vote;
}

final class HazardVoteState {
  final HazardVote mine;
  final int upvotes;
  final int downvotes;
  const HazardVoteState(HazardVote mine, int upvotes, int downvotes)
    : mine = mine,
      upvotes = upvotes,
      downvotes = downvotes;
}

final class HazardReport {
  final HazardReportId id;
  final HazardType type;
  final String title;
  final String? description;
  final GeographicPoint location;
  final HazardAuthorStatus status;
  final DateTime reportedAt;
  final HazardAuthorView author;
  final HazardVoteState vote;
  const HazardReport({
    required HazardReportId id,
    required HazardType type,
    required String title,
    String? description,
    required GeographicPoint location,
    required HazardAuthorStatus status,
    required DateTime reportedAt,
    required HazardAuthorView author,
    required HazardVoteState vote,
  }) : id = id,
       type = type,
       title = title,
       description = description,
       location = location,
       status = status,
       reportedAt = reportedAt,
       author = author,
       vote = vote;
}

final class HazardPage {
  final List<HazardReport> reports;
  final String? nextCursor;
  final String viewportVersion;
  const HazardPage(
    List<HazardReport> reports,
    String? nextCursor,
    String viewportVersion,
  ) : reports = reports,
      nextCursor = nextCursor,
      viewportVersion = viewportVersion;
}

final class HazardNearbyCountRequest {
  final ValidLocationReference propertyLocation;
  const HazardNearbyCountRequest(ValidLocationReference propertyLocation)
    : propertyLocation = propertyLocation;
}

sealed class HazardCreateOutcome {
  const HazardCreateOutcome();
}

final class HazardCreated extends HazardCreateOutcome {
  final HazardReport report;
  const HazardCreated(HazardReport report) : report = report;
}

final class HazardCreateRejected extends HazardCreateOutcome {
  final HazardWriteFailure failure;
  const HazardCreateRejected(HazardWriteFailure failure) : failure = failure;
}

sealed class HazardPageOutcome {
  const HazardPageOutcome();
}

final class HazardPageAvailable extends HazardPageOutcome {
  final HazardPage page;
  const HazardPageAvailable(HazardPage page) : page = page;
}

final class HazardPagePartial extends HazardPageOutcome {
  final HazardPage page;
  final HazardReadFailure failure;
  const HazardPagePartial(HazardPage page, HazardReadFailure failure)
    : page = page,
      failure = failure;
}

final class HazardPageUnavailable extends HazardPageOutcome {
  final HazardReadFailure failure;
  const HazardPageUnavailable(HazardReadFailure failure) : failure = failure;
}

sealed class HazardDetailOutcome {
  const HazardDetailOutcome();
}

final class HazardDetailAvailable extends HazardDetailOutcome {
  final HazardReport report;
  const HazardDetailAvailable(HazardReport report) : report = report;
}

final class HazardDetailUnavailable extends HazardDetailOutcome {
  final HazardReadFailure failure;
  const HazardDetailUnavailable(HazardReadFailure failure) : failure = failure;
}

sealed class MyHazardsOutcome {
  const MyHazardsOutcome();
}

final class MyHazardsAvailable extends MyHazardsOutcome {
  final HazardPage page;
  const MyHazardsAvailable(HazardPage page) : page = page;
}

final class MyHazardsUnavailable extends MyHazardsOutcome {
  final HazardReadFailure failure;
  const MyHazardsUnavailable(HazardReadFailure failure) : failure = failure;
}

sealed class HazardStatusOutcome {
  const HazardStatusOutcome();
}

final class HazardStatusChanged extends HazardStatusOutcome {
  final HazardReport report;
  const HazardStatusChanged(HazardReport report) : report = report;
}

final class HazardStatusRejected extends HazardStatusOutcome {
  final HazardWriteFailure failure;
  const HazardStatusRejected(HazardWriteFailure failure) : failure = failure;
}

sealed class HazardDeleteOutcome {
  const HazardDeleteOutcome();
}

final class HazardDeleted extends HazardDeleteOutcome {
  final HazardReportId id;
  const HazardDeleted(HazardReportId id) : id = id;
}

final class HazardDeleteRejected extends HazardDeleteOutcome {
  final HazardWriteFailure failure;
  const HazardDeleteRejected(HazardWriteFailure failure) : failure = failure;
}

sealed class HazardVoteOutcome {
  const HazardVoteOutcome();
}

final class HazardVoteChanged extends HazardVoteOutcome {
  final HazardReportId id;
  final HazardVoteState state;
  const HazardVoteChanged(HazardReportId id, HazardVoteState state)
    : id = id,
      state = state;
}

final class HazardVoteRejected extends HazardVoteOutcome {
  final HazardWriteFailure failure;
  const HazardVoteRejected(HazardWriteFailure failure) : failure = failure;
}

sealed class HazardNearbyCountOutcome {
  const HazardNearbyCountOutcome();
}

final class HazardNearbyCountAvailable extends HazardNearbyCountOutcome {
  final int count;
  final int radiusMeters;
  final DateTime countedAt;
  const HazardNearbyCountAvailable(
    int count,
    int radiusMeters,
    DateTime countedAt,
  ) : count = count,
      radiusMeters = radiusMeters,
      countedAt = countedAt;
}

final class HazardNearbyCountUnavailable extends HazardNearbyCountOutcome {
  final HazardNearbyCountFailure failure;
  const HazardNearbyCountUnavailable(HazardNearbyCountFailure failure)
    : failure = failure;
}

final class ReturnToHazardMapIntent implements ShellIntent {
  final String returnContextId;
  const ReturnToHazardMapIntent(String returnContextId)
    : returnContextId = returnContextId;
}

final class HazardShellContribution implements ShellContribution {
  final String contributionId;
  final String source;
  final DateTime observedAt;
  final String availability;
  const HazardShellContribution({
    required String contributionId,
    required String source,
    required DateTime observedAt,
    required String availability,
  }) : contributionId = contributionId,
       source = source,
       observedAt = observedAt,
       availability = availability;
}
