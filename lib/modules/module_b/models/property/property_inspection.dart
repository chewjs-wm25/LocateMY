class PropertyInspection {
  final String id;
  final String name;
  final String address;
  final double price;
  final double rating; // 1-5
  final List<String> photos;
  final int mainPhotoIndex;
  final bool hasFloodHistory;
  final String notes;
  final DateTime updatedAt;

  // New fields for Security & Risk
  final double? latitude;
  final double? longitude;
  final String? policeDistrict;
  final double? securityScore; // 0-10
  final Map<String, int> monsoonChecklist;
  final int nearbyHazardsCount;

  PropertyInspection({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    this.rating = 0.0,
    this.photos = const [],
    this.mainPhotoIndex = 0,
    this.hasFloodHistory = false,
    this.notes = '',
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.policeDistrict,
    this.securityScore,
    this.monsoonChecklist = const {
      'drainage_score': 3,
      'waterproofing_score': 3,
      'humidity_score': 3,
      'lighting_score': 3,
    },
    this.nearbyHazardsCount = 0,
  });

  PropertyInspection copyWith({
    String? name,
    String? address,
    double? price,
    double? rating,
    List<String>? photos,
    int? mainPhotoIndex,
    bool? hasFloodHistory,
    String? notes,
    double? latitude,
    double? longitude,
    String? policeDistrict,
    double? securityScore,
    Map<String, int>? monsoonChecklist,
    int? nearbyHazardsCount,
  }) {
    return PropertyInspection(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      photos: photos ?? this.photos,
      mainPhotoIndex: mainPhotoIndex ?? this.mainPhotoIndex,
      hasFloodHistory: hasFloodHistory ?? this.hasFloodHistory,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now(),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      policeDistrict: policeDistrict ?? this.policeDistrict,
      securityScore: securityScore ?? this.securityScore,
      monsoonChecklist: monsoonChecklist ?? this.monsoonChecklist,
      nearbyHazardsCount: nearbyHazardsCount ?? this.nearbyHazardsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'price': price,
      'rating': rating,
      'photos': photos,
      'mainPhotoIndex': mainPhotoIndex,
      'hasFloodHistory': hasFloodHistory,
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'policeDistrict': policeDistrict,
      'securityScore': securityScore,
      'monsoonChecklist': monsoonChecklist,
      'nearbyHazardsCount': nearbyHazardsCount,
    };
  }
}
