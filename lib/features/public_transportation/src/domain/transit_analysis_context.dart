// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:locatemy/features/map_location/map_location.dart';

/// Location, role and date supplied directly to a transportation page.
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
