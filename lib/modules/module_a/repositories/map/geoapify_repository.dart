import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:locate_my/core/api_keys.dart';
import 'package:locate_my/modules/module_a/models/map/geo_suggestion.dart';

class GeoapifyRepository {
  static const String _baseUrl = 'https://api.geoapify.com/v1/geocode';

  Future<List<GeoSuggestion>> getSuggestions(String text) async {
    if (text.isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl/autocomplete?text=${Uri.encodeComponent(text)}&filter=countrycode:my&apiKey=${ApiKeys.geoapify}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;
        return features
            .map((f) => GeoSuggestion.fromJson(f as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Geoapify autocomplete error: $e');
      return [];
    }
  }

  Future<GeoSuggestion?> search(String text) async {
    if (text.isEmpty) return null;

    final url = Uri.parse(
      '$_baseUrl/search?text=${Uri.encodeComponent(text)}&filter=countrycode:my&apiKey=${ApiKeys.geoapify}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;
        if (features.isNotEmpty) {
          return GeoSuggestion.fromJson(features.first as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Geoapify search error: $e');
      return null;
    }
  }
}
