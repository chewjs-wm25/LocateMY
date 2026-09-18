


import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/location_models.dart';
import '../application/location_search.dart';

class GeoapifySearch implements LocationSearch {
  GeoapifySearch(String apiKey, http.Client client)
    : apiKey = apiKey,
      client = client;
  final String apiKey;
  final http.Client client;
  @override
  Future<LocationSearchOutcome> search(String query) async {
    if (query.trim().isEmpty) {
      return LocationSearchAvailable([]);
    }
    if (apiKey.isEmpty) {
      return const LocationSearchUnavailable();
    }
    try {
      final http.Response response = await client
          .get(
            Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
              'text': query.trim(),
              'filter': 'countrycode:my',
              'limit': '8',
              'apiKey': apiKey,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return const LocationSearchUnavailable();
      }
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> features = data['features'] as List<dynamic>;
      final List<LocationSearchCandidate> candidates =
          <LocationSearchCandidate>[];
      for (final dynamic feature in features) {
        final Map<String, dynamic> properties =
            feature['properties'] as Map<String, dynamic>;
        final GeographicPoint point = GeographicPoint(
          latitude: (properties['lat'] as num).toDouble(),
          longitude: (properties['lon'] as num).toDouble(),
        );
        final String displayName = properties['formatted'] as String;
        candidates.add(LocationSearchCandidate(point, displayName));
      }
      return LocationSearchAvailable(candidates);
    } catch (_) {
      return const LocationSearchUnavailable();
    }
  }
}
