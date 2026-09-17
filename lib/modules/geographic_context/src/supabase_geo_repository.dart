import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'geographic_context_models.dart';
import 'geographic_context_repository.dart';

final class SupabaseGeoRepository implements GeographicContextRepository {
  final SupabaseClient _supabase;

  SupabaseGeoRepository(SupabaseClient supabase) : _supabase = supabase;

  @override
  Future<List<Map<String, dynamic>>> fetchCandidates(
    double lat,
    double lng,
  ) async {
    final Session? session = _supabase.auth.currentSession;
    if (session == null ||
        session.user.emailConfirmedAt == null ||
        session.user.isAnonymous) {
      throw GeographicContextFailure.scopeUnavailable;
    }
    try {
      final dynamic response = await _supabase.rpc(
        'read_administrative_boundary_candidates',
        params: {'latitude': lat, 'longitude': lng},
      );
      if (!identical(session, _supabase.auth.currentSession)) {
        throw GeographicContextFailure.scopeUnavailable;
      }
      if (response is! List || _containsInvalidRow(response)) {
        throw GeographicContextFailure.versionUnverifiable;
      }
      return response.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      // Postgrest wraps a malformed 2xx JSON body using its HTTP status code.
      final int? status = int.tryParse(e.code ?? '');
      if (status != null && status >= 200 && status < 300) {
        throw GeographicContextFailure.versionUnverifiable;
      }
      if (status == 401 ||
          status == 403 ||
          e.code == '42501' ||
          e.code == 'PGRST301' ||
          e.code == 'PGRST302' ||
          e.code == 'PGRST303') {
        throw GeographicContextFailure.scopeUnavailable;
      }
      throw GeographicContextFailure.sourceUnavailable;
    } on AuthException {
      throw GeographicContextFailure.scopeUnavailable;
    } on http.ClientException {
      throw GeographicContextFailure.sourceUnavailable;
    } on IOException {
      throw GeographicContextFailure.sourceUnavailable;
    } on TimeoutException {
      throw GeographicContextFailure.sourceUnavailable;
    } on FormatException {
      throw GeographicContextFailure.versionUnverifiable;
    }
  }

  bool _containsInvalidRow(List<dynamic> rows) {
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) {
        return true;
      }
    }
    return false;
  }
}
