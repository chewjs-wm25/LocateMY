// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'dart:typed_data';

import 'package:locatemy/features/map_location/map_location.dart';

final class PropertyRiskSnapshot {
  final Map<String, Object?> fields;
  PropertyRiskSnapshot(Map<String, Object?> fields)
    : fields = Map<String, Object?>.unmodifiable(fields);
  bool get available {
    return fields['snapshot_availability'] == 'available';
  }

  bool matches(ValidLocationReference location) {
    if (!available ||
        fields['snapshot_latitude'] != location.point.latitude ||
        fields['snapshot_longitude'] != location.point.longitude ||
        fields['safety_completeness'] != 'complete' ||
        fields['hazard_radius_m'] != 2000) {
      return false;
    }
    for (final String key in <String>[
      'reporting_state',
      'safety_source_id',
      'safety_model_boundary_version',
      'hazard_counted_at',
      'snapshot_captured_at',
    ]) {
      final Object? value = fields[key];
      if (value is! String || value.trim().isEmpty) {
        return false;
      }
    }
    final Object? score = fields['safety_index'];
    final Object? count = fields['hazard_pending_count'];
    return score is num &&
        score.isFinite &&
        score >= 0 &&
        score <= 100 &&
        count is int &&
        count >= 0 &&
        fields['safety_source_year'] is int;
  }

  factory PropertyRiskSnapshot.unavailable(DateTime time) {
    return PropertyRiskSnapshot(<String, Object?>{
      'snapshot_availability': 'unavailable',
      'snapshot_captured_at': time.toUtc().toIso8601String(),
    });
  }
}

final class PropertyInspectionDraft {
  final String name, address, notes;
  final double price;
  final ValidLocationReference location;
  final int drainage, waterproofing, humidity, lighting;
  final bool floodRisk;
  const PropertyInspectionDraft({
    required String name,
    required String address,
    required double price,
    required ValidLocationReference location,
    String notes = '',
    int drainage = 3,
    int waterproofing = 3,
    int humidity = 3,
    int lighting = 3,
    bool floodRisk = false,
  }) : name = name,
       address = address,
       price = price,
       location = location,
       notes = notes,
       drainage = drainage,
       waterproofing = waterproofing,
       humidity = humidity,
       lighting = lighting,
       floodRisk = floodRisk;
  void validate() {
    final GeographicPoint point = location.point;
    if (name.trim().isEmpty ||
        name.trim().length > 200 ||
        address.trim().isEmpty ||
        !price.isFinite ||
        price < 0 ||
        !point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      throw const PropertyFailure('invalid');
    }
    for (final int score in <int>[
      drainage,
      waterproofing,
      humidity,
      lighting,
    ]) {
      if (score < 1 || score > 5) {
        throw const PropertyFailure('invalid');
      }
    }
  }
}

final class PropertyInspectionRecord {
  final String id;
  final PropertyInspectionDraft draft;
  final PropertyRiskSnapshot snapshot;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<PropertyPhoto> photos;
  PropertyInspectionRecord({
    required String id,
    required PropertyInspectionDraft draft,
    required PropertyRiskSnapshot snapshot,
    required DateTime createdAt,
    DateTime? deletedAt,
    List<PropertyPhoto> photos = const <PropertyPhoto>[],
  }) : id = id,
       draft = draft,
       snapshot = snapshot,
       createdAt = createdAt,
       deletedAt = deletedAt,
       photos = List<PropertyPhoto>.unmodifiable(photos);
  String get name {
    return draft.name;
  }

  String get address {
    return draft.address;
  }

  double get price {
    return draft.price;
  }

  double get rating {
    return (draft.drainage +
            draft.waterproofing +
            draft.humidity +
            draft.lighting) /
        4;
  }

  String get notes {
    return draft.notes;
  }

  ValidLocationReference get location {
    return draft.location;
  }

  PropertyPhoto? get cover {
    for (final PropertyPhoto photo in photos) {
      if (photo.isCover && photo.uploaded) {
        return photo;
      }
    }
    for (final PropertyPhoto photo in photos) {
      if (photo.uploaded) {
        return photo;
      }
    }
    return null;
  }
}

final class PropertyPhoto {
  final String id, path, caption;
  final bool isCover, uploaded;
  final DateTime createdAt;
  final String? url;
  const PropertyPhoto({
    required String id,
    required String path,
    required DateTime createdAt,
    String caption = '',
    bool isCover = false,
    bool uploaded = true,
    String? url,
  }) : id = id,
       path = path,
       createdAt = createdAt,
       caption = caption,
       isCover = isCover,
       uploaded = uploaded,
       url = url;
}

final class PropertyPickedPhoto {
  final Uint8List _bytes;
  PropertyPickedPhoto(Uint8List bytes) : _bytes = Uint8List.fromList(bytes);
  Uint8List get bytes {
    return Uint8List.fromList(_bytes);
  }
}

enum PropertyPhotoSource { camera, gallery }

abstract interface class PropertyPhotoPicker {
  Future<PropertyPickedPhoto?> pick(PropertyPhotoSource source);
}

final class PropertyFailure implements Exception {
  final String code;
  final String? item;
  const PropertyFailure(String code, {String? item}) : code = code, item = item;
  @override
  String toString() {
    return 'PropertyFailure($code)';
  }
}

final class PropertyPurgeResult {
  final List<String> completed, remaining;
  PropertyPurgeResult(List<String> completed, List<String> remaining)
    : completed = List<String>.unmodifiable(completed),
      remaining = List<String>.unmodifiable(remaining);
}
