// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/safety_inputs_reader.dart';

final class SupabaseSafetyInputsReader implements SafetyInputsReader {
  final SupabaseClient _client;
  SupabaseSafetyInputsReader(SupabaseClient client) : _client = client;
  @override
  Future<Map<String, Object?>> readSafetyInputs() async {
    final Object? response = await _client
        .rpc('read_safety_inputs')
        .timeout(const Duration(seconds: 20));
    if (response is! Map) {
      throw const FormatException('Safety inputs must be an object');
    }
    return Map<String, Object?>.from(response);
  }
}
