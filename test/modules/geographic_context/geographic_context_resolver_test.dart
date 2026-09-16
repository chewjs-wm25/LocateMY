import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/src/fake_geographic_context.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:locatemy/modules/geographic_context/src/geographic_context_resolver.dart';

void main() {
  late GeographicContextResolver resolver;

  setUp(() {
    resolver = GeographicContextResolver();
  });

  Map<String, dynamic> createSampleRow({
    String boundaryId = 'bnd_001',
    String state = 'Selangor',
    String district = 'Petaling',
  }) {
    return {
      'boundary_id': boundaryId,
      'state': state,
      'district': district,
      'source_dataset': 'dosm_admin_2026',
      'source_url': 'https://data.gov.my/datasets/dosm_boundaries',
      'source_version': 'v1.0.0',
      'geometry_transform': 'ST_MakeValid',
      'source_sha256': 'abc123sha',
      'derived_geometry_sha256': 'def456sha',
      'imported_at': '2026-09-14T08:00:00.000Z',
    };
  }

  test('returns GeographicLevelUnresolved(noCoverage) on empty candidates', () {
    final outcome = resolver.processCandidates(
      rawRows: [],
      requestedLevels: {
        GeographicLevel.district,
        GeographicLevel.reportingState,
      },
    );

    expect(outcome, isA<GeographicContextAvailable>());
    final available = outcome as GeographicContextAvailable;

    expect(
      available.results[GeographicLevel.district],
      isA<GeographicLevelUnresolved>().having(
        (u) => u.failure,
        'failure',
        GeographicContextFailure.noCoverage,
      ),
    );
  });

  test('resolves single candidate flat RPC row successfully', () {
    final rawRows = [createSampleRow()];

    final outcome = resolver.processCandidates(
      rawRows: rawRows,
      requestedLevels: {
        GeographicLevel.district,
        GeographicLevel.reportingState,
      },
    );

    expect(outcome, isA<GeographicContextAvailable>());
    final available = outcome as GeographicContextAvailable;

    final districtRes =
        available.results[GeographicLevel.district] as GeographicLevelResolved;
    expect(districtRes.area.name, 'Petaling');
    expect(districtRes.area.reportingStateName, 'Selangor');

    final stateRes =
        available.results[GeographicLevel.reportingState]
            as GeographicLevelResolved;
    expect(stateRes.area.name, 'Selangor');
  });

  test('handles multi-district candidates in same state', () {
    final rawRows = [
      createSampleRow(boundaryId: 'bnd_001', district: 'Petaling'),
      createSampleRow(boundaryId: 'bnd_002', district: 'Klang'),
    ];

    final outcome = resolver.processCandidates(
      rawRows: rawRows,
      requestedLevels: {
        GeographicLevel.district,
        GeographicLevel.reportingState,
      },
    );

    final available = outcome as GeographicContextAvailable;

    expect(
      available.results[GeographicLevel.district],
      isA<GeographicLevelAmbiguous>(),
    );
    expect(
      available.results[GeographicLevel.reportingState],
      isA<GeographicLevelResolved>(),
    );
  });

  test('handles multi-state candidates as ambiguous reportingState', () {
    final rawRows = [
      createSampleRow(
        boundaryId: 'bnd_001',
        state: 'Selangor',
        district: 'Petaling',
      ),
      createSampleRow(
        boundaryId: 'bnd_002',
        state: 'Kuala Lumpur',
        district: 'KL Center',
      ),
    ];

    final outcome = resolver.processCandidates(
      rawRows: rawRows,
      requestedLevels: {
        GeographicLevel.district,
        GeographicLevel.reportingState,
      },
    );

    final available = outcome as GeographicContextAvailable;

    expect(
      available.results[GeographicLevel.district],
      isA<GeographicLevelAmbiguous>(),
    );
    expect(
      available.results[GeographicLevel.reportingState],
      isA<GeographicLevelAmbiguous>(),
    );
  });

  test(
    'returns GeographicContextUnavailable when provenance fields are missing',
    () {
      final invalidRow = createSampleRow();
      invalidRow.remove('source_version');

      final outcome = resolver.processCandidates(
        rawRows: [invalidRow],
        requestedLevels: {GeographicLevel.district},
      );

      expect(outcome, isA<GeographicContextUnavailable>());
      final unavailable = outcome as GeographicContextUnavailable;
      expect(unavailable.failure, GeographicContextFailure.versionUnverifiable);
    },
  );
  test('provider fake preserves partial results, exact levels and immutable candidates via resolve', () async {
    final production = resolver.processCandidates(
      rawRows: [createSampleRow()],
      requestedLevels: GeographicLevel.values.toSet(),
    ) as GeographicContextAvailable;
    final state =
        production.results[GeographicLevel.reportingState]
            as GeographicLevelResolved;
    final candidates = [state.area, state.area];
    final preset = <GeographicLevel, GeographicLevelOutcome>{
      GeographicLevel.district: const GeographicLevelUnresolved(
        GeographicContextFailure.noCoverage,
      ),
      GeographicLevel.reportingState: state,
    };
    final GeographicContext fake = FakeGeographicContext(
      presetOutcome: GeographicContextAvailable(preset),
    );
    const selected = ValidLocationReference(
      locationId: 'map-fixture',
      point: GeographicPoint(latitude: 3.1, longitude: 101.6),
    );
    final result = await fake.resolve(
      GeographicContextRequest(
        location: selected,
        levels: GeographicLevel.values.toSet(),
      ),
    ) as GeographicContextAvailable;
    preset.clear();
    expect(
      result.results[GeographicLevel.reportingState],
      isA<GeographicLevelResolved>(),
    );
    expect(
      (result.results[GeographicLevel.district] as GeographicLevelUnresolved)
          .failure,
      GeographicContextFailure.noCoverage,
    );
    expect(() => result.results.clear(), throwsUnsupportedError);
    final GeographicContext ambiguousFake = FakeGeographicContext(
      presetOutcome: GeographicContextAvailable({
        GeographicLevel.reportingState: GeographicLevelAmbiguous(
          candidates,
          state.provenance,
        ),
        GeographicLevel.district: const GeographicLevelUnresolved(
          GeographicContextFailure.noCoverage,
        ),
      }),
    );
    final ambiguous = await ambiguousFake.resolve(
      const GeographicContextRequest(
        location: selected,
        levels: {GeographicLevel.reportingState},
      ),
    ) as GeographicContextAvailable;
    candidates.clear();
    expect(ambiguous.results.keys, [GeographicLevel.reportingState]);
    final snapshot =
        ambiguous.results.values.single as GeographicLevelAmbiguous;
    expect(snapshot.candidates.length, 2);
    expect(() => snapshot.candidates.clear(), throwsUnsupportedError);
  });
}
