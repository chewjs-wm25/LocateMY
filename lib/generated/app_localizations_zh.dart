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
  String get analysisReport => '分析报告';

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
  String get stableInflationInfo => '通胀稳定，是搬迁的理想时机。';

  @override
  String get indexLabel => '指数';

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
  String get food => '食品';

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
  String get lowRisk => '低风险';

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
  String get incomeClassDistribution => '收入阶层分布';

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
    return '您的收入优于该地区 $percent% 的家庭（基于该县收入分布估算）。';
  }

  @override
  String get infrastructureCoverage => '基础设施普及率 (ICI)';

  @override
  String get excellent => '极佳';

  @override
  String get good => '良好';

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

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get username => '用户名';

  @override
  String get enterUsername => '输入您的用户名';

  @override
  String get invalidUsername => '用户名只能包含字母、数字和空格，且必须包含至少3个字母或数字';

  @override
  String get email => '电子邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get loginTitle => '欢迎回来';

  @override
  String get registerTitle => '创建账号';

  @override
  String get noAccount => '还没有账号？点击注册';

  @override
  String get alreadyHaveAccount => '已有账号？点击登录';

  @override
  String get invalidEmail => '请输入有效的电子邮箱地址';

  @override
  String get passwordTooShort => '密码至少需要 8 个字符';

  @override
  String get passwordComplexityError => '密码须包含大小写字母、数字及特殊符号（禁止空格）';

  @override
  String get passwordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get authError => '认证失败，请重试';

  @override
  String get errorInvalidCredentials => '邮箱或密码错误';

  @override
  String get errorUserAlreadyRegistered => '该邮箱已被注册';

  @override
  String get errorEmailNotConfirmed => '邮箱未验证，请检查您的收件箱';

  @override
  String get errorTooManyRequests => '请求过于频繁，请稍后再试';

  @override
  String get errorUnexpected => '发生未知错误，请重试';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get registerSuccess => '注册成功，请查收验证邮件';

  @override
  String get enterEmail => '输入您的邮箱';

  @override
  String get enterPassword => '输入您的密码';

  @override
  String get reportHazard => '报告隐患';

  @override
  String get hazardTitle => '标题';

  @override
  String get hazardDescription => '描述';

  @override
  String get hazardType => '类型';

  @override
  String get add => '添加';

  @override
  String get cancel => '取消';

  @override
  String get newScenario => '新建预案';

  @override
  String get scenarioName => '预案名称';

  @override
  String get create => '创建';

  @override
  String get addProperty => '添加房源';

  @override
  String get propertyName => '房源名称';

  @override
  String get address => '地址';

  @override
  String get price => '价格';

  @override
  String get propertyPortfolio => '房源档案库';

  @override
  String get budgetTranslation => '预算平移';

  @override
  String lifestyleComparisonText(
    Object dest,
    Object percent,
    Object change,
    Object origin,
  ) {
    return '要在$dest维持您目前在$origin的生活方式，您需要的预算$change$percent%。';
  }

  @override
  String get microPriceInsight => '微观物价透视 (5公里)';

  @override
  String get viewStores => '查看商家';

  @override
  String get realTimePriceComparison => '目标位置方圆 5 公里内核心物资的实时价格对比。';

  @override
  String get eggs => 'A级鸡蛋 (10粒)';

  @override
  String get chicken => '肉鸡 (1公斤)';

  @override
  String get bread => '白面包';

  @override
  String get petrol => '汽油 (RON95/升)';

  @override
  String get less => '减少';

  @override
  String get more => '增加';

  @override
  String get monthly => '按月';

  @override
  String get savedLocations => '已储存地点';

  @override
  String get saveCurrentLocation => '储存当前地点';

  @override
  String get saveLocation => '储存地点';

  @override
  String get pickOnMap => '在地图上选取';

  @override
  String get selectSavedLocation => '选择已储存地点';

  @override
  String get enterLocationName => '输入地点名称';

  @override
  String get locationName => '地点名称';

  @override
  String get delete => '删除';

  @override
  String get noSavedLocations => '暂无已储存地点';

  @override
  String get outOfMalaysiaRange => '所选地点超出马来西亚范围';

  @override
  String get clearSelection => '清除选择';

  @override
  String get securityRiskAssessment => '治安与风险评估';

  @override
  String get policeDistrict => '所属警区';

  @override
  String get securityScore => '治安评分';

  @override
  String get monsoonChecklist => '雨季验房清单';

  @override
  String get nearbyHazards => '周边隐患';

  @override
  String get drainage => '排水';

  @override
  String get waterproofing => '防水';

  @override
  String get humidity => '防潮';

  @override
  String get lighting => '照明';

  @override
  String get fetchingRiskData => '正在获取风险数据...';

  @override
  String get propertyDetails => '房源详情';

  @override
  String get saveProperty => '保存房源';

  @override
  String get mainImage => '主图';

  @override
  String get tapToSetMainImage => '点击图片设为主图';

  @override
  String get swipeForMore => '向左滑动查看更多';

  @override
  String totalPhotos(Object count) {
    return '共 $count 张图片';
  }

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get editScenario => '编辑预案';

  @override
  String get expenseIncrease => '开销增加';
}
