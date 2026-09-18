

import 'package:locatemy/features/map_location/map_location.dart';


final class AnalysisReturnContext {
  final ValidLocationReference location;
  final LocationRole role;
  final DateTime analysisDate;
  const AnalysisReturnContext({
    required ValidLocationReference location,
    required LocationRole role,
    required DateTime analysisDate,
  }) : location = location,
       role = role,
       analysisDate = analysisDate;
}
