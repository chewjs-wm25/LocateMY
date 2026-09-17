export 'src/presentation/home_outlook_page.dart' show HomeOutlookPage;
export 'src/domain/home_models.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

import 'src/application/home_dependencies.dart';
import 'src/domain/home_models.dart';
import 'src/application/home_service.dart';
import 'src/data/supabase_home_reader.dart';
import 'src/data/sqlite_home_cache.dart';

HomeRelocationOutlook createHomeRelocationOutlook(
  SupabaseClient client, {
  Future<Database> Function()? openCache,
  DateTime Function()? clock,
}) {
  final Future<Database> Function() cacheOpener =
      openCache ?? _openDefaultCache;
  final HomeReader reader = SupabaseHomeReader(client);
  final PublicHomeCache cache = SqliteHomeCache(cacheOpener, clock: clock);
  return HomeService(reader, cache, clock: clock);
}

Future<Database> _openDefaultCache() async {
  final String databaseDirectory = await getDatabasesPath();
  return openDatabase('$databaseDirectory/locatemy-public.db');
}
