

import 'package:flutter/widgets.dart';

import '../domain/safety_models.dart';

final class SafetyStrings {
  final bool zh;
  SafetyStrings(BuildContext context)
    : zh = Localizations.localeOf(context).languageCode == 'zh';
  String text(String en, String cn) {
    if (zh) {
      return cn;
    }
    return en;
  }

  String get title {
    return text('Crime and security', '治安与犯罪');
  }

  String get unavailable {
    return text('Unavailable', '暂不可用');
  }

  String category(String key) {
    switch (key) {
      case 'all':
        return text('All', '全部');
      case 'assault':
        return text('Violent crime', '暴力犯罪');
      case 'property':
        return text('Property crime', '财产犯罪');
      case 'type:murder':
        return text('Murder', '谋杀');
      case 'type:rape':
        return text('Rape', '强奸');
      case 'type:causing_injury':
        return text('Causing injury', '伤害');
      case 'type:break_in':
        return text('Break-in', '入室盗窃');
      case 'type:theft_other':
        return text('Other theft', '其他盗窃');
      case 'type:theft_vehicle_lorry':
        return text('Lorry theft', '货车盗窃');
      case 'type:theft_vehicle_motorcar':
        return text('Car theft', '汽车盗窃');
      case 'type:theft_vehicle_motorcycle':
        return text('Motorcycle theft', '摩托车盗窃');
      case 'type:robbery_gang_armed':
        return text('Armed gang robbery', '持械团伙抢劫');
      case 'type:robbery_gang_unarmed':
        return text('Unarmed gang robbery', '无械团伙抢劫');
      case 'type:robbery_solo_armed':
        return text('Armed solo robbery', '持械个人抢劫');
      case 'type:robbery_solo_unarmed':
        return text('Unarmed solo robbery', '无械个人抢劫');
      default:
        return text(
          'Crime type: ${key.substring(5)}',
          '犯罪类型：${key.substring(5)}',
        );
    }
  }

  String failure(SafetyFailure? reason) {
    if (reason == SafetyFailure.geographicContext) {
      return text(
        'The reporting state could not be determined.',
        '无法确定地点所属统计州。',
      );
    }
    if (reason == SafetyFailure.noData) {
      return text(
        'No valid crime data for the complete year.',
        '完整年度暂无有效犯罪资料。',
      );
    }
    if (reason == SafetyFailure.sourceUnverifiable) {
      return text(
        'Crime data could not be verified. Try again.',
        '治安资料暂无法验证，请重试。',
      );
    }
    return text('Unable to load crime data. Try again.', '治安资料暂无法加载，请重试。');
  }
}
