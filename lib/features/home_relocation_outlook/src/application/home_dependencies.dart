import '../domain/home_models.dart';
import '../domain/home_trends.dart';

abstract interface class HomeReader {
  Future<Map<String, dynamic>> read();
}

abstract interface class PublicHomeCache {
  Future<HomeOutlookSnapshot?> read();
  Future<void> write(HomeOutlookSnapshot snapshot);
}

final class HomeReadFailure implements Exception {
  final HomeUnavailableReason reason;
  const HomeReadFailure(this.reason);
}


abstract interface class HomeTrendReader {
  HomeTrendHistory get trendHistory;
}
