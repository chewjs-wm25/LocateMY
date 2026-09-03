import 'package:latlong2/latlong.dart';

enum HazardType { flood, crime, traffic, infrastructure, other }

class HazardMarker {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final HazardType type;
  final int upvotes;
  final int downvotes;
  final String createdBy;
  final DateTime createdAt;

  HazardMarker({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdBy,
    required this.createdAt,
  });

  HazardMarker copyWith({
    String? title,
    String? description,
    HazardType? type,
    int? upvotes,
    int? downvotes,
  }) {
    return HazardMarker(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location,
      type: type ?? this.type,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
