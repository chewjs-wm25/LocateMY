

import '../domain/location_models.dart';


abstract interface class LocationSummaryReader {
  Future<List<LocationSummaryReading>> read(
    ValidLocationReference location,
    DateTime date,
  );
}

enum LocationSummaryMetric {
  safety,
  cost,
  facilities,
  transportation,
  infrastructure,
}

final class LocationSummaryReading {
  final LocationSummaryMetric metric;
  final String? english;
  final String? chinese;
  const LocationSummaryReading(
    LocationSummaryMetric metric, {
    String? english,
    String? chinese,
  }) : metric = metric,
       english = english,
       chinese = chinese;
}
