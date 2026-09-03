import 'package:flutter/material.dart';
import '../models/property_inspection.dart';

class PropertyProvider extends ChangeNotifier {
  final List<PropertyInspection> _inspections = [];

  List<PropertyInspection> get inspections => List.unmodifiable(_inspections);

  void addInspection({
    required String name,
    required String address,
    required double price,
    double rating = 0.0,
    String notes = '',
  }) {
    final newInspection = PropertyInspection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      address: address,
      price: price,
      rating: rating,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    _inspections.add(newInspection);
    notifyListeners();
  }

  void updateInspection(String id, {
    String? name,
    String? address,
    double? price,
    double? rating,
    String? notes,
    bool? hasFloodHistory,
  }) {
    final index = _inspections.indexWhere((i) => i.id == id);
    if (index != -1) {
      _inspections[index] = _inspections[index].copyWith(
        name: name,
        address: address,
        price: price,
        rating: rating,
        notes: notes,
        hasFloodHistory: hasFloodHistory,
      );
      notifyListeners();
    }
  }

  void deleteInspection(String id) {
    _inspections.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
