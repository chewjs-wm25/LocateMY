import 'package:sqflite/sqflite.dart';

import '../cost_of_living_budget/cost_of_living_budget.dart';
import '../../modules/geographic_context/geographic_context.dart';
import 'src/application/socio_service.dart';
import 'src/data/socio_cache.dart';
import 'src/domain/socio_models.dart';
export 'src/application/socio_service.dart' show SocioInputsReader;
export 'src/domain/socio_models.dart';
export 'src/data/supabase_socio_reader.dart';
export 'src/presentation/socio_economic_page.dart' show SocioEconomicPage;

SocioEconomic createSocioEconomic({
  required GeographicContext geographicContext,
  required SocioInputsReader reader,
  CurrentBudgetReader? budget,
  Database? database,
  DateTime Function()? clock,
}) {
  return SocioService(
    geographicContext,
    reader,
    budget,
    database == null ? null : SocioCache(database, clock ?? DateTime.now),
  );
}
