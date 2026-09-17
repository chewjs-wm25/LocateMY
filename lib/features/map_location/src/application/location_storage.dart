// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import '../domain/location_models.dart';

/// External persistence boundary. Records include tombstones for replay safety.
abstract interface class LocationStorage {
  Future<List<SavedRecord>> readRemote();
  Future<SavedRecord> createRemote(SavedRecord record);
  Future<SavedRecord> deleteRemote(SavedRecord record);
  Future<List<SavedRecord>> readLocal();
  Future<void> writeLocal(List<SavedRecord> records);
  Future<void> clearLocal();
}

final class SavedRecord {
  final SavedLocation saved;
  final bool deleted;
  final int version;
  final String clientKey;
  final int attempts;
  final SavedLocationFailure? lastFailure;
  const SavedRecord({
    required SavedLocation saved,
    required String clientKey,
    bool deleted = false,
    int version = 0,
    int attempts = 0,
    SavedLocationFailure? lastFailure,
  }) : saved = saved,
       clientKey = clientKey,
       deleted = deleted,
       version = version,
       attempts = attempts,
       lastFailure = lastFailure;
}
