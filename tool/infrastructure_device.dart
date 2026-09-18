

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:locatemy/app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int fixturePort = int.fromEnvironment(
  'LOCATEMY_INFRASTRUCTURE_FIXTURE_PORT',
);

final class _FixtureProxy extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    client.findProxy = (Uri uri) {
      if (uri.host == '127.0.0.1') {
        return 'DIRECT';
      }
      return 'PROXY 127.0.0.1:$fixturePort';
    };
    return client;
  }
}

Future<void> main() async {
  HttpOverrides.global = _FixtureProxy();
  final HttpClient fixture = HttpClient();
  try {
    final HttpClientRequest request = await fixture.getUrl(
      Uri.parse('http://127.0.0.1:$fixturePort/fixture'),
    );
    final HttpClientResponse response = await request.close();
    final Map<String, dynamic> credentials = jsonDecode(
      await utf8.decoder.bind(response).join(),
    ) as Map<String, dynamic>;
    await startLocateMy();
    await Supabase.instance.client.auth.signInWithPassword(
      email: credentials['LOCATEMY_EMAIL'] as String,
      password: credentials['LOCATEMY_PASSWORD'] as String,
    );
    debugPrint('INFRASTRUCTURE_DEVICE: REAL_SIGNED_IN');
  } catch (_) {
    debugPrint('INFRASTRUCTURE_DEVICE: FAILED (details redacted)');
    exitCode = 1;
  } finally {
    fixture.close();
  }
}
