import 'dart:async';
import 'package:locatemy/features/map_location/map_location.dart';
import '../domain/infrastructure_models.dart';

/// Minimal service placeholder for the Infrastructure Coverage feature.
/// Provides the same async contract as a real adapter; returns unavailable by default.
final class InfrastructureService {
  const InfrastructureService();

  Future<InfrastructureLoadOutcome> fetch(
    ValidLocationReference location,
    DateTime analysisDate, {
    InfrastructureLoadPolicy policy = InfrastructureLoadPolicy.cacheAllowed,
  }) async {
    // Simulate a network/read delay and return unavailable placeholder.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return InfrastructureUnavailable('Data not yet implemented');
  }
}
