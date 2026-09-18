


import '../domain/location_models.dart';


abstract interface class LocationStorage {
  Future<List<SavedRecord>> readRemote();
  Future<SavedRecord> createRemote(SavedRecord record);
  Future<SavedRecord> deleteRemote(SavedRecord record);
}

final class SavedRecord {
  final SavedLocation saved;
  final bool deleted;
  final int version;
  final String clientKey;
  const SavedRecord({
    required SavedLocation saved,
    required String clientKey,
    bool deleted = false,
    int version = 0,
  }) : saved = saved,
       clientKey = clientKey,
       deleted = deleted,
       version = version;
}
