import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'crime_security_test.dart'
    show GeoFixture, ReaderFixture, sunway, PendingInputs;

void main() {
  sqfliteFfiInit();
  testWidgets(
    'single point shows actual state safety and category filtering keeps score',
    (WidgetTester tester) async {
      final Database db = (await tester.runAsync(() async {
        return await databaseFactoryFfiNoIsolate.openDatabase(
          inMemoryDatabasePath,
        );
      }))!;
      final CrimeSecurity crime = createCrimeSecurity(
        geographicContext: GeoFixture(),
        reader: ReaderFixture(),
        database: db,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CrimeSecurityPage(crime: crime, location: sunway),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('40'), findsOneWidget);
      expect(find.text('Selangor · 统计州口径'), findsOneWidget);
      await tester.tap(find.text('暴力犯罪 (10)'));
      await tester.pumpAndSettle();
      expect(find.text('40'), findsOneWidget);
      expect(find.text('筛选仅影响趋势图，不改变安全指数'), findsOneWidget);
      expect(find.textContaining('crime_district'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await db.close();
      });
    },
  );
  testWidgets('A/B shows both state results and swaps presentation order', (
    WidgetTester tester,
  ) async {
    final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
    );
    final CrimeSecurity crime = createCrimeSecurity(
      geographicContext: GeoFixture(),
      reader: ReaderFixture(),
      database: db,
    );
    const ValidLocationReference b = ValidLocationReference(
      locationId: 'b',
      point: GeographicPoint(latitude: 1.5, longitude: 103.7),
      displayName: 'Johor Bahru',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CrimeSecurityPage(crime: crime, location: sunway, locationB: b),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A · Sunway Mentari'), findsOneWidget);
    expect(find.text('B · Johor Bahru', skipOffstage: false), findsOneWidget);
    expect(find.text('B − A: 0'), findsOneWidget);
    await tester.tap(find.byTooltip('Swap A/B'));
    await tester.pumpAndSettle();
    expect(find.text('A · Johor Bahru'), findsOneWidget);
    expect(
      find.text('B · Sunway Mentari', skipOffstage: false),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets(
    'main map action carries the current analysis location and property entries are honest Wave 6 routes',
    (WidgetTester tester) async {
      final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
        inMemoryDatabasePath,
      );
      final CrimeSecurity crime = createCrimeSecurity(
        geographicContext: GeoFixture(),
        reader: ReaderFixture(),
        database: db,
      );
      ValidLocationReference? returned;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CrimeSecurityPage(
            crime: crime,
            location: sunway,
            onShowMap: (ValidLocationReference location) {
              returned = location;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Main map'));
      expect(returned, sunway);
      await tester.scrollUntilVisible(
        find.text('Add property inspection'),
        200,
      );
      await tester.tap(find.text('Add property inspection'));
      await tester.pumpAndSettle();
      expect(find.text('Not implemented yet · Wave 6'), findsOneWidget);
      expect(find.text('Sunway Mentari'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CrimeSecurityPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );

  for (final String language in <String>['zh', 'en']) {
    testWidgets(
      '$language at 320dp and 200 percent supports loading, failure, retry and translated statistics',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() {
          return tester.binding.setSurfaceSize(null);
        });
        final SemanticsHandle handle = tester.ensureSemantics();
        final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
          inMemoryDatabasePath,
        );
        final ReaderFixture reader = ReaderFixture();
        reader.offline = true;
        final CrimeSecurity crime = createCrimeSecurity(
          geographicContext: GeoFixture(),
          reader: reader,
          database: db,
        );
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
            home: CrimeSecurityPage(
              crime: crime,
              location: sunway,
              onShowMap: (ValidLocationReference location) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final String title = language == 'zh' ? '治安与犯罪' : 'Crime and security';
        final RenderParagraph titleParagraph = tester
            .renderObject<RenderParagraph>(find.text(title));
        expect(
          titleParagraph.didExceedMaxLines,
          false,
          reason: 'Page title remains readable at 200 percent',
        );
        final String retry = language == 'zh' ? '重试 / 刷新' : 'Retry / refresh';
        await tester.scrollUntilVisible(find.text(retry), 200);
        await tester.pumpAndSettle();
        reader.offline = false;
        await tester.tap(find.text(retry));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('40'), -200);
        expect(find.text('40'), findsOneWidget);
        final String chart = language == 'zh'
            ? '案件数，不代表实际犯罪率'
            : 'Convicted cases, not the actual crime rate';
        await tester.scrollUntilVisible(find.text(chart), 250);
        expect(find.text(chart), findsOneWidget);
        expect(tester.getSemantics(find.text(chart)).label, contains(chart));
        expect(tester.takeException(), isNull);
        handle.dispose();
        await tester.pumpWidget(const SizedBox());
        await db.close();
      },
    );
  }

  for (final String language in <String>['zh', 'en']) {
    testWidgets('$language A/B remains readable at 320dp and 200 percent', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() {
        return tester.binding.setSurfaceSize(null);
      });
      final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
        inMemoryDatabasePath,
      );
      final GeoFixture geo = GeoFixture();
      geo.locationStates['b'] = 'Johor';
      final CrimeSecurity crime = createCrimeSecurity(
        geographicContext: geo,
        reader: ReaderFixture(),
        database: db,
      );
      const ValidLocationReference b = ValidLocationReference(
        locationId: 'b',
        point: GeographicPoint(latitude: 1.5, longitude: 103.7),
        displayName: 'Johor Bahru',
      );
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
          home: CrimeSecurityPage(crime: crime, location: sunway, locationB: b),
        ),
      );
      await tester.pumpAndSettle();
      final String title = language == 'zh' ? '治安与犯罪' : 'Crime and security';
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(title))
            .didExceedMaxLines,
        false,
      );
      expect(find.text('A · Sunway Mentari'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('B · Johor Bahru'), 250);
      await tester.pumpAndSettle();
      expect(find.text('B · Johor Bahru'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
  }

  testWidgets(
    'changed location ignores the late old result and dispose ignores unfinished analysis',
    (WidgetTester tester) async {
      final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
        inMemoryDatabasePath,
      );
      final PendingInputs source = PendingInputs();
      final CrimeSecurity crime = createCrimeSecurity(
        geographicContext: GeoFixture(),
        reader: source,
        database: db,
      );
      const ValidLocationReference b = ValidLocationReference(
        locationId: 'new',
        point: GeographicPoint(latitude: 3.2, longitude: 101.8),
        displayName: 'New location',
      );
      Widget page(ValidLocationReference location) {
        return MaterialApp(
          home: CrimeSecurityPage(crime: crime, location: location),
        );
      }

      await tester.pumpWidget(page(sunway));
      await tester.pump();
      await tester.pumpWidget(page(b));
      await tester.pump();
      source.pending[1].complete(ReaderFixture().payload);
      await tester.pumpAndSettle();
      expect(find.text('New location'), findsOneWidget);
      source.pending[0].complete(ReaderFixture().payload);
      await tester.pumpAndSettle();
      expect(find.text('Sunway Mentari'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await db.close();
      expect(tester.takeException(), isNull);
    },
  );
}
