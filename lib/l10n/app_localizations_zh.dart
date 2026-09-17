// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get signingOut => '正在退出';

  @override
  String get restoringSession => '正在检查登录状态';

  @override
  String get signOutIncomplete => '退出未完成';

  @override
  String get retrySignOut => '重试退出';

  @override
  String get sessionUnavailableTitle => '登录状态暂不可用';

  @override
  String get sessionRetryHint => '请连接网络后重试，以确认登录状态。';

  @override
  String get sessionRejectedHint => '登录状态已失效，请退出当前设备后重新登录。';

  @override
  String get sessionUnsupportedHint => '暂不支持登录，请检查应用配置或联系支持。';

  @override
  String get retry => '重试';

  @override
  String get signOutDevice => '退出当前设备';

  @override
  String get signedIn => '已登录';

  @override
  String get emailConfirmed => '邮箱已验证';

  @override
  String get emailVerificationRequired => '需要验证邮箱';

  @override
  String get emailConfirmationUnavailable => '邮箱验证状态暂不可用';

  @override
  String get retryUsername => '重试保存用户名';

  @override
  String get createAccount => '创建账户';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get registrationSubtitle => '创建账户，开始规划更适合你的生活。';

  @override
  String get signInSubtitle => '登录后继续查看地点、预算与房产实勘。';

  @override
  String get optionalUsername => '用户名（可选）';

  @override
  String get usernameHint => '输入用户名';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get emailRequired => '请输入邮箱。';

  @override
  String get emailInvalid => '请输入有效的邮箱地址。';

  @override
  String get passwordHint => '输入密码';

  @override
  String get hide => '隐藏';

  @override
  String get show => '显示';

  @override
  String get passwordRequired => '请输入密码。';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get confirmPasswordHint => '再次输入密码';

  @override
  String get passwordMismatch => '两次输入的密码不一致。';

  @override
  String get signIn => '登录';

  @override
  String get switchToSignIn => '已有账户？登录';

  @override
  String get switchToRegistration => '还没有账户？创建账户';

  @override
  String get confirmSignOut => '确认退出？';

  @override
  String get confirmSignOutBody => '是否结束当前设备上的登录？';

  @override
  String get cancel => '取消';

  @override
  String get signOut => '退出';

  @override
  String get signInSucceeded => '登录成功。';

  @override
  String get signInInvalidInput => '请输入邮箱和密码。';

  @override
  String get signInInvalidCredentials => '邮箱或密码不正确。';

  @override
  String get serviceUnavailable => '服务暂不可用，请重试。';

  @override
  String get signInUnsupportedClient => '当前设备暂时无法登录。';

  @override
  String get registrationAuthenticated => '账户创建成功。';

  @override
  String get registrationProfileFailed => '账户已创建，用户名保存失败，可稍后重试。';

  @override
  String get verificationEmailSent => '请查看邮件，完成邮箱验证后再登录。';

  @override
  String get verificationProfileRetryNeeded => '请验证邮箱，再登录以完成用户名设置。';

  @override
  String get registrationInvalidInput => '请检查必填项和确认密码。';

  @override
  String get registrationAccountExists => '该邮箱已注册。';

  @override
  String get registrationUnsupportedClient => '当前设备暂时无法注册。';

  @override
  String get profileRetrySucceeded => '用户名已保存。';

  @override
  String get profileRetryFailed => '用户名未保存，请检查格式或重试。';

  @override
  String get profileRetrySkipped => '当前设备没有待保存的用户名。';

  @override
  String get signOutRetryableUnavailable => '退出未完成，请连接网络后重试。';

  @override
  String get signOutRemoteRejected => '退出请求被拒绝，请重试或联系支持。';

  @override
  String get signOutUnsupportedClient => '当前设备无法完成退出，请检查应用配置。';

  @override
  String get sessionUnavailable => '暂时无法确认登录状态，请重试。';

  @override
  String get unknownError => '发生错误，请重试。';

  @override
  String get brandTagline => '找到更适合生活的地点';

  @override
  String get language => '语言';

  @override
  String get languageSaveFailed => '语言偏好未保存，请重试。';

  @override
  String get configurationMissing =>
      'LocateMY 尚未配置，请设置 Supabase 项目 URL 和 publishable key 后重启应用。';

  @override
  String get shellHome => '首页';

  @override
  String get shellMap => '地图';

  @override
  String get shellAccount => '账户';

  @override
  String get shellTask => '任务';

  @override
  String get shellPreparing => '正在准备应用，请稍候。';

  @override
  String get shellRecovery => '应用暂时不可用，请重试。';

  @override
  String get shellCleanupPending => '旧账户清理尚未完成，私有内容已关闭。请重试完成清理。';

  @override
  String get shellScopeUnavailable => '暂时无法确认账户范围，请重试。';

  @override
  String get shellFutureTask => '此功能将在后续开发阶段接入。';

  @override
  String get shellHomePending => '首页功能尚未接入。';

  @override
  String get shellMapPending => '地图功能尚未接入。当前没有选择地点。';

  @override
  String get shellAccountPending => '账户中心尚未接入。你可以在此退出当前设备。';

  @override
  String get homeTiming => '搬家时机';

  @override
  String get homeCost => '成本压力';

  @override
  String get homeEmployment => '就业稳定度';

  @override
  String get homeEconomy => '经济动能';

  @override
  String get homeIncome => '家庭收入中位数';

  @override
  String get homeNational => '马来西亚 · 全国搬迁环境';

  @override
  String get homeDisclaimer => '相对近期历史的指数，不是政府评级或对未来的保证。';

  @override
  String get homeRefresh => '刷新';

  @override
  String get homeExplore => '探索地图';

  @override
  String get homeLoading => '正在读取全国搬迁环境…';

  @override
  String get homeNominal => '按当年价格，未按通胀调整';

  @override
  String get homeCostDirection => '分数越高，表示相对成本压力越低。';

  @override
  String get homeLaborCaveat => '人口普查基准变化可能影响比较。';

  @override
  String get homePartial => '部分指标暂不可用；保留其他可用结果。';

  @override
  String get homeUnavailable => '暂不可用';

  @override
  String get homeObservedUnknown => '观测日期不可用';

  @override
  String homeCooling(int seconds) {
    return '$seconds 秒后可再次刷新';
  }

  @override
  String homeFetched(String date) {
    return '上次成功读取：$date';
  }

  @override
  String homeIncomeAmount(String amount, String year) {
    return 'RM $amount / 月 · $year 年调查';
  }

  @override
  String homeSource(String dataset, String date) {
    return '来源：DOSM / data.gov.my · $dataset · $date';
  }

  @override
  String homeNavigation(String reason) {
    return '暂不能进入地图：$reason';
  }

  @override
  String homeDirection(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'timing_favorable': '较适合',
      'timing_wait': '建议观望',
      'timing_defer': '暂缓较好',
      'cost_easing': '成本压力正在缓解',
      'cost_worsening': '成本压力正在加剧',
      'cost_stable': '成本压力大致稳定',
      'cost_lowerIsBetter': '分数越高，相对压力越低',
      'employment_improving': '就业稳定度改善',
      'employment_weakening': '就业稳定度转弱',
      'employment_stable': '就业稳定度大致稳定',
      'employment_comparisonUnavailable': '就业趋势比较暂不可用',
      'economy_expanding': '近期经济趋势：扩张',
      'economy_weakening': '近期经济趋势：转弱',
      'economy_stable': '近期经济趋势：大致稳定',
      'other': '暂不可用',
    });
    return '$_temp0';
  }

  @override
  String homeReason(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'sourceMissing': '来源资料缺失',
      'sourceSchemaChanged': '来源字段已变化',
      'insufficientHistory': '有效历史样本不足',
      'sourceDataUnverifiable': '来源资料无法验证',
      'retryableUnavailable': '连接暂不可用，请重试',
      'noCachedResult': '没有可用观测或缓存结果',
      'authenticationRequired': '请重新登录',
      'missingInput': '缺少必需输入',
      'staleInput': '此请求已过期',
      'inapplicableDestination': '目标页面不可用',
      'scopeUnavailable': '账户范围已关闭',
      'other': '暂不可用',
    });
    return '$_temp0';
  }

  @override
  String homeFreshness(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'fresh': '已验证在线读取；日期为资料观测日期',
      'cached': '缓存资料；刷新未替换已保存结果',
      'stale': '已过期缓存资料；请联网重试',
      'other': '暂不可用',
    });
    return '$_temp0';
  }

  @override
  String homeTrendSummary(int count) {
    return '近期趋势 · $count 个观测';
  }

  @override
  String get homeTrendApproximation => '根据当前观测重建；历史资料修订可能影响比较。';

  @override
  String get homeTrendUnavailable => '历史趋势暂不可用；请参阅上方方向说明。';

  @override
  String get homeGreeting => '准备看看搬家时机吗？';

  @override
  String get homeIndicators => '主要指标';

  @override
  String get homeDataDetails => '数据与说明';

  @override
  String get mapEnterAValidWGS84LatitudeAnd => '请输入合法 WGS84 纬度和经度。';

  @override
  String get mapChooseAPointOnMalaysianLand => '请选择马来西亚陆地范围内的地点。';

  @override
  String get mapAAndBMustBeDifferent => '地点 A 与地点 B 必须不同。';

  @override
  String get mapNameMustContain1120Characters => '名称须为 1–120 个字符。';

  @override
  String get mapSelectAValidatedLocationFirst => '请先选择合法地点。';

  @override
  String get mapDeletionRequiresAConnectionTheLocation => '删除需要联网；原收藏仍保留。';

  @override
  String get mapPermissionDeniedSignInAgain => '无访问权限，请重新登录。';

  @override
  String get mapTheLocationChangedOnAnotherDevice => '收藏已在其他设备改变，请重试同步。';

  @override
  String get mapThisSavedLocationNoLongerExists => '此收藏已不存在。';

  @override
  String get mapQueuedOnThisDeviceNotSynchronized => '已在本机排队 · 尚未同步。';

  @override
  String get mapSavedAndSynchronized => '已收藏并同步。';

  @override
  String get mapDeletedAndSynchronized => '已删除并同步。';

  @override
  String get mapAccountScopeUnavailableSignInAgain => '账户范围不可用，请重新登录。';

  @override
  String get mapThisRequestIsOutdatedSelectOr => '此请求已过期，请重新选择或刷新。';

  @override
  String get mapTemporarilyUnavailableTryAgain => '暂不可用，请重试。';

  @override
  String get mapSaveLocation => '收藏地点';

  @override
  String get mapName => '名称';

  @override
  String get mapCancel => '取消';

  @override
  String get mapSave => '保存';

  @override
  String get mapSetCurrentLocationAs => '将当前地点设为';

  @override
  String get mapLocationA => '地点 A';

  @override
  String get mapLocationB => '地点 B';

  @override
  String get mapSavedLocations => '收藏地点';

  @override
  String get mapSavedLocationsUnavailableRetrySynchronization =>
      '收藏暂不可用，请重试同步。';

  @override
  String get mapNoSavedLocations => '尚无收藏地点';

  @override
  String get mapCachedRetrySynchronization => '缓存记录 · 请重试同步';

  @override
  String get mapSynchronized => '已同步';

  @override
  String get mapQueuedNotSynchronized => '已排队 · 尚未同步';

  @override
  String get mapDelete => '删除';

  @override
  String get mapRetrySynchronization => '重试同步';

  @override
  String get mapSearchPlacesInMalaysia => '搜索马来西亚地点';

  @override
  String get mapEnterCoordinates => '输入坐标';

  @override
  String get mapSingle => '单点';

  @override
  String get mapCompareLocations => '两地比较';

  @override
  String get mapLayers => '图层';

  @override
  String get mapSaved => '收藏';

  @override
  String get mapRefresh => '刷新';

  @override
  String get mapClear => '清除';

  @override
  String get mapSearchUnavailableTryAgain => '搜索暂不可用，请重试。';

  @override
  String get mapNoPlacesFound => '未找到候选地点';

  @override
  String get mapSwapAB => '交换 A/B';

  @override
  String get mapNotSelected => '未选择';

  @override
  String get mapViewComparison => '查看地点比较';

  @override
  String get mapSelectALocation => '先选择地点';

  @override
  String get mapSelectedAnalysisLocation => '已选择分析地点';

  @override
  String get mapPersonalizedSuitabilityUnavailable => '个人化地点适配度暂不可用';

  @override
  String get mapViewFullAnalysis => '查看完整分析';

  @override
  String get mapStartComparison => '发起比较';

  @override
  String get mapSafetyIndex => '地区安全指数';

  @override
  String get mapCostOfLivingIndex => '本地生活成本指数';

  @override
  String get mapNearbyFacilities2Km => '周边设施 · 2 km';

  @override
  String get mapPublicTransportation15Km => '公共交通 · 1.5 km';

  @override
  String get mapInfrastructure => '基础设施';

  @override
  String get mapProviderNotConnectedDateSourceUnavailable => '提供方未接入；日期／来源不可用';

  @override
  String get mapLatitudeMustBeBetween90And => '纬度须介于 −90 与 90。';

  @override
  String get mapLongitudeMustBeBetween180And => '经度须介于 −180 与 180。';

  @override
  String get mapLatitude => '纬度';

  @override
  String get mapLongitude => '经度';

  @override
  String get mapSelect => '选择';

  @override
  String get mapHideSummary => '收起摘要';

  @override
  String get mapShowSummary => '展开摘要';

  @override
  String get mapPropertyLocation => '房产地点';

  @override
  String get mapNoLocationSelected => '地图：尚未选择地点。';

  @override
  String mapLocationSummary(
    String role,
    String name,
    String latitude,
    String longitude,
  ) {
    return '$role：$name。纬度 $latitude，经度 $longitude。';
  }

  @override
  String mapLayerPoint(String latitude, String longitude) {
    return '图层地点：纬度 $latitude，经度 $longitude。';
  }

  @override
  String get mapFeatureNotConnected => '此功能尚未接入';

  @override
  String get mapLocationRetained => '已保留所选地点，返回地图可继续选点。';
}
