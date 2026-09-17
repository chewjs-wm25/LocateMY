import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/nearby_facilities/nearby_facilities.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';
import 'package:locatemy/l10n/app_localizations.dart';

void main() {
  const ValidLocationReference a = ValidLocationReference(
    locationId: 'a',
    point: GeographicPoint(latitude: 3.1, longitude: 101.6),
    displayName: 'Place A',
  );
  const ValidLocationReference b = ValidLocationReference(
    locationId: 'b',
    point: GeographicPoint(latitude: 3.2, longitude: 101.7),
    displayName: 'Place B',
  );
  for (final bool comparison in <bool>[false, true]) {
    testWidgets(
      'ordinary ${comparison ? 'A/B' : 'single'} analysis routes preserve validated inputs and return',
      (WidgetTester tester) async {
        final RecordingFacilities facilities = RecordingFacilities();
        final RecordingTransportation transit = RecordingTransportation();
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LocationAnalysisMenu(
              location: a,
              locationB: comparison ? b : null,
              facilities: facilities,
              transportation: transit,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Not implemented yet'), findsNWidgets(4));
        await tester.ensureVisible(find.text('Nearby facilities'));
        await tester.tap(find.text('Nearby facilities'));
        await tester.pumpAndSettle();
        expect(find.byType(NearbyFacilitiesPage), findsOneWidget);
        if (comparison) {
          expect(facilities.comparisons.single.locationA, a);
          expect(facilities.comparisons.single.locationB, b);
        } else {
          expect(facilities.analyses.single.location, a);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(LocationAnalysisMenu), findsOneWidget);
        await tester.ensureVisible(find.text('Public transportation'));
        await tester.tap(find.text('Public transportation'));
        await tester.pumpAndSettle();
        if (comparison) {
          expect(
            find.byType(PublicTransportationComparisonPage),
            findsOneWidget,
          );
          expect(transit.comparisons.single.a.location, a);
          expect(transit.comparisons.single.b.location, b);
          expect(
            transit.comparisons.single.a.analysisDate,
            transit.comparisons.single.b.analysisDate,
          );
        } else {
          expect(find.byType(PublicTransportationPage), findsOneWidget);
          expect(transit.loads.single.location, a);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Place A'), findsOneWidget);
        expect(
          find.text('Place B'),
          comparison ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final String language in <String>['en', 'zh']) {
    testWidgets('analysis remains usable at 320px and 200% text in $language', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            );
          },
          home: LocationAnalysisMenu(
            location: a,
            locationB: b,
            facilities: RecordingFacilities(),
            transportation: RecordingTransportation(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Finder transit = find.text(
        language == 'zh' ? '公共交通' : 'Public transportation',
      );
      await tester.ensureVisible(transit);
      await tester.tap(transit);
      await tester.pumpAndSettle();
      expect(find.byType(PublicTransportationComparisonPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

final class RecordingFacilities implements NearbyFacilities {
  final List<FacilityAnalysisRequest> analyses = <FacilityAnalysisRequest>[];
  final List<FacilityComparisonRequest> comparisons =
      <FacilityComparisonRequest>[];
  @override
  Future<FacilityAnalysisOutcome> analyse(
    FacilityAnalysisRequest request,
  ) async {
    analyses.add(request);
    return const FacilityAnalysisUnavailable(
      failure: FacilityFailure.sourceUnavailable,
    );
  }

  @override
  Future<FacilityComparisonOutcome> compare(
    FacilityComparisonRequest request,
  ) async {
    comparisons.add(request);
    return const FacilityComparisonUnavailable(
      failure: FacilityFailure.sourceUnavailable,
    );
  }

  @override
  Future<FacilityLayerOutcome> contributeLayer(
    FacilityLayerRequest request,
  ) async {
    return const FacilityLayerNotPublished(
      failure: FacilityLayerFailure.analysisUnavailable,
    );
  }
}

final class RecordingTransportation implements PublicTransportation {
  final List<TransitRequest> loads = <TransitRequest>[];
  final List<TransitComparisonRequest> comparisons =
      <TransitComparisonRequest>[];
  @override
  Future<TransitLoadOutcome> load(TransitRequest request) async {
    loads.add(request);
    return const TransitUnavailable(
      TransitUnavailableReason.retryableUnavailable,
      <FeedStatus>[],
    );
  }

  @override
  Future<TransitComparisonOutcome> compare(
    TransitComparisonRequest request,
  ) async {
    comparisons.add(request);
    return const TransitIncomparable(
      TransitUnavailable(
        TransitUnavailableReason.retryableUnavailable,
        <FeedStatus>[],
      ),
      TransitUnavailable(
        TransitUnavailableReason.retryableUnavailable,
        <FeedStatus>[],
      ),
      TransitComparisonReason.sideUnavailable,
    );
  }
}
