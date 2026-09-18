import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  test(
    'boundary outage returns typed failures without mutating roles',
    () async {
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (_) async => throw StateError('boundary unavailable'),
      );
      final GeographicPoint point = GeographicPoint(
        latitude: 3,
        longitude: 101,
      );
      expect(
        await map.select(
          LocationSelectionRequest(role: LocationRole.single, point: point),
        ),
        isA<LocationSelectionRejected>(),
      );
      expect(
        await locationLayerHost(map).requestLongPress(point),
        isA<MapLayerIntentRejected>(),
      );
      expect(
        await locationLayerHost(map).contribute(
          MapLayerContribution(
            providerId: 'hazard',
            layerId: 'reports',
            viewportVersion: 'initial',
            visibility: MapLayerVisibility.visible,
            items: [
              MapLayerItem(
                stableItemId: 'report',
                point: point,
                intent: ProviderDefinedIntent(
                  providerId: 'hazard',
                  action: 'open',
                  stableItemId: 'report',
                ),
              ),
            ],
          ),
        ),
        isA<MapLayerRejected>(),
      );
      expect(map.read(LocationRole.single), isA<LocationAbsent>());
    },
  );
  test(
    'visible/hidden contributions and long press preserve selection roles',
    () async {
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (p) async => p.latitude == 3,
      );
      final MapLayerHost host = locationLayerHost(map);
      setLocationViewport(map, 'v1');
      expect(
        await host.contribute(
          const MapLayerContribution(
            providerId: 'hazard',
            layerId: 'reports',
            viewportVersion: 'v1',
            visibility: MapLayerVisibility.visible,
            items: [],
          ),
        ),
        isA<MapLayerAccepted>(),
      );
      expect(
        await host.contribute(
          const MapLayerContribution(
            providerId: 'hazard',
            layerId: 'reports',
            viewportVersion: 'old',
            visibility: MapLayerVisibility.visible,
            items: [],
          ),
        ),
        isA<MapLayerRejected>(),
      );
      expect(
        await host.requestLongPress(
          const GeographicPoint(latitude: 3, longitude: 101),
        ),
        isA<MapLayerIntentAccepted>(),
      );
      expect(map.read(LocationRole.single), isA<LocationAbsent>());
      expect(
        (await host.requestLongPress(
          const GeographicPoint(latitude: 0, longitude: 101),
        ) as MapLayerIntentRejected).failure,
        MapLayerFailure.outsideMalaysia,
      );
    },
  );
}
