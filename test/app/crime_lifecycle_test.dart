import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/crime_security/crime_security.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../features/crime_security/crime_security_test.dart'
    show GeoFixture, ReaderFixture, PendingInputs;
import '../support/fake_authentication_session.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'account change and logout close crime pages and ignore late analysis responses',
    (WidgetTester tester) async {
      final Database db = await databaseFactoryFfiNoIsolate.openDatabase(
        inMemoryDatabasePath,
      );
      final PendingInputs reader = PendingInputs();
      final CrimeSecurity crime = createCrimeSecurity(
        geographicContext: GeoFixture(),
        reader: reader,
        database: db,
      );
      final FakeAuthenticationSession auth = FakeAuthenticationSession();
      auth.restored = const AuthenticatedSession(accountA);
      final AuthenticationViewModel vm = createAuthenticationViewModel(auth);
      await tester.pumpWidget(
        LocateMyApp(
          authenticationViewModel: vm,
          signedInBuilder:
              (BuildContext context, AuthenticatedAccount account) {
                return CrimeSecurityPage(
                  crime: crime,
                  location: ValidLocationReference(
                    locationId: account.accountId,
                    point: const GeographicPoint(
                      latitude: 3.0738,
                      longitude: 101.6077,
                    ),
                    displayName: 'Owner ${account.accountId}',
                  ),
                );
              },
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(reader.pending.length, 1);
      auth.changes.add(const AuthenticatedSession(accountB));
      await tester.pump();
      await tester.pump();
      expect(reader.pending.length, 2);
      reader.pending[1].complete(ReaderFixture().payload);
      await tester.pumpAndSettle();
      reader.pending[0].complete(ReaderFixture().payload);
      await tester.pumpAndSettle();
      expect(find.text('Owner a'), findsNothing);
      expect(find.text('Owner b'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('重试 / 刷新'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('重试 / 刷新'));
      await tester.pump();
      expect(reader.pending.length, 3);
      await vm.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(AuthenticationPage), findsOneWidget);
      reader.pending[2].complete(ReaderFixture().payload);
      await tester.pumpAndSettle();
      expect(find.byType(CrimeSecurityPage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      await auth.changes.close();
      await db.close();
    },
  );
}
