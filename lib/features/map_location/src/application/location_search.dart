


import '../domain/location_models.dart';

abstract interface class LocationSearch {
  Future<LocationSearchOutcome> search(String query);
}

sealed class LocationSearchOutcome {
  const LocationSearchOutcome();
}

final class LocationSearchAvailable extends LocationSearchOutcome {
  final List<LocationSearchCandidate> candidates;
  LocationSearchAvailable(Iterable<LocationSearchCandidate> candidates)
    : candidates = List.unmodifiable(candidates);
}

final class LocationSearchUnavailable extends LocationSearchOutcome {
  const LocationSearchUnavailable();
}

final class LocationSearchCandidate {
  final GeographicPoint point;
  final String displayName;
  const LocationSearchCandidate(GeographicPoint point, String displayName)
    : point = point,
      displayName = displayName;
}
