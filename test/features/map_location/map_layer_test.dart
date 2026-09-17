import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';

void main() {
  test('late contribution during closing returns scope unavailable', () async {
    for (final bool valid in [true, false]) {
      final AccountScope scope = AccountScope('a');
      AccountScopeSnapshot snapshot = AccountScopeOpened(scope);
      final Completer<bool> pending = Completer<bool>();
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => snapshot,
        validatePoint: (_) => pending.future,
      );
      final Future<MapLayerContributionOutcome> contribution =
          locationLayerHost(map).contribute(
            const MapLayerContribution(
              providerId: 'hazard',
              layerId: 'reports',
              viewportVersion: 'initial',
              visibility: MapLayerVisibility.visible,
              items: [
                MapLayerItem(
                  stableItemId: 'report',
                  point: GeographicPoint(latitude: 3, longitude: 101),
                  intent: ProviderDefinedIntent(
                    providerId: 'hazard',
                    action: 'open',
                    stableItemId: 'report',
                  ),
                ),
              ],
            ),
          );
      final Future<MapLayerIntentOutcome> longPress = locationLayerHost(map)
          .requestLongPress(const GeographicPoint(latitude: 3, longitude: 101));
      snapshot = AccountScopeClosing(scope);
      await locationPrivacyParticipant(map).clearPrivateState(scope);
      pending.complete(valid);
      expect(
        (await contribution as MapLayerRejected).failure,
        MapLayerFailure.scopeUnavailable,
      );
      expect(
        (await longPress as MapLayerIntentRejected).failure,
        MapLayerFailure.scopeUnavailable,
      );
    }
  });
  test('closing rejects long press as scope unavailable', () async {
    final AccountScope scope = AccountScope('a');
    final LocationCoordinator map = createLocationCoordinator(
      scope: scope,
      readScope: () => AccountScopeClosing(scope),
      validatePoint: (_) async => true,
    );
    final MapLayerIntentOutcome result = await locationLayerHost(map)
        .requestLongPress(const GeographicPoint(latitude: 3, longitude: 101));
    expect(
      (result as MapLayerIntentRejected).failure,
      MapLayerFailure.scopeUnavailable,
    );
  });
  test(
    'boundary outage returns typed failures without mutating roles',
    () async {
      final AccountScope scope = AccountScope('a');
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
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
      final AccountScope scope = AccountScope('a');
      final LocationCoordinator map = createLocationCoordinator(
        scope: scope,
        readScope: () => AccountScopeOpened(scope),
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
