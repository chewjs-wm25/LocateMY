import '../domain/location_models.dart';

/// Presentation controls owned by Map, separate from frozen owner interfaces.
abstract interface class MapWorkspace {
  bool get opened;
  List<MapLayerItem> get visibleLayerItems;
  Stream<void> get changes;
  void clear();
  void setViewport(String version);
}
