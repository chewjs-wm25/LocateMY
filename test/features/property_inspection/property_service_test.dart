import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/property_inspection/property_inspection.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  test('saved inspection is retrievable with four-rating average and unavailable snapshot', () async {
    final MemoryPropertyStore store = MemoryPropertyStore();
    final PropertyInspectionService service = PropertyInspectionService(
      store: store,
      risk: UnavailablePropertyRisk(),
    );
    final PropertyInspectionRecord saved = await service.save(
      const PropertyInspectionDraft(
        name: 'House',
        address: 'Street',
        price: 520000,
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
        ),
        drainage: 4,
        waterproofing: 4,
        humidity: 3,
        lighting: 5,
      ),
    );
    final PropertyInspectionRecord read = await service.read(saved.id);
    expect(read.rating, 4);
    expect(read.snapshot.available, false);
  });
  test('risk from a different coordinate cannot be persisted as this property snapshot', () async {
    final PropertyInspectionService service = PropertyInspectionService(
      store: MemoryPropertyStore(),
      risk: WrongCoordinateRisk(),
    );
    final PropertyInspectionRecord saved = await service.save(
      const PropertyInspectionDraft(
        name: 'House',
        address: 'Street',
        price: 1,
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ),
    );
    expect(saved.snapshot.available, false);
  });
  test(
    'restore cannot revive a record while permanent purge is in progress',
    () async {
      final BlockingPropertyStore store = BlockingPropertyStore();
      final PropertyInspectionService service = PropertyInspectionService(
        store: store,
        risk: UnavailablePropertyRisk(),
      );
      final PropertyInspectionRecord saved = await service.save(
        const PropertyInspectionDraft(
          name: 'House',
          address: 'Street',
          price: 1,
          location: ValidLocationReference(
            locationId: 'a',
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
        ),
      );
      await service.trash(saved.id);
      final Future<PropertyPurgeResult> purge = service.purge(<String>[
        saved.id,
      ]);
      await store.started.future;
      await expectLater(
        service.restore(saved.id),
        throwsA(isA<PropertyFailure>()),
      );
      store.release.complete();
      expect((await purge).completed, <String>[saved.id]);
    },
  );

  test('ordinary edits and reads retain risk but changed coordinate failure clears it', () async {
    final CountingRisk risk = CountingRisk();
    final PropertyInspectionService service = PropertyInspectionService(
      store: MemoryPropertyStore(),
      risk: risk,
    );
    const ValidLocationReference a = ValidLocationReference(
      locationId: 'a',
      point: GeographicPoint(latitude: 3, longitude: 101),
    );
    final PropertyInspectionRecord saved = await service.save(
      const PropertyInspectionDraft(
        name: 'A',
        address: 'Street',
        price: 0,
        location: a,
      ),
    );
    risk.fail = true;
    final PropertyInspectionRecord edit = await service.save(
      const PropertyInspectionDraft(
        name: 'B',
        address: 'Changed text',
        price: 1,
        location: ValidLocationReference(
          locationId: 'another-id',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ),
      id: saved.id,
    );
    await service.list();
    await service.read(saved.id);
    expect(edit.snapshot.available, true);
    expect(risk.requests, 1);
    final PropertyInspectionRecord changed = await service.save(
      const PropertyInspectionDraft(
        name: 'B',
        address: 'Changed',
        price: 1,
        location: ValidLocationReference(
          locationId: 'b',
          point: GeographicPoint(latitude: 4, longitude: 102),
        ),
      ),
      id: saved.id,
    );
    expect(changed.snapshot.available, false);
    expect(changed.snapshot.fields['safety_index'], isNull);
    expect(risk.requests, 2);
  });
  test('failed Storage purge retains photo path and parent; online retry completes', () async {
    final PhotoMemoryStore store = PhotoMemoryStore();
    final PropertyInspectionService service = PropertyInspectionService(
      store: store,
      risk: UnavailablePropertyRisk(),
    );
    final PropertyInspectionRecord record = await service.save(
      const PropertyInspectionDraft(
        name: 'A',
        address: 'Street',
        price: 0,
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ),
    );
    await service.addPhoto(
      record.id,
      PropertyPickedPhoto(Uint8List.fromList(<int>[1, 2, 3])),
    );
    await service.trash(record.id);
    store.failDelete = true;
    expect((await service.purge(<String>[record.id])).remaining, <String>[
      record.id,
    ]);
    expect(
      (await service.read(record.id)).photos.single.path,
      'id-0/photo-0.jpg',
    );
    store.failDelete = false;
    expect((await service.purge(<String>[record.id])).completed, <String>[
      record.id,
    ]);
  });
  test('incomplete upload remains visible and same path retries without duplicating photos', () async {
    final PhotoMemoryStore store = PhotoMemoryStore();
    final PropertyInspectionService service = PropertyInspectionService(
      store: store,
      risk: UnavailablePropertyRisk(),
    );
    final PropertyInspectionRecord record = await service.save(
      const PropertyInspectionDraft(
        name: 'A',
        address: 'Street',
        price: 0,
        location: ValidLocationReference(
          locationId: 'a',
          point: GeographicPoint(latitude: 3, longitude: 101),
        ),
      ),
    );
    store.failUpload = true;
    await expectLater(
      service.addPhoto(
        record.id,
        PropertyPickedPhoto(Uint8List.fromList(<int>[1, 2, 3])),
      ),
      throwsA(isA<PropertyFailure>()),
    );
    final PropertyPhoto photo = (await service.read(record.id)).photos.single;
    expect(photo.uploaded, false);
    store.failUpload = false;
    await service.retryPhoto(photo);
    final PropertyInspectionRecord read = await service.read(record.id);
    expect(read.photos.length, 1);
    expect(read.photos.single.uploaded, true);
    expect(read.cover?.path, photo.path);
  });
  test('twenty photos is a hard limit and comparison requires two or three active unique records', () async {
    final PhotoMemoryStore store = PhotoMemoryStore();
    final PropertyInspectionService service = PropertyInspectionService(
      store: store,
      risk: UnavailablePropertyRisk(),
    );
    const PropertyInspectionDraft draft = PropertyInspectionDraft(
      name: 'A',
      address: 'Street',
      price: 0,
      location: ValidLocationReference(
        locationId: 'a',
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    );
    final PropertyInspectionRecord a = await service.save(draft);
    final PropertyInspectionRecord b = await service.save(draft);
    for (int i = 0; i < 20; i++) {
      await service.addPhoto(
        a.id,
        PropertyPickedPhoto(Uint8List.fromList(<int>[1, 2, 3])),
      );
    }
    await expectLater(
      service.addPhoto(
        a.id,
        PropertyPickedPhoto(Uint8List.fromList(<int>[1, 2, 3])),
      ),
      throwsA(isA<PropertyFailure>()),
    );
    expect((await service.read(a.id)).photos.length, 20);
    final List<PropertyInspectionRecord> compare = await service.compare(
      <String>[a.id, b.id],
    );
    expect(compare.length, 2);
    expect(() {
      compare.clear();
    }, throwsUnsupportedError);
    await expectLater(
      service.compare(<String>[a.id, a.id]),
      throwsA(isA<PropertyFailure>()),
    );
    await service.trash(b.id);
    await expectLater(
      service.compare(<String>[a.id, b.id]),
      throwsA(isA<PropertyFailure>()),
    );
  });
}

class UnavailablePropertyRisk implements PropertyRiskReader {
  @override
  Future<PropertyRiskSnapshot> capture(ValidLocationReference location) async {
    return PropertyRiskSnapshot.unavailable(DateTime.utc(2026, 9, 18));
  }
}

class MemoryPropertyStore implements PropertyStore {
  final Map<String, PropertyInspectionRecord> records =
      <String, PropertyInspectionRecord>{};
  @override
  Future<List<PropertyInspectionRecord>> list({bool deleted = false}) async {
    return records.values.where((PropertyInspectionRecord r) {
      return (r.deletedAt != null) == deleted;
    }).toList();
  }

  @override
  Future<PropertyInspectionRecord> read(String id) async {
    return records[id]!;
  }

  @override
  Future<PropertyInspectionRecord> save(
    PropertyInspectionDraft draft,
    PropertyRiskSnapshot snapshot, {
    String? id,
  }) async {
    final String key = id ?? 'id-${records.length}';
    final PropertyInspectionRecord r = PropertyInspectionRecord(
      id: key,
      draft: draft,
      snapshot: snapshot,
      createdAt: DateTime.utc(2026),
    );
    records[key] = r;
    return r;
  }

  @override
  Future<void> setDeleted(String id, bool deleted) async {
    final PropertyInspectionRecord r = records[id]!;
    records[id] = PropertyInspectionRecord(
      id: id,
      draft: r.draft,
      snapshot: r.snapshot,
      createdAt: r.createdAt,
      photos: r.photos,
      deletedAt: deleted ? DateTime.utc(2026) : null,
    );
  }

  @override
  Future<void> removeInspection(String id) async {
    records.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class BlockingPropertyStore extends MemoryPropertyStore {
  final Completer<void> started = Completer<void>(),
      release = Completer<void>();
  @override
  Future<void> removeInspection(String id) async {
    started.complete();
    await release.future;
    await super.removeInspection(id);
  }
}

class WrongCoordinateRisk implements PropertyRiskReader {
  @override
  Future<PropertyRiskSnapshot> capture(ValidLocationReference location) async {
    return PropertyRiskSnapshot(<String, Object?>{
      'snapshot_availability': 'available',
      'snapshot_latitude': 4.0,
      'snapshot_longitude': 102.0,
    });
  }
}

class CountingRisk implements PropertyRiskReader {
  int requests = 0;
  bool fail = false;
  @override
  Future<PropertyRiskSnapshot> capture(ValidLocationReference location) async {
    requests++;
    if (fail) {
      throw const PropertyFailure('risk');
    }
    return PropertyRiskSnapshot(<String, Object?>{
      'snapshot_availability': 'available',
      'snapshot_latitude': location.point.latitude,
      'snapshot_longitude': location.point.longitude,
      'safety_index': 74.0,
      'safety_source_year': 2025,
      'safety_source_id': 'known-source',
      'safety_model_boundary_version': 'model/boundary',
      'reporting_state': 'Selangor',
      'safety_completeness': 'complete',
      'hazard_pending_count': 2,
      'hazard_radius_m': 2000,
      'hazard_counted_at': '2026-09-18T00:00:00Z',
      'snapshot_captured_at': '2026-09-18T00:00:00Z',
    });
  }
}

class PhotoMemoryStore extends MemoryPropertyStore {
  final Map<String, List<PropertyPhoto>> allPhotos =
      <String, List<PropertyPhoto>>{};
  bool failUpload = false, failDelete = false;
  @override
  Future<PropertyInspectionRecord> read(String id) async {
    final PropertyInspectionRecord r = await super.read(id);
    return PropertyInspectionRecord(
      id: r.id,
      draft: r.draft,
      snapshot: r.snapshot,
      createdAt: r.createdAt,
      deletedAt: r.deletedAt,
      photos: allPhotos[id] ?? <PropertyPhoto>[],
    );
  }

  @override
  Future<PropertyPhoto> reservePhoto(String inspectionId) async {
    final List<PropertyPhoto> photos = allPhotos.putIfAbsent(inspectionId, () {
      return <PropertyPhoto>[];
    });
    final String photoId = 'photo-${photos.length}';
    final PropertyPhoto photo = PropertyPhoto(
      id: photoId,
      path: '$inspectionId/$photoId.jpg',
      createdAt: DateTime.utc(2026),
      uploaded: false,
    );
    photos.add(photo);
    return photo;
  }

  @override
  Future<void> uploadPhoto(
    PropertyPhoto photo,
    PropertyPickedPhoto picked,
  ) async {
    if (failUpload) {
      throw const PropertyFailure('network');
    }
  }

  @override
  Future<void> markUploaded(String id) async {
    for (final List<PropertyPhoto> photos in allPhotos.values) {
      for (int i = 0; i < photos.length; i++) {
        final PropertyPhoto p = photos[i];
        if (p.id == id) {
          photos[i] = PropertyPhoto(
            id: p.id,
            path: p.path,
            createdAt: p.createdAt,
            uploaded: true,
            isCover: true,
          );
        }
      }
    }
  }

  @override
  Future<void> removeFile(String path) async {
    if (failDelete) {
      throw const PropertyFailure('network');
    }
  }

  @override
  Future<void> removePhoto(String id) async {
    for (final List<PropertyPhoto> photos in allPhotos.values) {
      photos.removeWhere((PropertyPhoto p) {
        return p.id == id;
      });
    }
  }

  @override
  Future<void> editPhoto(
    String inspectionId,
    String photoId, {
    String? caption,
    bool cover = false,
  }) async {}
}
