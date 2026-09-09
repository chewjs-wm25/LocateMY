import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locate_my/modules/module_a/models/map/hazard_marker.dart';
import 'package:locate_my/modules/module_a/repositories/map/map_repository.dart';

class HazardViewModel extends ChangeNotifier {
  final MapRepository _mapRepository = MapRepository();
  List<HazardMarker> _hazards = [];

  List<HazardMarker> get hazards => List.unmodifiable(_hazards);

  HazardViewModel() {
    refreshHazards();
  }

  Future<void> refreshHazards() async {
    _hazards = await _mapRepository.fetchHazards();
    notifyListeners();
  }

  void addHazard(HazardMarker hazard) {
    _hazards.add(hazard);
    notifyListeners();
  }

  Future<void> createHazard({
    required String title,
    required String description,
    required dynamic location, // LatLng
    required HazardType type,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final newHazard = HazardMarker(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      location: location,
      type: type,
      createdBy: user?.id ?? 'Anonymous',
      createdAt: DateTime.now(),
    );

    // Optimistic update
    _hazards.add(newHazard);
    notifyListeners();

    final success = await _mapRepository.saveHazard(newHazard);
    if (!success) {
      _hazards.removeWhere((h) => h.id == newHazard.id);
      notifyListeners();
    } else {
      // Small delay to ensure Supabase indexing is complete before refresh
      await Future.delayed(const Duration(milliseconds: 800));
      await refreshHazards();
    }
  }

  Future<List<HazardMarker>> getUserHazards() async {
    return await _mapRepository.fetchUserHazards();
  }

  Future<bool> removeHazard(String id) async {
    final success = await _mapRepository.deleteHazard(id);
    if (success) {
      _hazards.removeWhere((h) => h.id == id);
      notifyListeners();
    }
    return success;
  }

  void updateHazard(
    String id, {
    String? title,
    String? description,
    HazardType? type,
  }) {
    final index = _hazards.indexWhere((h) => h.id == id);
    if (index != -1) {
      _hazards[index] = _hazards[index].copyWith(
        title: title,
        description: description,
        type: type,
      );
      notifyListeners();
    }
  }

  void deleteHazard(String id) {
    _hazards.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  void voteHazard(String id, bool isUpvote) {
    final index = _hazards.indexWhere((h) => h.id == id);
    if (index != -1) {
      final hazard = _hazards[index];
      if (isUpvote) {
        _hazards[index] = hazard.copyWith(upvotes: hazard.upvotes + 1);
      } else {
        _hazards[index] = hazard.copyWith(downvotes: hazard.downvotes + 1);
      }
      notifyListeners();
    }
  }
}
