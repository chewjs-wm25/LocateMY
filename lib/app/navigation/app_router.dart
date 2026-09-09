import 'package:flutter/material.dart';
import 'package:locate_my/app/navigation/app_route_names.dart';
import 'package:locate_my/modules/module_a/views/map/reported_hazards_screen.dart';
import 'package:locate_my/modules/module_b/views/cost_of_living/cost_of_living_view.dart';
import 'package:locate_my/modules/module_b/views/security/crime_security_view.dart';
import 'package:locate_my/modules/module_b/views/socio_economic/socio_economic_view.dart';

abstract final class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case AppRouteNames.costOfLiving:
        page = const CostOfLivingView();
        break;
      case AppRouteNames.crimeSecurity:
        page = const CrimeSecurityView();
        break;
      case AppRouteNames.socioEconomic:
        page = const SocioEconomicView();
        break;
      case AppRouteNames.reportedHazards:
        page = const ReportedHazardsScreen();
        break;
      default:
        return null;
    }

    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
