

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/transit_models.dart';
import '../application/transit_analysis_reader.dart';

final class SupabaseTransitReader implements TransitAnalysisReader {
  final SupabaseClient _client;
  SupabaseTransitReader(SupabaseClient client) : _client = client;
  @override
  Future<Map<String, Object?>> readTransitAnalysis(
    TransitRequest request,
  ) async {
    final Object response = await _client.rpc(
      'read_transit_analysis',
      params: <String, Object?>{
        'p_latitude': request.location.point.latitude,
        'p_longitude': request.location.point.longitude,
        'p_analysis_date': request.analysisDate.toIso8601String().substring(
          0,
          10,
        ),
        'p_refresh': request.policy == TransitLoadPolicy.refresh,
      },
    );
    if (response is! Map) {
      throw const FormatException('Transit RPC response is not an object');
    }
    return Map<String, Object?>.from(response);
  }
}
