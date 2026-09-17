import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/home_dependencies.dart';
import '../domain/home_models.dart';

final class SupabaseHomeReader implements HomeReader {
  final SupabaseClient client;

  SupabaseHomeReader(this.client);

  @override
  Future<Map<String, dynamic>> read() async {
    try {
      final result = await client
          .rpc('read_home_metrics')
          .timeout(const Duration(seconds: 20));
      if (result is! Map ||
          result['version'] != 1 ||
          result['datasets'] is! Map) {
        throw const HomeReadFailure(HomeUnavailableReason.sourceSchemaChanged);
      }
      return Map<String, dynamic>.from(result);
    } on HomeReadFailure {
      rethrow;
    } on PostgrestException catch (e) {
      final List<String> schemaErrorCodes = <String>[
        '42703',
        '42883',
        'PGRST202',
        'PGRST204',
      ];
      final HomeUnavailableReason reason;
      if (schemaErrorCodes.contains(e.code)) {
        reason = HomeUnavailableReason.sourceSchemaChanged;
      } else {
        reason = HomeUnavailableReason.retryableUnavailable;
      }
      throw HomeReadFailure(reason);
    } catch (_) {
      throw const HomeReadFailure(HomeUnavailableReason.retryableUnavailable);
    }
  }
}
