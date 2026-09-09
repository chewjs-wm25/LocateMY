import 'package:latlong2/latlong.dart';

class SavedLocation {
  final String id;
  final String name;
  final LatLng location;
  final bool synced;
  final DateTime? createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.location,
    this.synced = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'synced': synced ? 1 : 0,
      'created_at':
          createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      location: LatLng(map['latitude'] as double, map['longitude'] as double),
      synced: map['synced'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
    );
  }

  SavedLocation copyWith({
    String? id,
    String? name,
    LatLng? location,
    bool? synced,
    DateTime? createdAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
