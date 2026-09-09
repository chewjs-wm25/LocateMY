import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:locate_my/modules/module_a/view_models/home/home_view_model.dart';
import 'package:locate_my/modules/module_a/view_models/infrastructure/infrastructure_view_model.dart';
import 'package:locate_my/modules/module_a/view_models/infrastructure/nearby_facilities_view_model.dart';
import 'package:locate_my/modules/module_a/view_models/map/hazard_view_model.dart';
import 'package:locate_my/modules/module_a/view_models/map/location_view_model.dart';
import 'package:locate_my/modules/module_a/view_models/transport/transit_view_model.dart';

List<SingleChildWidget> get moduleAProviders => [
  ChangeNotifierProvider(create: (_) => LocationViewModel()),
  ChangeNotifierProvider(create: (_) => HazardViewModel()),
  ChangeNotifierProvider(create: (_) => HomeViewModel()),
  ChangeNotifierProvider(create: (_) => NearbyFacilitiesViewModel()),
  ChangeNotifierProvider(create: (_) => InfrastructureViewModel()),
  ChangeNotifierProvider(create: (_) => TransitViewModel()),
];
