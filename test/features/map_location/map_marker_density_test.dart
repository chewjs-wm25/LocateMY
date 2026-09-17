// Explicit constructor types follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:latlong2/latlong.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../../support/fake_application_shell.dart';

void main() {
  testWidgets(
    'late dense facility layer stays readable and retains every point',
    (WidgetTester tester) async {
      final AccountScope scope = AccountScope('marker-density');
      final LocationCoordinator locations = createLocationCoordinator(
        scope: scope,
        readScope: () {
          return AccountScopeOpened(scope);
        },
        validatePoint: (GeographicPoint point) async {
          return true;
        },
      );
      String version = '';
      await tester.pumpWidget(
        MaterialApp(
          home: MapLocationPage(
            locations: locations,
            layerHost: locationLayerHost(locations),
            workspace: locationWorkspace(locations),
            applicationShell: FakeApplicationShell(),
            search: createLocationSearch(apiKey: ''),
            showTiles: false,
            onViewport:
                (String value, GeographicPoint south, GeographicPoint north) {
                  version = value;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The network layer completes after the map has already been displayed.
      await tester.pump(const Duration(seconds: 75));
      final List<MapLayerItem> items = <MapLayerItem>[];
      for (int index = 0; index < 600; index += 1) {
        items.add(
          MapLayerItem(
            stableItemId: 'node_$index',
            point: GeographicPoint(
              latitude: 4.2 + (index % 20) * 0.0001,
              longitude: 109.5 + (index ~/ 20) * 0.0001,
            ),
            intent: ProviderDefinedIntent(
              providerId: 'nearby-facilities',
              action: 'facilitySelected',
              stableItemId: 'node_$index',
            ),
          ),
        );
      }
      final MapLayerContribution contribution = MapLayerContribution(
        providerId: 'nearby-facilities',
        layerId: 'facilities',
        viewportVersion: version,
        visibility: MapLayerVisibility.visible,
        items: items,
      );
      expect(
        await locationLayerHost(locations).contribute(contribution),
        isA<MapLayerAccepted>(),
      );
      await tester.pumpAndSettle();
      final Iterable<Marker> markers = tester
          .widgetList<MarkerLayer>(find.byType(MarkerLayer))
          .expand((MarkerLayer layer) {
            return layer.markers;
          });
      expect(markers.length, lessThan(100));
      expect(locationWorkspace(locations).visibleLayerItems.length, 600);
      expect(find.text('600'), findsOneWidget);
      // Republishing the same layer replaces its contents rather than accumulating.
      expect(
        await locationLayerHost(locations).contribute(contribution),
        isA<MapLayerAccepted>(),
      );
      await tester.pumpAndSettle();
      expect(find.text('600'), findsOneWidget);
      final BuildContext mapContext = tester.element(
        find.byType(MarkerLayer).last,
      );
      final double zoom = MapCamera.of(mapContext).zoom;
      await tester.tap(find.text('600'));
      await tester.pumpAndSettle();
      expect(
        MapCamera.of(tester.element(find.byType(MarkerLayer).last)).zoom,
        greaterThan(zoom),
      );
      expect(locations.read(LocationRole.single), isA<LocationAbsent>());
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'providers remain distinct, offscreen points are culled and original intents are routed',
    (WidgetTester tester) async {
      final AccountScope scope = AccountScope('marker-types');
      final LocationCoordinator locations = createLocationCoordinator(
        scope: scope,
        readScope: () {
          return AccountScopeOpened(scope);
        },
        validatePoint: (GeographicPoint point) async {
          return true;
        },
      );
      final FakeApplicationShell shell = FakeApplicationShell(
        intents: <ShellIntentOutcome>[ShellIntentAccepted()],
      );
      String version = '';
      await tester.pumpWidget(
        MaterialApp(
          home: MapLocationPage(
            locations: locations,
            layerHost: locationLayerHost(locations),
            workspace: locationWorkspace(locations),
            applicationShell: shell,
            search: createLocationSearch(apiKey: ''),
            showTiles: false,
            onViewport:
                (String value, GeographicPoint south, GeographicPoint north) {
                  version = value;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final MapController controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      controller.move(const LatLng(4.2, 109.5), 18);
      await tester.pumpAndSettle();
      for (final String provider in <String>[
        'nearby-facilities',
        'hazard-reporting',
      ]) {
        final List<MapLayerItem> items = <MapLayerItem>[];
        final int count = provider == 'nearby-facilities' ? 2 : 1;
        for (int index = 0; index < count; index += 1) {
          items.add(
            MapLayerItem(
              stableItemId: '$provider-$index',
              point: GeographicPoint(
                latitude: provider == 'nearby-facilities' ? 4.2 : 4.2003,
                longitude: 109.5,
              ),
              intent: ProviderDefinedIntent(
                providerId: provider,
                action: 'detail',
                stableItemId: '$provider-$index',
              ),
            ),
          );
        }
        items.add(
          MapLayerItem(
            stableItemId: '$provider-offscreen',
            point: const GeographicPoint(latitude: 3, longitude: 101),
            intent: ProviderDefinedIntent(
              providerId: provider,
              action: 'detail',
              stableItemId: '$provider-offscreen',
            ),
          ),
        );
        expect(
          await locationLayerHost(locations).contribute(
            MapLayerContribution(
              providerId: provider,
              layerId: 'points',
              viewportVersion: version,
              visibility: MapLayerVisibility.visible,
              items: items,
            ),
          ),
          isA<MapLayerAccepted>(),
        );
      }
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
      expect(
        find.byTooltip('Nearby facilities: 2 points. Tap to explore.'),
        findsOneWidget,
      );
      expect(locationWorkspace(locations).visibleLayerItems.length, 5);
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(shell.intents, isEmpty);
      expect(locations.read(LocationRole.single), isA<LocationAbsent>());
      expect(find.byType(ListTile), findsNothing);
      await tester.tap(find.text('Layers'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.text('2'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
