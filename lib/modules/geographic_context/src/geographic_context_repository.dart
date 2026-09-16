abstract interface class GeographicContextRepository {
  Future<List<Map<String, dynamic>>> fetchCandidates(double lat, double lng);
}
