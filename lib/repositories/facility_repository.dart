import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/nearby_facility.dart';

class FacilityRepository {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<List<NearbyFacility>> getNearbyFacilities(LatLng location, {double radius = 2000}) async {
    final query = '''
      [out:json][timeout:25];
      (
        node(around:$radius, ${location.latitude}, ${location.longitude})["amenity"];
        way(around:$radius, ${location.latitude}, ${location.longitude})["amenity"];
        node(around:$radius, ${location.latitude}, ${location.longitude})["shop"~"supermarket|convenience|mall|pharmacy"];
        way(around:$radius, ${location.latitude}, ${location.longitude})["shop"~"supermarket|convenience|mall|pharmacy"];
        node(around:$radius, ${location.latitude}, ${location.longitude})["railway"="station"];
        node(around:$radius, ${location.latitude}, ${location.longitude})["highway"~"bus_stop|motorway_junction"];
        node(around:$radius, ${location.latitude}, ${location.longitude})["barrier"="toll_booth"];
        node(around:$radius, ${location.latitude}, ${location.longitude})["leisure"~"park|garden|sports_centre|fitness_centre"];
        way(around:$radius, ${location.latitude}, ${location.longitude})["leisure"~"park|garden|sports_centre|fitness_centre"];
        node(around:$radius, ${location.latitude}, ${location.longitude})["landuse"="industrial"];
        way(around:$radius, ${location.latitude}, ${location.longitude})["landuse"="industrial"];
      );
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>;
        
        return elements
            .map((e) => NearbyFacility.fromOsmJson(e as Map<String, dynamic>, location))
            .toList();
      } else {
        throw Exception('Failed to load facilities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching facilities: $e');
      return [];
    }
  }
}
