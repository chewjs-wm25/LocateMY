import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:locate_my/modules/module_b/view_models/auth/auth_view_model.dart';
import 'package:locate_my/modules/module_b/view_models/cost_of_living/budget_view_model.dart';
import 'package:locate_my/modules/module_b/view_models/property/property_view_model.dart';
import 'package:locate_my/modules/module_b/view_models/security/security_view_model.dart';
import 'package:locate_my/modules/module_b/view_models/socio_economic/socio_economic_view_model.dart';

List<SingleChildWidget> get moduleBProviders => [
  ChangeNotifierProvider(create: (_) => AuthViewModel()),
  ChangeNotifierProvider(create: (_) => BudgetViewModel()),
  ChangeNotifierProvider(create: (_) => PropertyViewModel()),
  ChangeNotifierProvider(create: (_) => SecurityViewModel()),
  ChangeNotifierProvider(create: (_) => SocioEconomicViewModel()),
];
