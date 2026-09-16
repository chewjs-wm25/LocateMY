import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'geographic_context_resolver.dart';
import 'supabase_geo_repository.dart';

class GeographicContextServiceImpl implements GeographicContext {
  final SupabaseGeoRepository _repository;
  final GeographicContextResolver _resolver = GeographicContextResolver();

  final Map<String, GeographicContextOutcome> _cache = {};

  GeographicContextServiceImpl(this._repository);

  @override
  Future<GeographicContextOutcome> resolve(GeographicContextRequest request) async {
    final lat = request.location.point.latitude;
    final lng = request.location.point.longitude;

    final cacheKey = '$lat,$lng:${request.levels.map((e) => e.name).join(',')}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final rows = await _repository.fetchCandidates(lat, lng);
      final outcome = _resolver.processCandidates(
        rawRows: rows,
        requestedLevels: request.levels,
      );

      _cache[cacheKey] = outcome;
      return outcome;
    } on GeographicContextFailure catch (failure) {
      return GeographicContextUnavailable(failure);
    }
  }
}