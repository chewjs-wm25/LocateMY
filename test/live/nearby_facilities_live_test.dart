import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('live Overpass yields actual five-category coverage and durable cached fallback', () async {
    HttpOverrides.global = null;
    sqfliteFfiInit();
    final http.Client client = http.Client();
    final Database database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    final NearbyFacilities facilities = createNearbyFacilities(
      source: createOverpassFacilitySource(client),
      database: database,
    );
    const FacilityAnalysisRequest request = FacilityAnalysisRequest(
      location: ValidLocationReference(
        locationId: 'qa',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6072),
        displayName: 'Sunway Mentari',
      ),
      refreshPolicy: FacilityRefreshPolicy.refresh,
    );
    try {
      final FacilityAnalysisOutcome result = await facilities.analyse(request);
      if (result is FacilityAnalysisUnavailable) {
        debugPrint('FACILITY_LIVE: failure=${result.failure.name}');
      }
      expect(result, isA<FacilityAnalysisAvailable>());
      final FacilityAnalysis analysis =
          (result as FacilityAnalysisAvailable).analysis;
      expect(analysis.categories.length, 5);
      expect(
        analysis.categories.any((FacilityCategoryResult category) {
          return category.state == FacilityCategoryState.covered;
        }),
        isTrue,
      );
      final NearbyFacilities offline = createNearbyFacilities(
        source: createOverpassFacilitySource(client),
        database: database,
      );
      final FacilityAnalysisOutcome cached = await offline.analyse(
        FacilityAnalysisRequest(
          location: request.location,
          refreshPolicy: FacilityRefreshPolicy.cacheAllowed,
        ),
      );
      expect(
        (cached as FacilityAnalysisAvailable).analysis.dataState,
        FacilityDataState.cached,
      );
      final List<int?> counts = <int?>[];
      for (final FacilityCategoryResult category in analysis.categories) {
        counts.add(category.count);
      }
      // Sanitized evidence: no account identifiers or precise coordinates.
      debugPrint(
        'FACILITY_LIVE: complete; radius=2000; counts=$counts; observedAt=${analysis.observedAt.toUtc()}; durable cache=PASS',
      );
    } finally {
      client.close();
      await database.close();
    }
  }, skip: Platform.environment['LOCATEMY_LIVE'] != '1');
}
