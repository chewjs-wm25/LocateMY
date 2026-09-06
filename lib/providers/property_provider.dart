import 'package:flutter/material.dart';
import '../models/property_inspection.dart';
import '../repositories/security_risk_repository.dart';

class PropertyProvider extends ChangeNotifier {
  final List<PropertyInspection> _inspections = [
    PropertyInspection(
      id: '1',
      name: 'Skyline Residence',
      address: 'Kuala Lumpur (Hazard Area)',
      price: 2500.0,
      rating: 4.5,
      notes: 'Modern apartment, excellent drainage system.',
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      latitude: 3.1390,
      longitude: 101.6869,
      policeDistrict: 'Dang Wangi',
      securityScore: 8.8,
      monsoonChecklist: {
        'drainage_score': 5,
        'waterproofing_score': 4,
        'humidity_score': 4,
        'lighting_score': 5,
      },
      nearbyHazardsCount: 0,
    ),
    PropertyInspection(
      id: '2',
      name: 'Penang Heritage Stay',
      address: 'Penang Island',
      price: 1800.0,
      rating: 3.5,
      notes: 'Beautiful heritage building, but check roof for leaks.',
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      latitude: 5.4141,
      longitude: 100.3288,
      policeDistrict: 'Georgetown',
      securityScore: 8.2,
      monsoonChecklist: {
        'drainage_score': 4,
        'waterproofing_score': 3,
        'humidity_score': 3,
        'lighting_score': 5,
      },
      nearbyHazardsCount: 1,
    ),
    PropertyInspection(
      id: '3',
      name: 'JB Waterfront Condo',
      address: 'Johor Bahru',
      price: 2200.0,
      rating: 4.0,
      notes: 'Stunning view, high-end security.',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      latitude: 1.4927,
      longitude: 103.7414,
      policeDistrict: 'JB Central',
      securityScore: 7.5,
      monsoonChecklist: {
        'drainage_score': 4,
        'waterproofing_score': 4,
        'humidity_score': 5,
        'lighting_score': 3,
      },
      nearbyHazardsCount: 1,
    ),
    PropertyInspection(
      id: '4',
      name: 'Kinabalu Peak Apartment',
      address: 'Kota Kinabalu',
      price: 1500.0,
      rating: 3.2,
      notes: 'Cool mountain air, but distance to hospital is far.',
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      latitude: 5.9804,
      longitude: 116.0735,
      policeDistrict: 'KK North',
      securityScore: 8.5,
      monsoonChecklist: {
        'drainage_score': 3,
        'waterproofing_score': 2,
        'humidity_score': 2,
        'lighting_score': 4,
      },
      nearbyHazardsCount: 0,
    ),
    PropertyInspection(
      id: '5',
      name: 'Kuching River View',
      address: 'Kuching',
      price: 1900.0,
      rating: 2.8,
      notes: 'Close to the river, high humidity and flood history.',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      hasFloodHistory: true,
      latitude: 1.5533,
      longitude: 110.3592,
      policeDistrict: 'Kuching City',
      securityScore: 7.0,
      monsoonChecklist: {
        'drainage_score': 2,
        'waterproofing_score': 3,
        'humidity_score': 2,
        'lighting_score': 4,
      },
      nearbyHazardsCount: 2,
    ),
  ];
  final List<PropertyInspection> _recycleBin = [];
  final SecurityRiskRepository _riskRepository = SecurityRiskRepository();

  List<PropertyInspection> get inspections => List.unmodifiable(_inspections);
  List<PropertyInspection> get recycleBin => List.unmodifiable(_recycleBin);

  bool _isLoadingRiskData = false;
  bool get isLoadingRiskData => _isLoadingRiskData;

  // Draft persistence in memory
  String _draftName = '';
  String _draftPrice = '';
  String? _draftSavedLocationId;
  Map<String, int> _draftMonsoonChecklist = {
    'drainage_score': 3,
    'waterproofing_score': 3,
    'humidity_score': 3,
    'lighting_score': 3,
  };

  String get draftName => _draftName;
  String get draftPrice => _draftPrice;
  String? get draftSavedLocationId => _draftSavedLocationId;
  Map<String, int> get draftMonsoonChecklist => _draftMonsoonChecklist;

  void updateDraft({
    String? name,
    String? price,
    String? savedLocationId,
    Map<String, int>? monsoonChecklist,
  }) {
    if (name != null) _draftName = name;
    if (price != null) _draftPrice = price;
    if (savedLocationId != null) _draftSavedLocationId = savedLocationId;
    if (monsoonChecklist != null) _draftMonsoonChecklist = Map.from(monsoonChecklist);
    notifyListeners();
  }

  void clearDraft() {
    _draftName = '';
    _draftPrice = '';
    _draftSavedLocationId = null;
    _draftMonsoonChecklist = {
      'drainage_score': 3,
      'waterproofing_score': 3,
      'humidity_score': 3,
      'lighting_score': 3,
    };
    notifyListeners();
  }

  Future<void> addInspection({
    required String name,
    required String address,
    required double price,
    double rating = 0.0,
    String notes = '',
    double? latitude,
    double? longitude,
    Map<String, int>? monsoonChecklist,
    List<String>? photos,
    int mainPhotoIndex = 0,
    bool hasFloodHistory = false,
  }) async {
    _isLoadingRiskData = true;
    notifyListeners();

    String? policeDistrict;
    double? securityScore;
    int nearbyHazardsCount = 0;

    if (latitude != null && longitude != null) {
      final riskData = await _riskRepository.getRiskContext(latitude, longitude);
      policeDistrict = riskData['police_district'];
      securityScore = double.tryParse(riskData['security_score']);
      nearbyHazardsCount = riskData['nearby_hazards_count'];
    }

    final newInspection = PropertyInspection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      address: address,
      price: price,
      rating: rating,
      notes: notes,
      photos: photos ?? [],
      mainPhotoIndex: mainPhotoIndex,
      updatedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      policeDistrict: policeDistrict,
      securityScore: securityScore,
      hasFloodHistory: hasFloodHistory,
      monsoonChecklist: monsoonChecklist ?? {
        'drainage_score': 3,
        'waterproofing_score': 3,
        'humidity_score': 3,
        'lighting_score': 3,
      },
      nearbyHazardsCount: nearbyHazardsCount,
    );

    _inspections.add(newInspection);
    _isLoadingRiskData = false;
    notifyListeners();
  }

  Future<void> updateInspection(String id, {
    String? name,
    String? address,
    double? price,
    double? rating,
    String? notes,
    bool? hasFloodHistory,
    Map<String, int>? monsoonChecklist,
    List<String>? photos,
    int? mainPhotoIndex,
    double? latitude,
    double? longitude,
  }) async {
    final index = _inspections.indexWhere((i) => i.id == id);
    if (index != -1) {
      String? policeDistrict;
      double? securityScore;
      int? nearbyHazardsCount;

      // If location changed, refresh risk data
      if (latitude != null && longitude != null && 
          (latitude != _inspections[index].latitude || longitude != _inspections[index].longitude)) {
        
        _isLoadingRiskData = true;
        notifyListeners();
        
        final riskData = await _riskRepository.getRiskContext(latitude, longitude);
        policeDistrict = riskData['police_district'];
        securityScore = double.tryParse(riskData['security_score']);
        nearbyHazardsCount = riskData['nearby_hazards_count'];
        
        _isLoadingRiskData = false;
      }

      _inspections[index] = _inspections[index].copyWith(
        name: name,
        address: address,
        price: price,
        rating: rating,
        notes: notes,
        hasFloodHistory: hasFloodHistory,
        monsoonChecklist: monsoonChecklist,
        photos: photos,
        mainPhotoIndex: mainPhotoIndex,
        latitude: latitude,
        longitude: longitude,
        policeDistrict: policeDistrict,
        securityScore: securityScore,
        nearbyHazardsCount: nearbyHazardsCount,
      );
      notifyListeners();
    }
  }

  void deleteInspection(String id) {
    final index = _inspections.indexWhere((i) => i.id == id);
    if (index != -1) {
      _recycleBin.add(_inspections[index]);
      _inspections.removeAt(index);
      notifyListeners();
    }
  }

  void restoreInspection(String id) {
    final index = _recycleBin.indexWhere((i) => i.id == id);
    if (index != -1) {
      _inspections.add(_recycleBin[index]);
      _recycleBin.removeAt(index);
      notifyListeners();
    }
  }

  void clearRecycleBin() {
    _recycleBin.clear();
    notifyListeners();
  }
}
