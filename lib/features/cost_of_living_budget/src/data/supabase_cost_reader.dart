// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/cost_service.dart';
import '../domain/cost_models.dart';

final class SupabaseCostPublicReader implements CostPublicReader {
  final SupabaseClient _client;
  SupabaseCostPublicReader(SupabaseClient client) : _client = client;
  @override
  Future<Map<String, Object?>> read(String state, String district) async {
    try {
      final Object? result = await _client
          .rpc(
            'read_cost_inputs',
            params: <String, Object?>{
              'input_state': state,
              'input_district': district,
            },
          )
          .timeout(const Duration(seconds: 30));
      if (result is! Map) {
        throw const FormatException('Invalid cost result');
      }
      return Map<String, Object?>.from(result);
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        throw const CostPublicFailure(CostAnalysisFailure.permissionDenied);
      }
      throw const CostPublicFailure(CostAnalysisFailure.retryableUnavailable);
    }
  }
}
