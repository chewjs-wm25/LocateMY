import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/hazard_marker.dart';

class HazardProvider extends ChangeNotifier {
  final List<HazardMarker> _hazards = [
    HazardMarker(
      id: 'test-1',
      title: 'Frequent Flash Flood',
      description: 'Water rises quickly during heavy rain. Avoid parking near the drain.',
      location: const LatLng(3.1478, 101.6945),
      type: HazardType.flood,
      upvotes: 12,
      createdBy: 'System',
      createdAt: DateTime.now(),
    ),
    HazardMarker(
      id: 'test-2',
      title: 'Construction Blockage',
      description: 'Main road partially closed due to subway construction.',
      location: const LatLng(3.1550, 101.7100),
      type: HazardType.traffic,
      upvotes: 5,
      createdBy: 'System',
      createdAt: DateTime.now(),
    ),
    HazardMarker(
      id: 'test-3',
      title: 'Poor Lighting at Night',
      description: 'Several street lights are broken in this alley.',
      location: const LatLng(3.1350, 101.6750),
      type: HazardType.crime,
      upvotes: 8,
      createdBy: 'System',
      createdAt: DateTime.now(),
    ),
  ];

  List<HazardMarker> get hazards => List.unmodifiable(_hazards);

  void addHazard(HazardMarker hazard) {
    _hazards.add(hazard);
    notifyListeners();
  }

  void createHazard({
    required String title,
    required String description,
    required dynamic location, // LatLng
    required HazardType type,
  }) {
    final newHazard = HazardMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      location: location,
      type: type,
      createdBy: 'currentUser',
      createdAt: DateTime.now(),
    );
    _hazards.add(newHazard);
    notifyListeners();
  }

  void updateHazard(String id, {String? title, String? description, HazardType? type}) {
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
