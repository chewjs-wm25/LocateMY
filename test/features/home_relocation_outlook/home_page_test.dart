import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/home_relocation_outlook/home_relocation_outlook.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import '../../support/fake_home_relocation_outlook.dart';

Widget host(HomeRelocationOutlook home, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: HomeOutlookPage(home: home, onExploreMap: () {}),
  ),
);
void main() {
  testWidgets('home displays five cards with units and national context', (
    tester,
  ) async {
    final home = FakeHomeRelocationOutlook(
      (_) async => HomeLoaded(snapshot: homeFixture()),
    );
    await tester.pumpWidget(host(home));
    await tester.pumpAndSettle();
    expect(find.text('Relocation timing'), findsOneWidget);
    expect(find.text('70 / 100'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Household median income'), 300);
    expect(find.textContaining('7,017'), findsOneWidget);
    expect(find.textContaining('2024'), findsWidgets);
    expect(
      find.text('At current-year prices, not adjusted for inflation'),
      findsOneWidget,
    );
  });
  testWidgets('Penpot home presents exploration before the macro indicators', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final home = FakeHomeRelocationOutlook(
      (_) async => HomeLoaded(snapshot: homeFixture()),
    );
    await tester.pumpWidget(host(home));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('home-explore'))).dy,
      lessThan(tester.getTopLeft(find.text('Cost pressure')).dy),
    );
    expect(
      tester.getBottomLeft(find.byKey(const ValueKey('home-explore'))).dy,
      lessThan(844),
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('compact Chinese trend cards fit a 384dp phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final HomeRelocationOutlook home = FakeHomeRelocationOutlook(
      (_) async => HomeLoaded(snapshot: homeFixture()),
    );

    await tester.pumpWidget(host(home, locale: 'zh'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'button and pull refresh share cooldown feedback and prevent repeated reads',
    (tester) async {
      var refreshes = 0;
      final home = FakeHomeRelocationOutlook((request) async {
        if (request == HomeLoadRequest.refresh) {
          refreshes++;
          return HomeRefreshCoolingDown(
            snapshot: homeFixture(),
            remainingSeconds: 42,
          );
        }
        return HomeLoaded(snapshot: homeFixture());
      });
      await tester.pumpWidget(host(home));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-refresh')));
      await tester.pump();
      expect(find.text('Refresh available in 42 seconds'), findsOneWidget);
      final pull = tester.widget<RefreshIndicator>(
        find.byKey(const ValueKey('home-pull-refresh')),
      );
      await pull.onRefresh();
      expect(refreshes, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('a downward page gesture requests refresh through HOME-001', (
    tester,
  ) async {
    final requests = <HomeLoadRequest>[];
    final home = FakeHomeRelocationOutlook((request) async {
      requests.add(request);
      return HomeLoaded(
        snapshot: homeFixture(freshness: HomeDataFreshness.cached),
      );
    });
    await tester.pumpWidget(host(home));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('home-pull-refresh')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(requests, [HomeLoadRequest.cacheAllowed, HomeLoadRequest.refresh]);
    await tester.pumpWidget(const SizedBox());
  });
  for (final locale in ['en', 'zh']) {
    testWidgets(
      '$locale partial outlook remains readable at 360dp and 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final home = FakeHomeRelocationOutlook(
          (_) async => HomeLoaded(
            snapshot: homeFixture(
              freshness: HomeDataFreshness.stale,
              partial: true,
            ),
          ),
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: HomeOutlookPage(home: home, onExploreMap: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Expired cached'), findsNothing);
        expect(find.textContaining('已过期缓存'), findsNothing);
        expect(
          find.textContaining(
            locale == 'en' ? 'Insufficient valid historical' : '有效历史样本不足',
          ),
          findsWidgets,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('home-explore')),
          500,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('home-explore')), findsOneWidget);
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
