


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import 'location_coordinator_test.dart' show MemoryStorage;

void main() {
  testWidgets('private save dialog disappears with account Navigator', (
    tester,
  ) async {
    final LocationCoordinator map = createLocationCoordinator(
      accountId: 'a',
      validatePoint: (_) async => true,
      storage: MemoryStorage(),
    );
    await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
        displayName: 'Private account A place',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => MapLocationPage(
              locations: map,
              layerHost: locationLayerHost(map),
              workspace: locationWorkspace(map),
              onAnalysis: (ValidLocationReference location) {},
              onComparison: (
                ValidLocationReference a,
                ValidLocationReference b,
              ) {},
              onLayerSelected: (MapLayerIntent intent) {},
              search: createLocationSearch(apiKey: ''),
              showTiles: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save location'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Text('Signed out')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Private account A place'), findsNothing);
  });
  testWidgets(
    'late selected-point rejection cannot overwrite current feedback',
    (tester) async {
      final Completer<bool> pending = Completer<bool>();
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (point) =>
            point.latitude == 3 ? pending.future : Future.value(true),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MapLocationPage(
            locations: map,
            layerHost: locationLayerHost(map),
            workspace: locationWorkspace(map),
            onAnalysis: (ValidLocationReference location) {},
            onComparison: (
              ValidLocationReference a,
              ValidLocationReference b,
            ) {},
            onLayerSelected: (MapLayerIntent intent) {},
            search: createLocationSearch(apiKey: ''),
            showTiles: false,
          ),
        ),
      );
      for (final String lat in ['3', '4']) {
        await tester.tap(find.byTooltip('Enter coordinates'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'Latitude'), lat);
        await tester.enterText(
          find.widgetWithText(TextField, 'Longitude'),
          '101',
        );
        await tester.tap(find.text('Select'));
        await tester.pumpAndSettle();
      }
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Choose a point on Malaysian land.'), findsNothing);
      expect(
        find.text('Account scope unavailable. Sign in again.'),
        findsNothing,
      );
      expect(find.text('View full analysis'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('invalid saved name keeps dialog open and focuses name', (
    tester,
  ) async {
    final LocationCoordinator map = createLocationCoordinator(
      accountId: 'a',
      validatePoint: (_) async => true,
      storage: MemoryStorage(),
    );
    await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MapLocationPage(
          locations: map,
          layerHost: locationLayerHost(map),
          workspace: locationWorkspace(map),
          onAnalysis: (ValidLocationReference location) {},
          onComparison: (ValidLocationReference a, ValidLocationReference b) {},
          onLayerSelected: (MapLayerIntent intent) {},
          search: createLocationSearch(apiKey: ''),
          showTiles: false,
        ),
      ),
    );
    await tester.tap(find.text('Save location'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Name must contain 1–120 characters.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Name'))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'page uses injected layer host and exposes localized map alternative',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final LocationCoordinator service = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (_) async => true,
      );
      final RecordingLayerHost host = RecordingLayerHost();
      await tester.pumpWidget(
        MaterialApp(
          home: MapLocationPage(
            locations: ForwardingLocations(service),
            layerHost: host,
            workspace: locationWorkspace(service),
            onAnalysis: (ValidLocationReference location) {},
            onComparison: (
              ValidLocationReference a,
              ValidLocationReference b,
            ) {},
            onLayerSelected: (MapLayerIntent intent) {},
            search: createLocationSearch(apiKey: ''),
            showTiles: false,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('Map: no location selected')),
        findsOneWidget,
      );
      await tester.longPressAt(const Offset(100, 230));
      await tester.pumpAndSettle();
      expect(host.requested, isNotNull);
      expect(service.read(LocationRole.single), isA<LocationAbsent>());
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
  testWidgets(
    'map has no default analysis and supports accessible coordinate selection',
    (tester) async {
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (_) async => true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MapLocationPage(
            locations: map,
            layerHost: locationLayerHost(map),
            workspace: locationWorkspace(map),
            onAnalysis: (ValidLocationReference location) {},
            onComparison: (
              ValidLocationReference a,
              ValidLocationReference b,
            ) {},
            onLayerSelected: (MapLayerIntent intent) {},
            search: createLocationSearch(apiKey: ''),
            showTiles: false,
          ),
        ),
      );
      expect(find.text('Select a location'), findsOneWidget);
      await tester.tap(find.byTooltip('Enter coordinates'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Latitude'), '3');
      await tester.enterText(
        find.widgetWithText(TextField, 'Longitude'),
        '101',
      );
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      expect(find.text('View full analysis'), findsOneWidget);
    },
  );
  testWidgets('comparison requires explicit A/B and search empty is readable', (
    tester,
  ) async {
    final LocationCoordinator map = createLocationCoordinator(
      accountId: 'a',
      validatePoint: (_) async => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MapLocationPage(
          locations: map,
          layerHost: locationLayerHost(map),
          workspace: locationWorkspace(map),
          onAnalysis: (ValidLocationReference location) {},
          onComparison: (ValidLocationReference a, ValidLocationReference b) {},
          onLayerSelected: (MapLayerIntent intent) {},
          search: createLocationSearch(apiKey: ''),
          showTiles: false,
        ),
      ),
    );
    await tester.tap(find.text('Compare locations'));
    await tester.pump();
    expect(find.text('Location A'), findsOneWidget);
    expect(find.text('Location B'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'View comparison'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField).first, 'Place');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Search unavailable. Try again.'), findsOneWidget);
  });
  for (final Locale locale in [const Locale('en'), const Locale('zh')]) {
    testWidgets(
      'small screen with 200 percent text remains usable in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final LocationCoordinator map = createLocationCoordinator(
          accountId: 'a',
          validatePoint: (_) async => true,
        );
        await map.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('zh')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: MapLocationPage(
              locations: map,
              layerHost: locationLayerHost(map),
              workspace: locationWorkspace(map),
              onAnalysis: (ValidLocationReference location) {},
              onComparison: (
                ValidLocationReference a,
                ValidLocationReference b,
              ) {},
              onLayerSelected: (MapLayerIntent intent) {},
              search: createLocationSearch(apiKey: ''),
              showTiles: false,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final String label = locale.languageCode == 'zh' ? '图层' : 'Layers';
        final Finder layersButton = find.byTooltip(label);
        expect(layersButton, findsOneWidget);
        expect(find.text(label), findsNothing);
        final Rect buttonRect = tester.getRect(layersButton);
        expect(buttonRect.width, greaterThanOrEqualTo(48));
        expect(buttonRect.height, greaterThanOrEqualTo(48));
        await tester.tap(layersButton);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widget<IconButton>(
                find.ancestor(
                  of: layersButton,
                  matching: find.byType(IconButton),
                ),
              )
              .isSelected,
          isFalse,
        );
        final String saveLabel = locale.languageCode == 'zh'
            ? '收藏地点'
            : 'Save location';
        expect(find.text('3.00000, 101.00000'), findsOneWidget);
        await tester.ensureVisible(find.text(saveLabel));
        await tester.tap(find.text(saveLabel));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'invalid coordinate keeps dialog open and focuses the invalid field',
    (tester) async {
      final LocationCoordinator map = createLocationCoordinator(
        accountId: 'a',
        validatePoint: (_) async => true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MapLocationPage(
            locations: map,
            layerHost: locationLayerHost(map),
            workspace: locationWorkspace(map),
            onAnalysis: (ValidLocationReference location) {},
            onComparison: (
              ValidLocationReference a,
              ValidLocationReference b,
            ) {},
            onLayerSelected: (MapLayerIntent intent) {},
            search: createLocationSearch(apiKey: ''),
            showTiles: false,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Enter coordinates'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Latitude'), '91');
      await tester.enterText(
        find.widgetWithText(TextField, 'Longitude'),
        '101',
      );
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Latitude must be between −90 and 90.'), findsOneWidget);
    },
  );
}

class RecordingLayerHost implements MapLayerHost {
  GeographicPoint? requested;
  @override
  Future<MapLayerContributionOutcome> contribute(
    MapLayerContribution contribution,
  ) async {
    return const MapLayerAccepted();
  }

  @override
  Future<MapLayerIntentOutcome> requestLongPress(GeographicPoint point) async {
    requested = point;
    return MapLayerIntentAccepted(
      intent: CreateHazardIntent(
        location: ValidLocationReference(locationId: 'longpress', point: point),
      ),
    );
  }
}

class ForwardingLocations implements LocationCoordinator {
  ForwardingLocations(LocationCoordinator delegate) : delegate = delegate;
  final LocationCoordinator delegate;
  @override
  Future<LocationSelectionOutcome> select(LocationSelectionRequest request) {
    return delegate.select(request);
  }

  @override
  LocationRoleSnapshot read(LocationRole role) {
    return delegate.read(role);
  }

  @override
  Future<LocationSelectionOutcome> swapComparisonLocations() {
    return delegate.swapComparisonLocations();
  }

  @override
  Future<SavedLocationOutcome> save(SaveLocationRequest request) {
    return delegate.save(request);
  }

  @override
  Future<SavedLocationOutcome> deleteSavedLocation(String id) {
    return delegate.deleteSavedLocation(id);
  }

  @override
  Stream<SavedLocationsSnapshot> watchSavedLocations() {
    return delegate.watchSavedLocations();
  }

  @override
  Future<SavedLocationsSnapshot> loadSavedLocations() {
    return delegate.loadSavedLocations();
  }
}
