// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../application/property_service.dart';
import '../domain/property_models.dart';

final class SupabasePropertyStore implements PropertyStore {
  final SupabaseClient client;
  final String? _accountId;
  SupabasePropertyStore(SupabaseClient client)
    : client = client,
      _accountId = client.auth.currentUser?.id;
  String get owner {
    final String? id = client.auth.currentUser?.id;
    if (id == null || id != _accountId) {
      throw const PropertyFailure('auth');
    }
    return id;
  }

  @override
  Future<List<PropertyInspectionRecord>> list({bool deleted = false}) async {
    owner;
    final List<dynamic> rows = await client.rpc(
      'read_property_inspections',
      params: <String, Object?>{'p_deleted': deleted},
    );
    final List<PropertyInspectionRecord> results = <PropertyInspectionRecord>[];
    for (final dynamic row in rows) {
      results.add(await _record(Map<String, dynamic>.from(row as Map)));
    }
    return results;
  }

  @override
  Future<PropertyInspectionRecord> read(String id) async {
    owner;
    final List<dynamic> rows = await client.rpc(
      'read_property_inspections',
      params: <String, Object?>{'p_id': id, 'p_deleted': null},
    );
    if (rows.length != 1) {
      throw const PropertyFailure('notFound');
    }
    return _record(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<PropertyInspectionRecord> _record(Map<String, dynamic> row) async {
    owner;
    final List<Map<String, dynamic>> photoRows = await client
        .from('property_inspection_photos')
        .select()
        .eq('inspection_id', row['id'] as String)
        .order('created_at')
        .order('id');
    final List<PropertyPhoto> photos = <PropertyPhoto>[];
    for (final Map<String, dynamic> photo in photoRows) {
      String? url;
      if (photo['upload_complete'] == true) {
        try {
          url = await client.storage
              .from('inspection-photos')
              .createSignedUrl(photo['storage_path'] as String, 3600);
        } catch (_) {
          url = null;
        }
      }
      photos.add(
        PropertyPhoto(
          id: photo['id'] as String,
          path: photo['storage_path'] as String,
          createdAt: DateTime.parse(photo['created_at'] as String),
          caption: photo['caption'] as String? ?? '',
          isCover: photo['is_cover'] as bool,
          uploaded: photo['upload_complete'] as bool,
          url: url,
        ),
      );
    }
    final Map<String, Object?> snapshot = <String, Object?>{};
    for (final String key in snapshotKeys) {
      snapshot[key] = row[key];
    }
    return PropertyInspectionRecord(
      id: row['id'] as String,
      draft: PropertyInspectionDraft(
        name: row['property_name'] as String,
        address: row['address'] as String? ?? '',
        price: (row['price'] as num).toDouble(),
        location: ValidLocationReference(
          locationId: row['id'] as String,
          point: GeographicPoint(
            latitude: (row['latitude'] as num).toDouble(),
            longitude: (row['longitude'] as num).toDouble(),
          ),
          displayName: row['address'] as String?,
        ),
        drainage: row['drainage_rating'] as int,
        waterproofing: row['waterproofing_rating'] as int,
        humidity: row['humidity_rating'] as int,
        lighting: row['lighting_rating'] as int,
        floodRisk: row['flood_evidence'] as bool,
        notes: row['notes'] as String? ?? '',
      ),
      snapshot: PropertyRiskSnapshot(snapshot),
      createdAt: DateTime.parse(row['created_at'] as String),
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String),
      photos: photos,
    );
  }

  @override
  Future<PropertyInspectionRecord> save(
    PropertyInspectionDraft draft,
    PropertyRiskSnapshot snapshot, {
    String? id,
  }) async {
    final Map<String, Object?> data = <String, Object?>{
      'user_id': owner,
      'property_name': draft.name.trim(),
      'address': draft.address.trim(),
      'location':
          'SRID=4326;POINT(${draft.location.point.longitude} ${draft.location.point.latitude})',
      'price': draft.price,
      'drainage_rating': draft.drainage,
      'waterproofing_rating': draft.waterproofing,
      'humidity_rating': draft.humidity,
      'lighting_rating': draft.lighting,
      'flood_evidence': draft.floodRisk,
      'notes': draft.notes,
    };
    for (final String key in snapshotKeys) {
      data[key] = snapshot.fields[key];
    }
    final Map<String, dynamic> row;
    if (id == null) {
      row = await client
          .from('property_inspections')
          .insert(data)
          .select('id')
          .single();
    } else {
      row = await client
          .from('property_inspections')
          .update(data)
          .eq('id', id)
          .eq('user_id', owner)
          .select('id')
          .single();
    }
    return read(row['id'] as String);
  }

  @override
  Future<void> setDeleted(String id, bool deleted) async {
    await client
        .from('property_inspections')
        .update(<String, Object?>{
          'deleted_at': deleted
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', id)
        .eq('user_id', owner)
        .select('id')
        .single();
  }

  @override
  Future<void> removeInspection(String id) async {
    await client
        .from('property_inspections')
        .delete()
        .eq('id', id)
        .eq('user_id', owner)
        .not('deleted_at', 'is', null)
        .select('id')
        .single();
  }

  @override
  Future<PropertyPhoto> reservePhoto(String inspectionId) async {
    final Map<String, dynamic> row = Map<String, dynamic>.from(
      await client.rpc(
        'reserve_property_photo',
        params: <String, Object?>{'p_inspection': inspectionId},
      ) as Map,
    );
    return PropertyPhoto(
      id: row['id'] as String,
      path: row['storage_path'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      uploaded: false,
    );
  }

  @override
  Future<void> uploadPhoto(
    PropertyPhoto photo,
    PropertyPickedPhoto picked,
  ) async {
    await client.storage
        .from('inspection-photos')
        .uploadBinary(
          photo.path,
          picked.bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
  }

  @override
  Future<void> markUploaded(String photoId) async {
    await client.rpc(
      'finish_property_photo',
      params: <String, Object?>{'p_photo': photoId},
    );
  }

  @override
  Future<void> removeFile(String path) async {
    await client.storage.from('inspection-photos').remove(<String>[path]);
  }

  @override
  Future<void> removePhoto(String photoId) async {
    await client
        .from('property_inspection_photos')
        .delete()
        .eq('id', photoId)
        .eq('user_id', owner)
        .select('id')
        .single();
  }

  @override
  Future<void> editPhoto(
    String inspectionId,
    String photoId, {
    String? caption,
    bool cover = false,
  }) async {
    await client.rpc(
      'edit_property_photo',
      params: <String, Object?>{
        'p_inspection': inspectionId,
        'p_photo': photoId,
        'p_caption': caption,
        'p_cover': cover,
      },
    );
  }

  static const List<String> snapshotKeys = <String>[
    'snapshot_availability',
    'snapshot_latitude',
    'snapshot_longitude',
    'reporting_state',
    'safety_index',
    'safety_source_year',
    'safety_source_id',
    'safety_model_boundary_version',
    'safety_completeness',
    'hazard_pending_count',
    'hazard_radius_m',
    'hazard_counted_at',
    'snapshot_captured_at',
  ];
}
