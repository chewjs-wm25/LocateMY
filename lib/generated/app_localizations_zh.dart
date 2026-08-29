// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'UI 原型展示';

  @override
  String get navHome => '首页';

  @override
  String get navMap => '地图';

  @override
  String get navCost => '开销';

  @override
  String get navSecurity => '治安';

  @override
  String get navSocioEconomic => '社会经济';

  @override
  String get navInfrastructure => '设施';

  @override
  String get navTransport => '交通';

  @override
  String get titleHome => 'LocateMY';

  @override
  String get titleMap => '地点探索';

  @override
  String get titleCost => '生活开销分析';

  @override
  String get titleSecurity => '治安与风险预警';

  @override
  String get titleSocioEconomic => '社会经济分析';

  @override
  String get titleInfrastructure => '基础设施评估';

  @override
  String get titleTransport => '公共交通与通勤';

  @override
  String get displayMode => '显示模式';

  @override
  String get comparisonMode => '对比模式';

  @override
  String get currentAddress => '原住址';

  @override
  String get newAddress => '新住址';

  @override
  String get searchLocation => '搜索地点';

  @override
  String get selectOnMap => '在地图上选取';

  @override
  String get costOfLiving => '生活开销';

  @override
  String get crimeSecurity => '治安与安全';

  @override
  String get socioEconomic => '社会经济';

  @override
  String get infrastructure => '基础设施';

  @override
  String get transportation => '交通运输';

  @override
  String get unemployment => '失业率';

  @override
  String get medianIncome => '收入中位数';

  @override
  String get economicGrowth => '经济增长 (GDP %)';

  @override
  String get cpiInflation => 'CPI 通胀率';

  @override
  String get oprRate => 'OPR 利率';

  @override
  String get startExploring => '开始探索地点';

  @override
  String get favorablePeriod => '适宜时期';

  @override
  String get goodTimeToRelocate => '搬迁的好时机';

  @override
  String get stableInflationInfo => '通胀稳定且处于旱季，非常理想。';

  @override
  String get indexLabel => '指数';

  @override
  String get interMonsoon => '季候风交替期';

  @override
  String get lowFloodRisk => '低水灾风险';

  @override
  String get idealForMoving => '目前非常适合搬家。';

  @override
  String get nextPeak => '下个高峰期：11月';

  @override
  String get locationSelection => '地点选择';

  @override
  String get origin => '出发地';

  @override
  String get destination => '目的地';

  @override
  String get kl => '吉隆坡';

  @override
  String get pg => '槟城';

  @override
  String get jb => '新山';

  @override
  String get ip => '怡保';

  @override
  String get purchasingPower => '购买力预测';

  @override
  String get significantImprovement => '显著提升';

  @override
  String get expectedQualityImprovement => '预计生活质量提升';

  @override
  String get housingExpenditure => '住房支出';

  @override
  String get foodPrices => '食品物价';

  @override
  String monthlySaving(Object value) {
    return '每月节省约 RM $value';
  }

  @override
  String get priceCatcherData => 'PriceCatcher 实时数据';

  @override
  String get expenditureComparison => '各类开销对比';

  @override
  String get weightAdjustment => '权重调整 (个性化开销)';

  @override
  String get housing => '住房';

  @override
  String get transport => '交通';

  @override
  String get entertainment => '娱乐';

  @override
  String get safetyMapLayer => '安全分布图层';

  @override
  String get cherasArea => '吉隆坡 - 蕉赖区';

  @override
  String get overallSafetyIndex => '综合安全指数';

  @override
  String betterThanNational(Object percent) {
    return '优于全国 $percent% 地区';
  }

  @override
  String get floodRiskLevel => '水灾风险等级';

  @override
  String get lowRisk => '低风险';

  @override
  String get noFloodHistory => '近 5 年无淹水记录';

  @override
  String get crimeTypeFocus => '犯罪类别关注';

  @override
  String get violentCrime => '暴力犯罪';

  @override
  String get propertyCrime => '财产犯罪';

  @override
  String get cyberFraud => '网络诈骗';

  @override
  String get crimeTrend => '犯罪率历史趋势';

  @override
  String get warningBanner => '注意：当前正值东北季候风季节，低洼地区有潜在积水风险。';

  @override
  String get incomeClassDistribution => '收入阶层分布 (2024)';

  @override
  String get dosmOfficialData => 'DOSM 官方数据';

  @override
  String get lowIncome => '低收入层';

  @override
  String get middleClass => '中产阶层';

  @override
  String get highIncome => '高收入层';

  @override
  String m40HigherThanAverage(Object percent) {
    return '该地区的 M40 群体占比高于全国平均水平 ($percent%)';
  }

  @override
  String get developmentRanking => '地区发展排名';

  @override
  String rankNumber(Object rank) {
    return '第 $rank 名';
  }

  @override
  String totalConstituencies(Object total) {
    return '共 $total 个选区';
  }

  @override
  String get giniCoefficient => '基尼系数 (不平等性)';

  @override
  String get moderate => '适中';

  @override
  String get incomeDistributionCurve => '家庭月收入分布曲线';

  @override
  String get yourIncomePosition => '您的收入排位';

  @override
  String get monthlyHouseholdIncome => '家庭月收入 (RM)';

  @override
  String incomeBetterThan(Object percent) {
    return '您的收入优于该地区 $percent% 的家庭，属于 M40 高端区间。';
  }

  @override
  String get infrastructureCoverage => '基础设施普及率 (ICI)';

  @override
  String get excellent => '极佳';

  @override
  String get iciDescription => '该项指标综合了水、电、通信与公共服务覆盖度';

  @override
  String get waterSupply => '供水系统';

  @override
  String get electricNetwork => '电力网络';

  @override
  String get medicalDensity => '医疗密度';

  @override
  String get educationalResources => '教育资源';

  @override
  String get high => '高';

  @override
  String get sufficient => '充足';

  @override
  String get iciRadarChart => 'ICI 维度平衡雷达图';

  @override
  String get personalizedWeight => '个性化需求权重';

  @override
  String get medicalImportance => '医疗服务重要性';

  @override
  String get educationPriority => '教育资源优先度';

  @override
  String get commercialConvenience => '商业配套便利度';

  @override
  String get connectivityScore => '连通性综合评分';

  @override
  String get highlyConvenient => '高度便利';

  @override
  String betterThanKL(Object percent) {
    return '优于 $percent% 的雪隆区地段';
  }

  @override
  String get nearbyStations => '周边主要站点 (500m 内)';

  @override
  String get walking => '步行';

  @override
  String get pedestrianBridge => '人行天桥连接';

  @override
  String get trafficDensityHeatmap => '交通网路密度热力图';

  @override
  String get viewDetails => '查看详情';

  @override
  String get commuteModeDistribution => '通勤模式分布';

  @override
  String get accountCenter => '账户中心';

  @override
  String get verifiedUser => '已认证用户';

  @override
  String get relocationHistory => '搬迁评估历史';

  @override
  String get defaultLocation => '默认地点';

  @override
  String get savedComparisons => '已保存的对比';

  @override
  String assessmentDate(Object date) {
    return '评估日期: $date';
  }

  @override
  String get myComments => '我的评论';

  @override
  String get likedAreas => '已点赞地区';

  @override
  String get logout => '退出登录';
}
