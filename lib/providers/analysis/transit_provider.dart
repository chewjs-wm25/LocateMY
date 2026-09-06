import 'package:flutter/material.dart';
import '../../core/supabase/supabase_client_manager.dart';

class TransitProvider extends ChangeNotifier {
  final SupabaseClientManager _supabase = SupabaseClientManager();
  
  List<Map<String, dynamic>> _nearbyStops = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get nearbyStops => _nearbyStops;
  bool get isLoading => _isLoading;

  String? _lastLocationKey;

  Future<void> loadNearbyStops(double lat, double lng) async {
    final locationKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    if (_nearbyStops.isNotEmpty && _lastLocationKey == locationKey) return;

    _isLoading = true;
    _lastLocationKey = locationKey;
    notifyListeners();
    try {
      final results = await _supabase.rpc('get_nearby_transit_stops', params: {
        'user_lng': lng,
        'user_lat': lat,
      });
      _nearbyStops = List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('Error loading transit stops: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
