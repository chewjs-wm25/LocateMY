import 'package:flutter_dotenv/flutter_dotenv.dart';

final class SupabaseConfig {
  static String get url =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '') != ''
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.maybeGet('SUPABASE_URL') ?? '';

  static String get publishableKey =>
      const String.fromEnvironment(
            'SUPABASE_PUBLISHABLE_KEY',
            defaultValue: '',
          ) !=
          ''
      ? const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY')
      : dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ?? '';

  static void validate() {
    if ((Uri.tryParse(url)?.host.isEmpty ?? true) ||
        !(url.startsWith('https://') || url.startsWith('http://')) ||
        !publishableKey.startsWith('sb_publishable_')) {
      throw StateError('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY.');
    }
  }
}
