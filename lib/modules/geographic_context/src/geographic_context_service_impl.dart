import 'geographic_context_models.dart';
import 'geographic_context_repository.dart';
import 'geographic_context_resolver.dart';

final class GeographicContextServiceImpl implements GeographicContext {
  final GeographicContextRepository _repository;
  final GeographicContextResolver _resolver;

  GeographicContextServiceImpl(
    GeographicContextRepository repository, {
    GeographicContextResolver? resolver,
  }) : _repository = repository,
       _resolver = resolver ?? GeographicContextResolver();

  @override
  Future<GeographicContextOutcome> resolve(
    GeographicContextRequest request,
  ) async {
    final Set<GeographicLevel> levels = Set<GeographicLevel>.unmodifiable(
      request.levels,
    );
    if (levels.isEmpty) {
      throw ArgumentError.value(levels, 'levels', 'must not be empty');
    }
    try {
      final List<Map<String, dynamic>> rows = await _repository.fetchCandidates(
        request.location.point.latitude,
        request.location.point.longitude,
      );
      return _resolver.processCandidates(
        rawRows: rows,
        requestedLevels: levels,
      );
    } on GeographicContextFailure catch (failure) {
      return GeographicContextUnavailable(failure);
    }
  }
}
