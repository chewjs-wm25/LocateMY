import 'dart:async';

import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/socio_economic/socio_economic.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:locatemy/l10n/language_controller.dart';
import 'package:provider/provider.dart';

import 'socio_economic_test.dart' show GeoFixture, ReaderFixture, location;

final class ControlledSocio implements SocioEconomic {
  final List<Completer<SocioAnalysis>> requests = <Completer<SocioAnalysis>>[];
  final StreamController<void> events = StreamController<void>.broadcast();
  @override
  Stream<void> get changes {
    return events.stream;
  }

  @override
  Future<SocioAnalysis> analyse(
    ValidLocationReference location, {
    bool refresh = false,
  }) {
    final Completer<SocioAnalysis> request = Completer<SocioAnalysis>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<SocioComparison> compare(
    ValidLocationReference a,
    ValidLocationReference b, {
    bool refresh = false,
  }) async {
    return SocioComparison(await analyse(a), await analyse(b));
  }
}

Widget app(
  SocioEconomic service, {
  Locale locale = const Locale('en'),
  double scale = 1,
  double width = 390,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 844),
        textScaler: TextScaler.linear(scale),
      ),
      child: SocioEconomicPage(socio: service, location: location),
    ),
  );
}

void main() {
  testWidgets('A unavailable and B usable retains B without crashing', (
    WidgetTester tester,
  ) async {
    final ControlledSocio service = ControlledSocio();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SocioEconomicPage(
          socio: service,
          location: location,
          locationB: location,
        ),
      ),
    );
    service.requests[0].complete(
      const SocioAnalysis(
        location: location,
        failure: SocioFailure.sourceUnavailable,
      ),
    );
    await tester.pump();
    service.requests[1].complete(
      const SocioAnalysis(
        location: location,
        income: SocioReading(9000, 2024, 'Selangor', 'Petaling'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('RM 9,000'), 300);
    expect(find.text('RM 9,000'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('About estimates'), 300);
    expect(find.text('About estimates'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await service.events.close();
  });
  testWidgets(
    'language switches on the Socio route without reloading analysis',
    (WidgetTester tester) async {
      final ControlledSocio service = ControlledSocio();
      final LanguageController language = LanguageController();
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageController>.value(
          value: language,
          child: Consumer<LanguageController>(
            builder:
                (
                  BuildContext context,
                  LanguageController controller,
                  Widget? child,
                ) {
                  return app(service, locale: controller.locale);
                },
          ),
        ),
      );
      service.requests[0].complete(
        const SocioAnalysis(
          location: location,
          income: SocioReading(8210, 2024, 'Selangor', 'Petaling'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('社会与经济'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('language-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Socio-economic'), findsOneWidget);
      expect(find.text('RM 8,210'), findsOneWidget);
      expect(service.requests, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      await service.events.close();
      language.dispose();
    },
  );
  testWidgets(
    'page displays real district readings and missing income position without a synthetic slider',
    (WidgetTester tester) async {
      final SocioEconomic service = createSocioEconomic(
        geographicContext: GeoFixture(),
        reader: ReaderFixture(),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SocioEconomicPage(socio: service, location: location),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('RM 8,210'), findsOneWidget);
      expect(find.textContaining('Petaling'), findsWidgets);
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Official district statistics'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Your income position'), 300);
      expect(find.text('Your income position'), findsOneWidget);
      expect(find.text('Temporarily unavailable'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'newer response wins old responses and dispose ignores late completion',
    (WidgetTester tester) async {
      final ControlledSocio service = ControlledSocio();
      await tester.pumpWidget(app(service));
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      service.requests[1].complete(
        const SocioAnalysis(
          location: location,
          income: SocioReading(9000, 2024, 'Selangor', 'Petaling'),
        ),
      );
      await tester.pump();
      service.requests[0].complete(
        const SocioAnalysis(
          location: location,
          income: SocioReading(1000, 2024, 'Selangor', 'Petaling'),
        ),
      );
      await tester.pump();
      expect(find.text('RM 9,000'), findsOneWidget);
      expect(find.text('RM 1,000'), findsNothing);
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      service.requests[2].complete(const SocioAnalysis(location: location));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(service.events.hasListener, false);
      await service.events.close();
    },
  );
  testWidgets(
    'current budget change updates income position and failed refresh preserves official readings',
    (WidgetTester tester) async {
      final ControlledSocio service = ControlledSocio();
      await tester.pumpWidget(app(service));
      service.requests[0].complete(
        const SocioAnalysis(
          location: location,
          income: SocioReading(8210, 2024, 'Selangor', 'Petaling'),
          position: IncomePosition(
            6300,
            63,
            IncomePositionBoundary.withinDistribution,
            2024,
          ),
        ),
      );
      await tester.pump();
      service.events.add(null);
      await tester.pump();
      service.requests[1].complete(
        const SocioAnalysis(
          location: location,
          income: SocioReading(8210, 2024, 'Selangor', 'Petaling'),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Your income position'), 300);
      expect(find.text('P63'), findsNothing);
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      service.requests[2].completeError(Exception('Private failure detail'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Temporarily unavailable. Please retry.'),
        -300,
      );
      expect(
        find.text('Temporarily unavailable. Please retry.'),
        findsOneWidget,
      );
      expect(find.textContaining('Private failure detail'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await service.events.close();
    },
  );
  for (final Locale locale in <Locale>[
    const Locale('en'),
    const Locale('zh'),
  ]) {
    testWidgets(
      'small screen and 200 percent text remain scrollable in $locale',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final SemanticsHandle semantics = tester.ensureSemantics();
        final SocioEconomic service = createSocioEconomic(
          geographicContext: GeoFixture(),
          reader: ReaderFixture(),
        );
        await tester.pumpWidget(
          app(service, locale: locale, scale: 2, width: 320),
        );
        await tester.pumpAndSettle();
        final String label = locale.languageCode == 'zh'
            ? '关于估算'
            : 'About estimates';
        await tester.scrollUntilVisible(find.text(label), 400);
        expect(find.text(label), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
  testWidgets(
    'failed refresh keeps official readings but withdraws an unverified previous income position',
    (WidgetTester tester) async {
      final ControlledSocio service = ControlledSocio();
      await tester.pumpWidget(app(service));
      service.requests[0].complete(
        const SocioAnalysis(
          location: location,
          income: SocioReading(8210, 2024, 'Selangor', 'Petaling'),
          position: IncomePosition(
            6300,
            63,
            IncomePositionBoundary.withinDistribution,
            2024,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      service.requests[1].completeError(Exception('unavailable'));
      await tester.pump();
      expect(find.text('RM 8,210'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Your income position'), 300);
      expect(find.text('P63'), findsNothing);
      expect(find.text('Temporarily unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await service.events.close();
    },
  );
}
