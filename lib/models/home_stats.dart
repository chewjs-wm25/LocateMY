class HomeStats {
  final double? gdpGrowth;
  final List<GDPDataPoint>? gdpTrend;
  final double? unemploymentRate;
  final double? unemploymentTrend;
  final int? medianIncome;
  final double? incomeTrend;
  final double? inflationRate;
  final double? oprRate;
  final double? relocationIndex;
  final bool isIciFallback; // 新增：标记 ICI 是否使用回退值
  final DateTime lastUpdated;

  HomeStats({
    this.gdpGrowth,
    this.gdpTrend,
    this.unemploymentRate,
    this.unemploymentTrend,
    this.medianIncome,
    this.incomeTrend,
    this.inflationRate,
    this.oprRate,
    this.relocationIndex,
    this.isIciFallback = false,
    required this.lastUpdated,
  });

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    return HomeStats(
      gdpGrowth: json['gdpGrowth'] != null ? (json['gdpGrowth'] as num).toDouble() : null,
      gdpTrend: json['gdpTrend'] != null 
          ? (json['gdpTrend'] as List).map((e) => GDPDataPoint.fromJson(e)).toList() 
          : null,
      unemploymentRate: json['unemploymentRate'] != null ? (json['unemploymentRate'] as num).toDouble() : null,
      unemploymentTrend: json['unemploymentTrend'] != null ? (json['unemploymentTrend'] as num).toDouble() : null,
      medianIncome: json['medianIncome'] as int?,
      incomeTrend: json['incomeTrend'] != null ? (json['incomeTrend'] as num).toDouble() : null,
      inflationRate: json['inflationRate'] != null ? (json['inflationRate'] as num).toDouble() : null,
      oprRate: json['oprRate'] != null ? (json['oprRate'] as num).toDouble() : null,
      relocationIndex: json['relocationIndex'] != null ? (json['relocationIndex'] as num).toDouble() : null,
      isIciFallback: json['isIciFallback'] ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gdpGrowth': gdpGrowth,
      'gdpTrend': gdpTrend?.map((e) => e.toJson()).toList(),
      'unemploymentRate': unemploymentRate,
      'unemploymentTrend': unemploymentTrend,
      'medianIncome': medianIncome,
      'incomeTrend': incomeTrend,
      'inflationRate': inflationRate,
      'oprRate': oprRate,
      'relocationIndex': relocationIndex,
      'isIciFallback': isIciFallback,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class GDPDataPoint {
  final String year;
  final double value;

  GDPDataPoint({required this.year, required this.value});

  factory GDPDataPoint.fromJson(Map<String, dynamic> json) {
    return GDPDataPoint(
      year: json['year'],
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'value': value,
    };
  }
}
