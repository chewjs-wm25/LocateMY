import 'package:locatemy/models/location.dart';

enum CostSource { officialObservation, modelAssumption, userInput }

extension CostSourceLabel on CostSource {
  String get label => switch (this) {
    CostSource.officialObservation => '官方观测',
    CostSource.modelAssumption => '模型假设',
    CostSource.userInput => '用户输入',
  };
}

class CostBasketItem {
  const CostBasketItem({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.weight,
    required this.source,
    required this.merchantCount,
    required this.recordCount,
    required this.months,
    this.klUnitPrice,
    this.penangUnitPrice,
  });

  final String name;
  final String unit;
  final double quantity;
  final double weight;
  final CostSource source;
  final int merchantCount;
  final int recordCount;
  final int months;
  final double? klUnitPrice;
  final double? penangUnitPrice;

  double? unitPriceFor(Place place) =>
      place == Place.kl ? klUnitPrice : penangUnitPrice;

  double? monthlyCostFor(Place place, double quantityMultiplier) {
    final unitPrice = unitPriceFor(place);
    return unitPrice == null ? null : unitPrice * quantity * quantityMultiplier;
  }
}

const costBasketItems = [
  CostBasketItem(
    name: '食米',
    unit: '5 kg',
    quantity: 1,
    weight: .08,
    source: CostSource.officialObservation,
    merchantCount: 12,
    recordCount: 86,
    months: 10,
    klUnitPrice: 34,
    penangUnitPrice: 31,
  ),
  CostBasketItem(
    name: '鸡蛋',
    unit: '10 粒',
    quantity: 2,
    weight: .04,
    source: CostSource.officialObservation,
    merchantCount: 15,
    recordCount: 104,
    months: 10,
    klUnitPrice: 6.5,
    penangUnitPrice: 5.8,
  ),
  CostBasketItem(
    name: '鸡肉',
    unit: 'kg',
    quantity: 4,
    weight: .08,
    source: CostSource.officialObservation,
    merchantCount: 11,
    recordCount: 73,
    months: 9,
    klUnitPrice: 12,
    penangUnitPrice: 11,
  ),
  CostBasketItem(
    name: '午餐',
    unit: '份',
    quantity: 20,
    weight: .12,
    source: CostSource.officialObservation,
    merchantCount: 18,
    recordCount: 132,
    months: 10,
    klUnitPrice: 15,
    penangUnitPrice: 13,
  ),
  CostBasketItem(
    name: '食用油',
    unit: '1 kg',
    quantity: 2,
    weight: .04,
    source: CostSource.officialObservation,
    merchantCount: 13,
    recordCount: 91,
    months: 10,
    klUnitPrice: 18,
    penangUnitPrice: 17,
  ),
  CostBasketItem(
    name: '水电燃气与通信',
    unit: '月',
    quantity: 1,
    weight: .18,
    source: CostSource.modelAssumption,
    merchantCount: 0,
    recordCount: 0,
    months: 12,
    klUnitPrice: 360,
    penangUnitPrice: 330,
  ),
  CostBasketItem(
    name: '医疗与药品',
    unit: '月',
    quantity: 1,
    weight: .10,
    source: CostSource.modelAssumption,
    merchantCount: 0,
    recordCount: 0,
    months: 12,
    klUnitPrice: 140,
    penangUnitPrice: 120,
  ),
  CostBasketItem(
    name: '教育／托育',
    unit: '月',
    quantity: 1,
    weight: .12,
    source: CostSource.modelAssumption,
    merchantCount: 0,
    recordCount: 0,
    months: 12,
    klUnitPrice: 180,
    penangUnitPrice: 160,
  ),
  CostBasketItem(
    name: '个人用品与服务',
    unit: '月',
    quantity: 1,
    weight: .10,
    source: CostSource.modelAssumption,
    merchantCount: 0,
    recordCount: 0,
    months: 12,
    klUnitPrice: 180,
    penangUnitPrice: 160,
  ),
  CostBasketItem(
    name: '休闲／其他',
    unit: '月',
    quantity: 1,
    weight: .14,
    source: CostSource.modelAssumption,
    merchantCount: 0,
    recordCount: 0,
    months: 12,
    klUnitPrice: 400,
    penangUnitPrice: 360,
  ),
];

class CostReport {
  const CostReport({
    required this.place,
    required this.items,
    required this.availableMonths,
    required this.housingMonthly,
    required this.transportMonthly,
    required this.quantityMultiplier,
  });

  static const baseSpend12 = 3710.0;

  final Place place;
  final List<CostBasketItem> items;
  final int availableMonths;
  final double? housingMonthly;
  final double? transportMonthly;
  final double quantityMultiplier;

  Iterable<CostBasketItem> get availableItems =>
      items.where((item) => item.unitPriceFor(place) != null);

  Iterable<CostBasketItem> get missingItems =>
      items.where((item) => item.unitPriceFor(place) == null);

  double get coverage =>
      availableItems.fold<double>(0, (sum, item) => sum + item.weight);

  double get observedSpend => availableItems.fold<double>(
    0,
    (sum, item) => sum + (item.monthlyCostFor(place, quantityMultiplier) ?? 0),
  );

  bool get hasScenarioInputs =>
      housingMonthly != null && transportMonthly != null;

  double? get scenarioSpend => hasScenarioInputs
      ? observedSpend + housingMonthly! + transportMonthly!
      : null;

  bool get meetsDataQuality => availableMonths >= 6 && coverage >= .8;

  bool get hasCompleteIndex => meetsDataQuality && hasScenarioInputs;

  double? get costIndex =>
      hasCompleteIndex ? 100 * scenarioSpend! / baseSpend12 : null;

  double? get locationBudgetBurden =>
      scenarioSpend == null ? null : 100 * scenarioSpend! / incomeMedian;

  double? personalBudgetBurden(double? monthlyNetIncome) =>
      scenarioSpend == null || monthlyNetIncome == null || monthlyNetIncome <= 0
      ? null
      : 100 * scenarioSpend! / monthlyNetIncome;

  String get coverageText => '${(coverage * 100).round()}%';

  double get incomeMedian => place == Place.kl ? 6420 : 5980;
}

CostReport buildCostReport({
  required Place place,
  required double? housingMonthly,
  required double? transportMonthly,
  required double quantityMultiplier,
  bool dataShortage = false,
}) {
  final missingNames = dataShortage ? {'鸡肉', '午餐', '食用油'} : <String>{};
  final items = costBasketItems
      .map(
        (item) => missingNames.contains(item.name)
            ? CostBasketItem(
                name: item.name,
                unit: item.unit,
                quantity: item.quantity,
                weight: item.weight,
                source: item.source,
                merchantCount: item.merchantCount,
                recordCount: item.recordCount,
                months: 5,
              )
            : item,
      )
      .toList();
  return CostReport(
    place: place,
    items: items,
    availableMonths: dataShortage ? 5 : (place == Place.kl ? 9 : 10),
    housingMonthly: housingMonthly,
    transportMonthly: transportMonthly,
    quantityMultiplier: quantityMultiplier,
  );
}
