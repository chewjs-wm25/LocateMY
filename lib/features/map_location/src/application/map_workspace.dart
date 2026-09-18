import '../domain/location_models.dart';


abstract interface class MapWorkspace {
  bool get opened;
  List<MapLayerItem> get visibleLayerItems;
  Stream<void> get changes;
  void clear();
  void setViewport(String version);
}
