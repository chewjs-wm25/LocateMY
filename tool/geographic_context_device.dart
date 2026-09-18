

import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: GeographicVerification()));
}

class GeographicVerification extends StatefulWidget {
  const GeographicVerification({super.key});
  @override
  State<GeographicVerification> createState() => _GeographicVerificationState();
}

class _GeographicVerificationState extends State<GeographicVerification> {
  final lines = <String>[];
  final client = SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  void record(String message) {
    debugPrint('GEO_DEVICE: $message');
    if (mounted) setState(() => lines.add(message));
  }

  @override
  void initState() {
    super.initState();
    verify();
  }

  Future<void> verify() async {
    final geo = createGeographicContext(client);
    GeographicContextRequest request(double lat, double lng) =>
        GeographicContextRequest(
          location: ValidLocationReference(
            locationId: 'map-validated-fixture',
            point: GeographicPoint(latitude: lat, longitude: lng),
          ),
          levels: GeographicLevel.values.toSet(),
        );
    Future<void> login() => client.auth.signInWithPassword(
      email: const String.fromEnvironment('LOCATEMY_GEO_EMAIL'),
      password: const String.fromEnvironment('LOCATEMY_GEO_PASSWORD'),
    );
    try {
      record('START: public seam / no private data');
      final blocked = await geo.resolve(request(3.103135, 101.550947699441));
      if (blocked is! GeographicContextUnavailable ||
          blocked.failure != GeographicContextFailure.scopeUnavailable) {
        throw StateError('initial gate');
      }
      record('PASS: signed-out scopeUnavailable');
      await login();
      if (client.auth.currentUser == null) {
        throw StateError('login required');
      }
      
      
      final samples = [
        ('single', 3.103135, 101.550947699441),
        ('boundary', 3.22238, 101.56576),
        ('island', 2.297005, 104.120960241975),
        ('noCoverage', 4.0, 109.0),
      ];
      for (final s in samples) {
        final result = await geo.resolve(request(s.$2, s.$3));
        if (result is! GeographicContextAvailable) {
          throw StateError('sample ${s.$1}');
        }
        final district = result.results[GeographicLevel.district];
        if (s.$1 == 'boundary' && district is! GeographicLevelAmbiguous ||
            s.$1 == 'noCoverage' && district is! GeographicLevelUnresolved ||
            (s.$1 == 'single' || s.$1 == 'island') &&
                district is! GeographicLevelResolved) {
          throw StateError('classification ${s.$1}');
        }
        record('PASS: ${s.$1} ${district.runtimeType}');
      }
      await client.auth.signOut(scope: SignOutScope.local);
      final signedOut = await geo.resolve(request(3.103135, 101.550947699441));
      if (signedOut is! GeographicContextUnavailable ||
          signedOut.failure != GeographicContextFailure.scopeUnavailable) {
        throw StateError('logout gate');
      }
      record('PASS: logout scopeUnavailable');
      await login();
      if (await geo.resolve(request(3.103135, 101.550947699441))
          is! GeographicContextAvailable) {
        throw StateError('recovery');
      }
      record('PASS: login recovery');
      await client.auth.signOut(scope: SignOutScope.local);
      record('ALL PASS');
    } catch (e) {
      record('FAILED: ${e.runtimeType}');
    } finally {
      await client.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Geographic Context · Wave 1')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: lines
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(s),
            ),
          )
          .toList(),
    ),
  );
}
