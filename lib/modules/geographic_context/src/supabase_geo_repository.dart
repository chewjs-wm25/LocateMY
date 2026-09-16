import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

class SupabaseGeoRepository {
  final SupabaseClient _supabase;

  SupabaseGeoRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchCandidates(double lat, double lng) async {
    try {
      final response = await _supabase.rpc(
        'read_administrative_boundary_candidates',
        params: {'latitude': lat, 'longitude': lng},
      );
      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw GeographicContextFailure.scopeUnavailable;
      }
      throw GeographicContextFailure.sourceUnavailable;
    } catch (_) {
      throw GeographicContextFailure.sourceUnavailable;
    }
  }
}