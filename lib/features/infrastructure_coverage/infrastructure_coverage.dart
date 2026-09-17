import 'package:sqflite/sqflite.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:locatemy/features/public_transportation/public_transportation.dart';

import 'src/application/infrastructure_service.dart';
import 'src/data/infrastructure_cache.dart';
// Infrastructure COVERAGE entry point. Consumers must not import src/.
export 'src/application/infrastructure_service.dart';
export 'src/domain/infrastructure_models.dart';
export 'src/presentation/infrastructure_coverage_page.dart';
export 'src/presentation/infrastructure_view_model.dart';

export 'src/data/supabase_infrastructure.dart';

InfrastructureService createInfrastructureCoverage({
  required GeographicContext geographicContext,
  required InfrastructureInputsReader reader,
  required PublicTransportation transportation,
  required InfrastructureWeightsStore weightsStore,
  Database? database,
  DateTime Function()? clock,
}) {
  return InfrastructureService(
    geo: geographicContext,
    reader: reader,
    transportation: transportation,
    weightsStore: weightsStore,
    cache: database == null
        ? null
        : InfrastructureCache(database, clock ?? DateTime.now),
  );
}
