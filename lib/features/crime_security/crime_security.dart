import 'package:sqflite/sqflite.dart';
import 'package:locatemy/modules/geographic_context/geographic_context.dart';

import 'src/domain/safety_models.dart';
import 'src/application/safety_inputs_reader.dart';
import 'src/application/crime_security_service.dart';
import 'src/data/sqlite_safety_inputs_cache.dart';

export 'src/domain/safety_models.dart';
export 'src/application/safety_inputs_reader.dart';

export 'src/data/supabase_safety_inputs_reader.dart';
export 'src/presentation/crime_security_page.dart' show CrimeSecurityPage;

CrimeSecurity createCrimeSecurity({
  required GeographicContext geographicContext,
  required SafetyInputsReader reader,
  required Database database,
  DateTime Function()? clock,
}) {
  return CrimeSecurityService(
    geographicContext,
    reader,
    SqliteSafetyInputsCache(database, clock ?? DateTime.now),
    clock ?? DateTime.now,
  );
}
