import 'location.dart';

enum PhotoSource { camera, gallery }

enum PhotoSyncStatus { synced, pending, failed }

class InspectionPhoto {
  const InspectionPhoto({
    required this.id,
    required this.source,
    required this.label,
    this.caption = '',
    this.syncStatus = PhotoSyncStatus.synced,
  });

  final String id;
  final PhotoSource source;
  final String label;
  final String caption;
  final PhotoSyncStatus syncStatus;

  InspectionPhoto copyWith({String? caption, PhotoSyncStatus? syncStatus}) =>
      InspectionPhoto(
        id: id,
        source: source,
        label: label,
        caption: caption ?? this.caption,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}

class Property {
  const Property(
    this.name,
    this.price,
    this.place,
    this.score,
    this.safety,
    this.hazards,
    this.flood,
    this.note, {
    this.photos = const <InspectionPhoto>[],
    this.coverPhotoId,
  });

  final String name, note;
  final int price, safety, hazards;
  final Place place;
  final double score;
  final bool flood;
  final List<InspectionPhoto> photos;
  final String? coverPhotoId;

  InspectionPhoto? get coverPhoto {
    if (photos.isEmpty) return null;
    for (final photo in photos) {
      if (photo.id == coverPhotoId) return photo;
    }
    return photos.first;
  }

  Property copyWith({
    String? name,
    int? price,
    Place? place,
    double? score,
    bool? flood,
    String? note,
    List<InspectionPhoto>? photos,
    String? coverPhotoId,
  }) => Property(
    name ?? this.name,
    price ?? this.price,
    place ?? this.place,
    score ?? this.score,
    safety,
    hazards,
    flood ?? this.flood,
    note ?? this.note,
    photos: photos ?? this.photos,
    coverPhotoId: coverPhotoId ?? this.coverPhotoId,
  );
}
