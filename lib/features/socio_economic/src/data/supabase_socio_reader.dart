

import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/socio_service.dart';

final class SupabaseSocioInputsReader implements SocioInputsReader {
  final SupabaseClient _client;
  SupabaseSocioInputsReader(SupabaseClient client) : _client = client;
  @override
  Future<Map<String, Object?>> read(String state, String? district) async {
    final Object? response = await _client
        .rpc(
          'read_socio_inputs',
          params: <String, Object?>{'p_state': state, 'p_district': district},
        )
        .timeout(const Duration(seconds: 20));
    if (response is! Map ||
        response['version'] != 1 ||
        response['state'] != state ||
        response['district'] != district) {
      throw const FormatException('Invalid Socio envelope');
    }
    for (final String key in <String>[
      'income_district',
      'income_state',
      'gini_district',
      'gini_state',
      'percentiles',
    ]) {
      if (response[key] is! List) {
        throw const FormatException('Invalid Socio observations');
      }
    }
    return Map<String, Object?>.from(response);
  }
}
