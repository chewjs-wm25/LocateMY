import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/app/app.dart';
import 'package:locatemy/app/application_shell.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/authentication_session/authentication_session.dart';

import '../support/fake_authentication_session.dart';
import 'application_shell_test.dart' show ControlledPrivacy;

void main() {
  test('production shell binding retains exact immutable analysis and comparison input', () async {
    final FakeAuthenticationSession auth = FakeAuthenticationSession()
      ..restored = const AuthenticatedSession(accountA);
    final ControlledPrivacy privacy = ControlledPrivacy();
    late ShellRuntime shell;
    shell = ShellRuntime.compose(
      authentication: auth,
      privacy: () => privacy,
      intents: mapShellBindings(() => shell),
    );
    await shell.initialize();
    final LocationCoordinator map = createLocationCoordinator(
      scope: shell.state.scope!,
      readScope: privacy.readScope,
      validatePoint: (_) async => true,
    );
    final LocationSelected selected = await map.select(
      const LocationSelectionRequest(
        role: LocationRole.single,
        point: GeographicPoint(latitude: 3, longitude: 101),
      ),
    ) as LocationSelected;
    final OpenAnalysisIntent intent = OpenAnalysisIntent(
      location: selected.location,
    );
    expect(
      await shell.applicationShell!.submit(intent),
      isA<ShellIntentAccepted>(),
    );
    expect(identical(shell.state.routes.single.intent, intent), true);
    final ApplicationShell old = shell.applicationShell!;
    await shell.signOut();
    expect(await old.submit(intent), isA<ShellAuthenticationRequired>());
    await shell.dispose();
    await auth.changes.close();
  });
}
