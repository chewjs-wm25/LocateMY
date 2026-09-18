

import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/infrastructure_service.dart';
import '../domain/infrastructure_models.dart';

final class SupabaseInfrastructureInputsReader
    implements InfrastructureInputsReader {
  final SupabaseClient _client;
  SupabaseInfrastructureInputsReader(SupabaseClient client) : _client = client;
  @override
  Future<Map<String, Object?>> read(String state, String district) async {
    final Object? response = await _client
        .rpc(
          'read_infrastructure_inputs',
          params: <String, Object?>{'p_state': state, 'p_district': district},
        )
        .timeout(const Duration(seconds: 20));
    if (response is! Map ||
        response['version'] != 1 ||
        response['state'] != state ||
        response['district'] != district) {
      throw const FormatException('Invalid infrastructure scope');
    }
    for (final String field in <String>[
      'amenities',
      'beds',
      'population',
      'schools',
      'teachers',
      'enrolment',
    ]) {
      if (response[field] is! List) {
        throw const FormatException('Invalid infrastructure inputs');
      }
    }
    return Map<String, Object?>.from(response);
  }
}

final class SupabaseInfrastructureWeightsStore
    implements InfrastructureWeightsStore {
  final SupabaseClient _client;
  final String _accountId;
  SupabaseInfrastructureWeightsStore(SupabaseClient client)
    : _client = client,
      _accountId = client.auth.currentUser!.id;
  void _checkAccount() {
    if (_client.auth.currentUser?.id != _accountId) {
      throw StateError('Account changed');
    }
  }

  @override
  Future<InfrastructureWeightSettings> read() async {
    _checkAccount();
    final Map<String, dynamic>? row = await _client
        .from('user_ici_preferences')
        .select('health,education,transit')
        .eq('user_id', _accountId)
        .maybeSingle()
        .timeout(const Duration(seconds: 20));
    _checkAccount();
    if (row == null) {
      return const InfrastructureWeightSettings();
    }
    final InfrastructureWeightSettings weights = InfrastructureWeightSettings(
      health: row['health'] as int,
      education: row['education'] as int,
      transit: row['transit'] as int,
    );
    if (!weights.valid) {
      throw const FormatException('Invalid priorities');
    }
    return weights;
  }

  @override
  Future<void> save(InfrastructureWeightSettings weights) async {
    _checkAccount();
    if (!weights.valid) {
      throw ArgumentError('Priorities must be 1–10');
    }
    await _client
        .from('user_ici_preferences')
        .upsert(<String, Object?>{
          'user_id': _accountId,
          ...weights.toMap(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .timeout(const Duration(seconds: 20));
    _checkAccount();
  }
}
