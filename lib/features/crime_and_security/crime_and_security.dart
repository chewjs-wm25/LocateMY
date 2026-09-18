import 'package:locatemy/modules/geographic_context/geographic_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

import 'src/domain/safety_models.dart';
import 'src/application/safety_service.dart';
import 'src/data/crime_repository.dart';

export 'src/domain/safety_models.dart';
export 'src/presentation/crime_security_page.dart';


CrimeAndSecurity createCrimeAndSecurity({
  required SupabaseClient supabaseClient,
  required Database database,
  required GeographicContext geographicContext,
}) {
  final repository = CrimeRepository(
    supabaseClient: supabaseClient,
    database: database,
  );
  return SafetyService(
    repository: repository,
    geographicContext: geographicContext,
  );
}
