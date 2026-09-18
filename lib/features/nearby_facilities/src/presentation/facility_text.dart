import 'package:flutter/widgets.dart';

import '../domain/facility_models.dart';

final class FacilityText {
  final bool english;
  FacilityText(BuildContext context)
    : english = Localizations.localeOf(context).languageCode == 'en';
  String pick(String chinese, String englishText) {
    if (english) {
      return englishText;
    }
    return chinese;
  }

  String category(FacilityCategory value) {
    return pick(
      const <String>['医疗健康', '教育资源', '日常生活', '交通出行', '休闲与绿地'][value.index],
      const <String>[
        'Health',
        'Education',
        'Daily living',
        'Transport',
        'Leisure and green space',
      ][value.index],
    );
  }

  String failure(FacilityFailure value) {
    switch (value) {
      case FacilityFailure.invalidLocation:
        return pick(
          '地点坐标无效，请重新选点。',
          'Invalid coordinates. Select a location again.',
        );
      case FacilityFailure.sameComparisonPoint:
        return pick(
          'A/B 为同一地点，请选择不同地点。',
          'A and B are the same point. Select different locations.',
        );
      case FacilityFailure.sourceUnavailable:
        return pick('网络或数据来源暂不可用。', 'Network or data source unavailable.');
      case FacilityFailure.rateLimited:
        return pick('数据来源请求过多，请稍后重试。', 'Too many requests. Try again later.');
      case FacilityFailure.invalidPayload:
        return pick('设施资料暂不可用，请重试。', 'Facility data unavailable. Retry.');
      case FacilityFailure.incompleteResponse:
        return pick(
          '查询结果不完整，无法确认设施覆盖。',
          'The response is incomplete; coverage is unknown.',
        );
      case FacilityFailure.retryableUnavailable:
        return pick('查询中断，请重试。', 'The query was interrupted. Retry.');
      case FacilityFailure.scopeUnavailable:
        return pick('账户会话已关闭，请重新登录。', 'Account session closed. Sign in again.');
    }
  }

  String comparisonFailure(FacilityComparisonFailure failure) {
    switch (failure) {
      case FacilityComparisonFailure.locationAUnavailable:
        return pick('地点 A 资料不可用', 'Location A unavailable');
      case FacilityComparisonFailure.locationBUnavailable:
        return pick('地点 B 资料不可用', 'Location B unavailable');
      case FacilityComparisonFailure.incompleteResult:
        return pick('设施资料不完整', 'Incomplete coverage');
      case FacilityComparisonFailure.incompatibleRadius:
        return pick('分析半径不同', 'Different radii');
      case FacilityComparisonFailure.incompatibleMappingVersion:
        return pick('资料口径不同', 'Incompatible data');
    }
  }
}
