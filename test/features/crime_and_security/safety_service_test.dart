import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/crime_and_security/crime_and_security.dart';
import 'package:locatemy/features/crime_and_security/src/application/safety_service.dart';
import 'package:locatemy/features/crime_and_security/src/data/crime_repository.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'dart:convert';

class FakeCrimeRepository implements CrimeRepository {
  List<RawCrimeData> crimeData = [];
  List<String> peerData = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<RawCrimeData>> fetchCrimeData(String stateName) async => crimeData;

  @override
  Future<List<String>> fetchOtherStatesData(int year) async => peerData;

  @override
  Future<CachedSafetyData?> getCachedSafety(String s, String m, String b) async => null;

  @override
  Future<void> cacheSafety({required String stateId, required String modelVersion, required String boundaryVersion, required String snapshotJson, required int sourceYear, required Duration ttl}) async {}
}

class FakeGeographicContext implements GeographicContext {
  GeographicContextOutcome outcome;
  FakeGeographicContext(this.outcome);

  @override
  Future<GeographicContextOutcome> resolve(GeographicContextRequest request) async => outcome;
}

void main() {
  group('SafetyService', () {
    late FakeCrimeRepository repository;
    late ValidLocationReference location;

    setUp(() {
      repository = FakeCrimeRepository();
      location = const ValidLocationReference(
        locationId: 'loc1',
        point: GeographicPoint(latitude: 3.1390, longitude: 101.6869),
        displayName: 'Kuala Lumpur',
      );
    });

    test('should return SafetyAvailable when data is complete', () async {
      final geoOutcome = GeographicContextAvailable({
        GeographicLevel.reportingState: GeographicLevelResolved(
          const AdministrativeArea(
            level: GeographicLevel.reportingState,
            stableId: 'state_kl',
            name: 'W.P. Kuala Lumpur',
            reportingStateId: 'state_kl',
            reportingStateName: 'W.P. Kuala Lumpur',
          ),
          BoundaryProvenance(
            datasetId: 'boundaries',
            sourceUri: Uri.parse('https://example.com'),
            sourceVersion: 'v1',
            sourceSha256: 'sha',
            derivedGeometrySha256: 'sha',
            importedAt: DateTime.now(),
          ),
        ),
      });

      final service = SafetyService(
        repository: repository,
        geographicContext: FakeGeographicContext(geoOutcome),
      );

      repository.crimeData = [
        const RawCrimeData(date: '2023-01-01', state: 'W.P. Kuala Lumpur', category: 'assault', type: 'robbery', crimes: 100),
        const RawCrimeData(date: '2023-01-01', state: 'W.P. Kuala Lumpur', category: 'property', type: 'theft', crimes: 200),
      ];

      repository.peerData = [
        jsonEncode({'state': 'Selangor', 'category': 'assault', 'crimes': 50}),
        jsonEncode({'state': 'Selangor', 'category': 'property', 'crimes': 150}),
      ];

      final outcome = await service.load(SafetyRequest(
        location: location,
        policy: SafetyLoadPolicy.refresh,
        filter: const AllCrimeTrend(),
      ));

      expect(outcome, isA<SafetyAvailable>());
      final snapshot = (outcome as SafetyAvailable).snapshot;
      expect(snapshot.score.value, isNotNull);
      expect(snapshot.latestCompleteYearCount.year, 2023);
      // KL (100, 200) vs Selangor (50, 150). KL has more crimes, so risk should be higher, safety lower.
      // log(101) > log(51), log(201) > log(151).
      // KL is 100th percentile for both (in this 2-state set).
      // Risk = 0.6*100 + 0.4*100 = 100. Safety = 100 - 100 = 0.
      expect(snapshot.score.value, 0); 
    });

    test('should return SafetyUnavailable when location is unresolved', () async {
      final geoOutcome = const GeographicContextUnavailable(GeographicContextFailure.noCoverage);

      final service = SafetyService(
        repository: repository,
        geographicContext: FakeGeographicContext(geoOutcome),
      );

      final outcome = await service.load(SafetyRequest(
        location: location,
        policy: SafetyLoadPolicy.refresh,
        filter: const AllCrimeTrend(),
      ));

      expect(outcome, isA<SafetyUnavailable>());
      expect((outcome as SafetyUnavailable).reason, SafetyUnavailableReason.stateUnresolved);
    });
  });
}
