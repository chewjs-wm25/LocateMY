import 'package:latlong2/latlong.dart';

enum FacilityCategory {
  healthcare,
  education,
  living,
  transport,
  safety,
  leisure,
  risk,
}

class NearbyFacility {
  final String name;
  final String type;
  final FacilityCategory category;
  final LatLng location;
  final double distance; // in meters
  final String? osmTag;
  final Map<String, dynamic>? metadata;

  NearbyFacility({
    required this.name,
    required this.type,
    required this.category,
    required this.location,
    required this.distance,
    this.osmTag,
    this.metadata,
  });

  factory NearbyFacility.fromOsmJson(Map<String, dynamic> json, LatLng center) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final name = tags['name'] ?? tags['operator'] ?? 'Unnamed ${json['type']}';
    final lat = json['lat'] ?? json['center']?['lat'];
    final lon = json['lon'] ?? json['center']?['lon'];
    final location = LatLng(lat, lon);
    
    // Calculate distance (simplified for now, or use a proper tool)
    const distanceCalculator = Distance();
    final distance = distanceCalculator.as(LengthUnit.Meter, center, location);

    return NearbyFacility(
      name: name,
      type: _determineType(tags),
      category: _determineCategory(tags),
      location: location,
      distance: distance.toDouble(),
      osmTag: _getMainTag(tags),
      metadata: tags,
    );
  }

  static FacilityCategory _determineCategory(Map<String, dynamic> tags) {
    if (tags.containsKey('amenity')) {
      final amenity = tags['amenity'];
      if (['hospital', 'clinic', 'doctors', 'pharmacy'].contains(amenity)) return FacilityCategory.healthcare;
      if (['school', 'university', 'college', 'kindergarten', 'childcare'].contains(amenity)) return FacilityCategory.education;
      if (['bank', 'atm', 'marketplace', 'food_court', 'restaurant'].contains(amenity)) return FacilityCategory.living;
      if (['police', 'fire_station', 'post_office'].contains(amenity)) return FacilityCategory.safety;
      if (['place_of_worship'].contains(amenity)) return FacilityCategory.leisure;
      if (['bus_stop', 'charging_station'].contains(amenity)) return FacilityCategory.transport;
    }
    if (tags.containsKey('shop')) {
      final shop = tags['shop'];
      if (['supermarket', 'convenience', 'mall', 'pharmacy'].contains(shop)) return FacilityCategory.living;
    }
    if (tags.containsKey('railway') || tags.containsKey('station')) return FacilityCategory.transport;
    if (tags.containsKey('leisure')) {
      final leisure = tags['leisure'];
      if (['park', 'garden', 'sports_centre', 'fitness_centre'].contains(leisure)) return FacilityCategory.leisure;
    }
    if (tags.containsKey('landuse') && tags['landuse'] == 'industrial') return FacilityCategory.risk;
    if (tags.containsKey('highway')) {
      final highway = tags['highway'];
      if (['bus_stop', 'motorway_junction'].contains(highway)) return FacilityCategory.transport;
    }
    if (tags.containsKey('barrier') && tags['barrier'] == 'toll_booth') return FacilityCategory.transport;
    
    return FacilityCategory.living; // Default
  }

  static String _determineType(Map<String, dynamic> tags) {
    return tags['amenity'] ?? tags['shop'] ?? tags['railway'] ?? tags['leisure'] ?? tags['highway'] ?? 'Facility';
  }

  static String? _getMainTag(Map<String, dynamic> tags) {
    if (tags.containsKey('amenity')) return 'amenity=${tags['amenity']}';
    if (tags.containsKey('shop')) return 'shop=${tags['shop']}';
    if (tags.containsKey('railway')) return 'railway=${tags['railway']}';
    if (tags.containsKey('leisure')) return 'leisure=${tags['leisure']}';
    return null;
  }
}
