import 'package:flutter/material.dart';

import '../domain/hazard_models.dart';

final class HazardStrings {
  final bool chinese;
  HazardStrings(BuildContext context)
    : chinese = Localizations.localeOf(context).languageCode == 'zh';
  String text(String english, String chineseText) {
    if (chinese) {
      return chineseText;
    }
    return english;
  }

  String type(HazardType type) {
    switch (type) {
      case HazardType.flood:
        return text('Flood', '水灾');
      case HazardType.crime:
        return text('Crime', '治安');
      case HazardType.traffic:
        return text('Traffic', '交通');
      case HazardType.infrastructure:
        return text('Infrastructure', '基础设施');
      case HazardType.other:
        return text('Other', '其他');
    }
  }

  String status(HazardAuthorStatus status) {
    if (status == HazardAuthorStatus.pending) {
      return text('Pending', '待处理');
    }
    return text('Resolved', '已解决');
  }

  String failure(HazardWriteFailure failure) {
    switch (failure) {
      case HazardWriteFailure.invalidType:
        return text('Choose a hazard type.', '请选择隐患类型。');
      case HazardWriteFailure.emptyTitle:
        return text('Enter a title.', '请输入标题。');
      case HazardWriteFailure.titleTooLong:
        return text('Title must contain 1–120 characters.', '标题须为 1–120 字。');
      case HazardWriteFailure.descriptionTooLong:
        return text(
          'Description must be at most 2,000 characters.',
          '描述不能超过 2,000 字。',
        );
      case HazardWriteFailure.invalidLocation:
        return text('Choose a validated map location.', '请从地图选择有效位置。');
      case HazardWriteFailure.authenticationRequired:
      case HazardWriteFailure.scopeUnavailable:
        return text(
          'Your account is unavailable. Sign in again.',
          '账户不可用，请重新登录。',
        );
      case HazardWriteFailure.permissionDenied:
        return text('Only the author can manage this report.', '只有作者可以管理此报告。');
      case HazardWriteFailure.conflict:
        return text('The report changed. Refresh and retry.', '报告已改变，请刷新后重试。');
      case HazardWriteFailure.notFound:
        return text('This report no longer exists.', '此报告已不存在。');
      case HazardWriteFailure.immutableContent:
        return text('Published content cannot be edited.', '发布后的内容不可编辑。');
      case HazardWriteFailure.retryableUnavailable:
        return text(
          'Unavailable. Retry while online; your input is retained.',
          '暂时不可用，请联网重试；输入已保留。',
        );
    }
  }

  String readFailure(HazardReadFailure failure) {
    switch (failure) {
      case HazardReadFailure.authenticationRequired:
      case HazardReadFailure.scopeUnavailable:
        return text(
          'Your account is unavailable. Sign in again.',
          '账户不可用，请重新登录。',
        );
      case HazardReadFailure.notFound:
        return text('This report no longer exists.', '此报告已不存在。');
      case HazardReadFailure.invalidViewport:
        return text('Move the map and retry.', '请移动地图后重试。');
      case HazardReadFailure.incompletePage:
        return text(
          'Some reports could not be loaded. Retry.',
          '部分报告未能加载，请重试。',
        );
      case HazardReadFailure.retryableUnavailable:
        return text(
          'Could not refresh. Previous content is retained. Retry.',
          '刷新失败，已保留上次内容。请重试。',
        );
    }
  }
}
