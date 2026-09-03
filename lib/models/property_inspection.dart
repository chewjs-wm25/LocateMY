class PropertyInspection {
  final String id;
  final String name;
  final String address;
  final double price;
  final double rating; // 1-5
  final List<String> photos;
  final bool hasFloodHistory;
  final String notes;
  final DateTime updatedAt;

  PropertyInspection({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    this.rating = 0.0,
    this.photos = const [],
    this.hasFloodHistory = false,
    this.notes = '',
    required this.updatedAt,
  });

  PropertyInspection copyWith({
    String? name,
    String? address,
    double? price,
    double? rating,
    List<String>? photos,
    bool? hasFloodHistory,
    String? notes,
  }) {
    return PropertyInspection(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      photos: photos ?? this.photos,
      hasFloodHistory: hasFloodHistory ?? this.hasFloodHistory,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now(),
    );
  }
}
