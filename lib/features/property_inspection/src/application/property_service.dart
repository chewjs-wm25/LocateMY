

import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/property_models.dart';

abstract interface class PropertyStore {
  Future<List<PropertyInspectionRecord>> list({bool deleted = false});
  Future<PropertyInspectionRecord> read(String id);
  Future<PropertyInspectionRecord> save(
    PropertyInspectionDraft draft,
    PropertyRiskSnapshot snapshot, {
    String? id,
  });
  Future<void> setDeleted(String id, bool deleted);
  Future<void> removeInspection(String id);
  Future<PropertyPhoto> reservePhoto(String inspectionId);
  Future<void> uploadPhoto(PropertyPhoto photo, PropertyPickedPhoto picked);
  Future<void> markUploaded(String photoId);
  Future<void> removeFile(String path);
  Future<void> removePhoto(String photoId);
  Future<void> editPhoto(
    String inspectionId,
    String photoId, {
    String? caption,
    bool cover = false,
  });
}

abstract interface class PropertyRiskReader {
  Future<PropertyRiskSnapshot> capture(ValidLocationReference location);
}

final class PropertyInspectionService {
  final PropertyStore _store;
  final PropertyRiskReader _risk;
  final Map<String, PropertyPickedPhoto> _retryBytes =
      <String, PropertyPickedPhoto>{};
  final Set<String> _busy = <String>{};
  PropertyInspectionService({
    required PropertyStore store,
    required PropertyRiskReader risk,
  }) : _store = store,
       _risk = risk;
  Future<List<PropertyInspectionRecord>> list({bool deleted = false}) async {
    return List<PropertyInspectionRecord>.unmodifiable(
      await _store.list(deleted: deleted),
    );
  }

  Future<PropertyInspectionRecord> read(String id) {
    return _store.read(id);
  }

  Future<PropertyInspectionRecord> save(
    PropertyInspectionDraft draft, {
    String? id,
  }) async {
    draft.validate();
    final PropertyInspectionRecord? old = id == null
        ? null
        : await _store.read(id);
    PropertyRiskSnapshot snapshot;
    if (old != null &&
        old.location.point.latitude == draft.location.point.latitude &&
        old.location.point.longitude == draft.location.point.longitude) {
      snapshot = old.snapshot;
    } else {
      try {
        snapshot = await _risk.capture(draft.location);
        if (snapshot.available && !snapshot.matches(draft.location)) {
          snapshot = PropertyRiskSnapshot.unavailable(DateTime.now());
        }
      } catch (_) {
        snapshot = PropertyRiskSnapshot.unavailable(DateTime.now());
      }
    }
    return _store.save(draft, snapshot, id: id);
  }

  Future<void> trash(String id) {
    return _setDeleted(id, true);
  }

  Future<void> restore(String id) {
    return _setDeleted(id, false);
  }

  Future<void> _setDeleted(String id, bool deleted) async {
    if (!_busy.add(id)) {
      throw const PropertyFailure('busy');
    }
    try {
      await _store.setDeleted(id, deleted);
    } finally {
      _busy.remove(id);
    }
  }

  Future<PropertyPurgeResult> purge(List<String> ids) async {
    final List<String> completed = <String>[];
    final List<String> remaining = <String>[];
    for (final String id in ids) {
      if (!_busy.add(id)) {
        remaining.add(id);
        continue;
      }
      try {
        final PropertyInspectionRecord record = await _store.read(id);
        if (record.deletedAt == null) {
          throw const PropertyFailure('active');
        }
        for (final PropertyPhoto photo in record.photos) {
          await _store.removeFile(photo.path);
          await _store.removePhoto(photo.id);
          _retryBytes.remove(photo.id);
        }
        await _store.removeInspection(id);
        completed.add(id);
      } catch (_) {
        remaining.add(id);
      } finally {
        _busy.remove(id);
      }
    }
    return PropertyPurgeResult(completed, remaining);
  }

  Future<PropertyPhoto> addPhoto(String id, PropertyPickedPhoto picked) async {
    if (!_busy.add(id)) {
      throw const PropertyFailure('busy');
    }
    try {
      final PropertyInspectionRecord record = await _store.read(id);
      if (record.deletedAt != null) {
        throw const PropertyFailure('deleted');
      }
      if (record.photos.length >= 20) {
        throw const PropertyFailure('photoLimit');
      }
      final PropertyPhoto photo = await _store.reservePhoto(id);
      _retryBytes[photo.id] = picked;
      await retryPhoto(photo);
      return photo;
    } finally {
      _busy.remove(id);
    }
  }

  Future<void> retryPhoto(PropertyPhoto photo) async {
    final PropertyPickedPhoto? bytes = _retryBytes[photo.id];
    if (bytes == null) {
      throw const PropertyFailure('chooseAgain');
    }
    try {
      await _store.uploadPhoto(photo, bytes);
      await _store.markUploaded(photo.id);
      _retryBytes.remove(photo.id);
    } catch (_) {
      throw PropertyFailure('upload', item: photo.path);
    }
  }

  Future<void> deletePhoto(String id, PropertyPhoto photo) async {
    await _store.removeFile(photo.path);
    await _store.removePhoto(photo.id);
    _retryBytes.remove(photo.id);
    await _ensureCover(id);
  }

  Future<void> _ensureCover(String id) async {
    final PropertyInspectionRecord record = await _store.read(id);
    if (record.cover != null) {
      await _store.editPhoto(id, record.cover!.id, cover: true);
    }
  }

  Future<void> editPhoto(
    String id,
    String photoId, {
    String? caption,
    bool cover = false,
  }) {
    if (caption != null && caption.length > 1000) {
      throw const PropertyFailure('caption');
    }
    return _store.editPhoto(id, photoId, caption: caption, cover: cover);
  }

  Future<List<PropertyInspectionRecord>> compare(List<String> ids) async {
    if (ids.toSet().length != ids.length || ids.length < 2 || ids.length > 3) {
      throw const PropertyFailure('comparison');
    }
    final List<PropertyInspectionRecord> records = <PropertyInspectionRecord>[];
    for (final String id in ids) {
      final PropertyInspectionRecord record = await read(id);
      if (record.deletedAt != null) {
        throw const PropertyFailure('comparison');
      }
      records.add(record);
    }
    return List<PropertyInspectionRecord>.unmodifiable(records);
  }
}
