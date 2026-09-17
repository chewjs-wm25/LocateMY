// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:locatemy/features/property_inspection/property_inspection.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:locatemy/features/hazard_reporting/hazard_reporting.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

void main() {
  test('real CRUD risk snapshot photo Storage metadata owner deny and recycle lifecycle', () async {
    HttpOverrides.global = null;
    sqfliteFfiInit();
    final Map<String, String> env = Platform.environment;
    SupabaseClient client() {
      return SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }

    final SupabaseClient a = client(), b = client(), anon = client();
    final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
    );
    String? id;
    try {
      await a.auth.signInWithPassword(
        email: env['LOCATEMY_EMAIL']!,
        password: env['LOCATEMY_PASSWORD']!,
      );
      await b.auth.signInWithPassword(
        email: env['LOCATEMY_OTHER_EMAIL']!,
        password: env['LOCATEMY_OTHER_PASSWORD']!,
      );
      final PropertyInspectionService service = PropertyInspectionService(
        store: SupabasePropertyStore(a),
        risk: PropertyBusinessRiskReader(
          geo: createGeographicContext(a),
          crime: createCrimeSecurity(
            geographicContext: createGeographicContext(a),
            reader: SupabaseSafetyInputsReader(a),
            database: db,
          ),
          hazards: createHazardRiskCounter(
            store: createSupabaseHazardStore(a),
            currentAccountId: () {
              return a.auth.currentUser?.id;
            },
          ),
        ),
      );
      const ValidLocationReference location = ValidLocationReference(
        locationId: 'live',
        point: GeographicPoint(latitude: 3.0738, longitude: 101.6077),
      );
      final PropertyInspectionRecord saved = await service.save(
        const PropertyInspectionDraft(
          name: 'QA Property Live',
          address: 'Petaling',
          price: 520000,
          location: location,
          drainage: 4,
          waterproofing: 4,
          humidity: 3,
          lighting: 5,
        ),
      );
      id = saved.id;
      print('PROPERTY_LIVE: created');
      expect(saved.rating, 4);
      expect(saved.snapshot.available, true);
      final Object? captured = saved.snapshot.fields['snapshot_captured_at'];
      final PropertyInspectionRecord edited = await service.save(
        const PropertyInspectionDraft(
          name: 'QA Property Edited',
          address: 'Petaling',
          price: 1,
          location: location,
        ),
        id: id,
      );
      print('PROPERTY_LIVE: edited');
      expect(edited.snapshot.fields['snapshot_captured_at'], captured);
      expect(
        await b.from('property_inspections').select().eq('id', id),
        isEmpty,
      );
      await expectLater(
        anon.rpc('read_property_inspections'),
        throwsA(isA<PostgrestException>()),
      );
      final Uint8List bytes = Uint8List.fromList(<int>[
        255,
        216,
        255,
        224,
        0,
        16,
        74,
        70,
        73,
        70,
        0,
        1,
        1,
        0,
        0,
        1,
        0,
        1,
        0,
        0,
        255,
        217,
      ]);
      print('PROPERTY_LIVE: owner deny done');
      await service.addPhoto(id, PropertyPickedPhoto(bytes));
      PropertyInspectionRecord read = await service.read(id);
      expect(read.photos.length, 1);
      expect(read.photos.single.uploaded, true);
      expect(read.cover, isNotNull);
      final PropertyPhoto photo = read.photos.single;
      expect(
        await a.storage.from('inspection-photos').download(photo.path),
        bytes,
      );
      await expectLater(
        b.storage.from('inspection-photos').download(photo.path),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        anon.storage.from('inspection-photos').download(photo.path),
        throwsA(isA<StorageException>()),
      );
      expect(
        await b.from('property_inspection_photos').select().eq('id', photo.id),
        isEmpty,
      );
      expect(
        await b
            .from('property_inspection_photos')
            .update(<String, Object?>{'caption': 'unauthorized'})
            .eq('id', photo.id)
            .select(),
        isEmpty,
      );
      await expectLater(
        b.storage
            .from('inspection-photos')
            .uploadBinary(
              photo.path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            ),
        throwsA(isA<StorageException>()),
      );
      print('PROPERTY_LIVE: photo storage deny done');
      await service.editPhoto(
        id,
        photo.id,
        caption: 'Living room',
        cover: true,
      );
      expect((await service.read(id)).photos.single.caption, 'Living room');
      print('PROPERTY_LIVE: caption done');
      await service.trash(id);
      expect(
        (await service.list()).any((PropertyInspectionRecord r) {
          return r.id == id;
        }),
        false,
      );
      expect(
        (await service.list(deleted: true)).any((PropertyInspectionRecord r) {
          return r.id == id;
        }),
        true,
      );
      expect(
        await a.storage.from('inspection-photos').download(photo.path),
        bytes,
      );
      await service.restore(id);
      expect((await service.read(id)).photos.length, 1);
      await service.trash(id);
      print('PROPERTY_LIVE: restored and trashed');
      final PropertyPurgeResult purged = await service.purge(<String>[id]);
      print(
        'PROPERTY_LIVE: purged completed=${purged.completed.length} remaining=${purged.remaining.length}',
      );
      expect(purged.remaining, isEmpty);
      expect(purged.completed, <String>[id]);
      id = null;
      expect(
        await a
            .from('property_inspection_photos')
            .select()
            .eq('inspection_id', saved.id),
        isEmpty,
      );
      expect(
        await a.storage
            .from('inspection-photos')
            .list(path: '${a.auth.currentUser!.id}/${saved.id}'),
        isEmpty,
      );
      id = null;
      print(
        'PROPERTY_LIVE: real CRUD complete risk persisted unchanged edit owner Storage metadata deny softdelete restore purge PASS',
      );
    } finally {
      if (id != null) {
        final SupabasePropertyStore store = SupabasePropertyStore(a);
        final PropertyInspectionRecord record = await store.read(id);
        for (final PropertyPhoto photo in record.photos) {
          await store.removeFile(photo.path);
          await store.removePhoto(photo.id);
        }
        await store.setDeleted(id, true);
        await store.removeInspection(id);
      }
      await db.close();
      await a.dispose();
      await b.dispose();
      await anon.dispose();
    }
  }, skip: Platform.environment['LOCATEMY_PROPERTY_LIVE'] != '1');
}
