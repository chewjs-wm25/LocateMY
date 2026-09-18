// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import '../domain/location_models.dart';

/// The five native readings shown in expanded map location details.
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
