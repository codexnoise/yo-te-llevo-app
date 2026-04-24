import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/connectivity_provider.dart';
import '../../../routes/presentation/providers/driver_route_providers.dart';
import '../../../routes/presentation/providers/mapbox_providers.dart';
import '../../data/repositories/matching_repository_impl.dart';
import '../../data/services/matching_engine.dart';
import '../../domain/repositories/matching_repository.dart';
import 'matching_notifier.dart';
import 'matching_state.dart';

final matchingEngineProvider = Provider<MatchingEngine>((ref) {
  return MatchingEngine(
    ref.watch(driverRouteRepositoryProvider),
    ref.watch(mapboxRepositoryProvider),
  );
});

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepositoryImpl(
    engine: ref.watch(matchingEngineProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

final matchingNotifierProvider =
    StateNotifierProvider<MatchingNotifier, MatchingState>((ref) {
  return MatchingNotifier(ref.watch(matchingRepositoryProvider));
});
