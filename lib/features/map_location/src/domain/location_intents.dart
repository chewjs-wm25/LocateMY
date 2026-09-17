// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import '../../../../app/application_shell.dart';
import 'location_models.dart';

final class OpenAnalysisIntent implements ShellIntent {
  final ValidLocationReference location;
  const OpenAnalysisIntent({required ValidLocationReference location})
    : location = location;
}

final class OpenLocationComparisonIntent implements ShellIntent {
  final ValidLocationReference locationA, locationB;
  const OpenLocationComparisonIntent({
    required ValidLocationReference locationA,
    required ValidLocationReference locationB,
  }) : locationA = locationA,
       locationB = locationB;
}

final class OpenMapLayerIntent implements ShellIntent {
  final MapLayerIntent intent;
  const OpenMapLayerIntent(MapLayerIntent intent) : intent = intent;
}
