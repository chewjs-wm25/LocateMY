import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/features/account_privacy/account_privacy.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../support/fake_authentication_session.dart';
import '../features/map_location/location_coordinator_test.dart'
    show MemoryStorage;

void main() {
  test(
    'real Privacy/Shell block failed Map cleanup and A cannot leak into B',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'map-privacy-',
      );
      final FakeAuthenticationSession auth = FakeAuthenticationSession()
        ..restored = const AuthenticatedSession(accountA);
      late AccountPrivacy privacy;
      late ShellRuntime shell;
      final Map<String, ClearFailureStorage> stores = {
        'a': ClearFailureStorage()..offline = true,
        'b': ClearFailureStorage(),
      };
      final Completer<bool> slow = Completer<bool>();
      final MapLocationRuntime map = MapLocationRuntime(
        readScope: () => privacy.readScope(),
        validatePoint: (p) =>
            p.latitude == 4 ? slow.future : Future.value(true),
        storageForAccount: (id) => stores[id]!,
      );
      shell = ShellRuntime.compose(
        authentication: auth,
        privacy: () => privacy,
        intents: mapShellBindings(() => shell),
      );
      privacy = createAccountPrivacy(
        authenticationSession: auth,
        participants: [
          createAuthenticationPrivacyParticipant(auth),
          shell,
          map,
        ],
        requiredParticipants: const {
          AccountPrivacyParticipantId.authenticationSession,
          AccountPrivacyParticipantId.applicationShell,
          AccountPrivacyParticipantId.mapLocation,
        },
        stateDirectory: directory,
      );
      try {
        await shell.initialize();
        final LocationCoordinator old = map.locations;
        final LocationSelected selected = await old.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 3, longitude: 101),
          ),
        ) as LocationSelected;
        expect(
          await old.save(
            SaveLocationRequest(location: selected.location, name: 'A private'),
          ),
          isA<SavedLocationQueued>(),
        );
        final Future<LocationSelectionOutcome> late = old.select(
          const LocationSelectionRequest(
            role: LocationRole.single,
            point: GeographicPoint(latitude: 4, longitude: 101),
          ),
        );
        stores['a']!.failClear = true;
        await shell.signOut();
        expect(shell.state.gate, ShellGate.recovery);
        expect(old.read(LocationRole.single), isA<LocationAbsent>());
        expect(
          await old.synchronizeSavedLocations(),
          isA<SavedLocationsUnavailable>(),
        );
        slow.complete(true);
        expect(await late, isA<LocationSelectionRejected>());
        stores['a']!.failClear = false;
        await shell.retry();
        expect(shell.state.gate, ShellGate.authentication);
        auth.restored = const AuthenticatedSession(
          AuthenticatedAccount(
            accountId: 'b',
            email: 'b@example.test',
            confirmation: EmailConfirmation.confirmed,
          ),
        );
        final Future<ShellState> opened = shell.changes.firstWhere(
          (s) => s.gate == ShellGate.opened,
        );
        auth.changes.add(auth.restored);
        await opened;
        final LocationCoordinator next = map.locations;
        expect(identical(next, old), false);
        expect(next.read(LocationRole.single), isA<LocationAbsent>());
        expect(
          (await next.synchronizeSavedLocations() as SavedLocationsAvailable)
              .locations,
          isEmpty,
        );
        expect(await stores['a']!.readLocal(), isEmpty);
      } finally {
        await shell.dispose();
        await disposeAccountPrivacy(privacy);
        await auth.changes.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

class ClearFailureStorage extends MemoryStorage {
  bool failClear = false;
  @override
  Future<void> clearLocal() async {
    if (failClear) throw StateError('QA store unavailable');
    await super.clearLocal();
  }
}
