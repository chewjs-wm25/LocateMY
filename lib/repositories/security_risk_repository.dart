import '../core/supabase/supabase_client_manager.dart';

class SecurityRiskRepository {
  final SupabaseClientManager _supabase = SupabaseClientManager();

  // Simulate fetching security and risk data based on coordinates
  Future<Map<String, dynamic>> getRiskContext(double lat, double lng) async {
    // 1. Match coordinates to district via Supabase RPC
    final districtMatch = await _supabase.rpc('match_police_district', params: {'lat': lat, 'lng': lng});
    final districtInfo = (districtMatch as List).isNotEmpty ? districtMatch.first : {'name': 'Kuala Lumpur', 'id': 'PD-KL'};
    final districtName = districtInfo['name'];

    // 2. Fetch raw crime stats and user-generated hazards (对接真实表)
    final crimeStatsList = await _supabase.from('crime_stats').select().eq('district', districtName);
    final hazards = await _supabase.from('crowdsourced_hazards').select().eq('district', districtName);

    // Derive score from crimes
    int totalCrimes = 0;
    for (var crime in crimeStatsList) {
      totalCrimes += (crime['crimes'] as int);
    }
    double securityScore = (9.8 - (totalCrimes / 500.0)).clamp(0.0, 10.0);

    return {
      'police_district': districtName,
      'security_score': securityScore.toStringAsFixed(1),
      'nearby_hazards_count': hazards.length,
      'crime_stats': { for (var e in crimeStatsList) e['category'] as String : e['crimes'] as int }
    };
  }
}
