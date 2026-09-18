import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/geographic_context_models.dart';
import 'src/geographic_context_service_impl.dart';
import 'src/supabase_geo_repository.dart';

export 'src/geographic_context_models.dart';

GeographicContext createGeographicContext(SupabaseClient supabaseClient) {
  final SupabaseGeoRepository repository = SupabaseGeoRepository(
    supabaseClient,
  );
  return GeographicContextServiceImpl(repository);
}
