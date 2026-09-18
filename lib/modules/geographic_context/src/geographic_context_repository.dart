abstract interface class GeographicContextRepository {
  Future<List<Map<String, dynamic>>> fetchCandidates(
    double latitude,
    double longitude,
  );
}
