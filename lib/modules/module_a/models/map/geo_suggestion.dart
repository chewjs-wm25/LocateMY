import 'package:latlong2/latlong.dart';

class GeoSuggestion {
  final String name;
  final String label;
  final LatLng location;

  GeoSuggestion({
    required this.name,
    required this.label,
    required this.location,
  });

  factory GeoSuggestion.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'];
    final geometry = json['geometry'];
    final coordinates = geometry['coordinates'] as List<dynamic>;

    return GeoSuggestion(
      name:
          properties['name'] ??
          properties['city'] ??
          properties['street'] ??
          'Unknown',
      label: properties['formatted'] ?? 'Unknown address',
      location: LatLng(coordinates[1] as double, coordinates[0] as double),
    );
  }
}
