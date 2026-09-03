class BudgetScenario {
  final String id;
  final String name;
  final double housingWeight;
  final double foodWeight;
  final double transportWeight;
  final double entertainmentWeight;
  final DateTime updatedAt;

  BudgetScenario({
    required this.id,
    required this.name,
    this.housingWeight = 0.5,
    this.foodWeight = 0.3,
    this.transportWeight = 0.2,
    this.entertainmentWeight = 0.1,
    required this.updatedAt,
  });

  BudgetScenario copyWith({
    String? name,
    double? housingWeight,
    double? foodWeight,
    double? transportWeight,
    double? entertainmentWeight,
  }) {
    return BudgetScenario(
      id: id,
      name: name ?? this.name,
      housingWeight: housingWeight ?? this.housingWeight,
      foodWeight: foodWeight ?? this.foodWeight,
      transportWeight: transportWeight ?? this.transportWeight,
      entertainmentWeight: entertainmentWeight ?? this.entertainmentWeight,
      updatedAt: DateTime.now(),
    );
  }
}
