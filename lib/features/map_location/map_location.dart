/// Public location-reference types shared by map consumers.
///
/// Map / Location owns construction and Malaysia-range validation of
/// [ValidLocationReference]. Consumers, including Geographic Context, must
/// treat a received reference as an immutable snapshot rather than read or
/// modify the map's mutable selection state.
library;

/// A WGS84 coordinate supplied by Map / Location.
final class GeographicPoint {
  final double latitude;
  final double longitude;

  const GeographicPoint({required this.latitude, required this.longitude});
}

/// A location that Map / Location has already validated for use in analysis.
///
/// Geographic Context uses [point] to resolve administrative context. The
/// optional [displayName] is presentation metadata and must not be used as an
/// input to geographic resolution or as a cache key.
final class ValidLocationReference {
  final String locationId;
  final GeographicPoint point;
  final String? displayName;

  const ValidLocationReference({
    required this.locationId,
    required this.point,
    this.displayName,
  });
}
