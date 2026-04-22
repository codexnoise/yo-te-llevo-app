import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/connectivity_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/route_remote_datasource.dart';
import '../../data/repositories/driver_route_repository_impl.dart';
import '../../domain/entities/geocoding_result.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/driver_route_repository.dart';
import 'create_route_notifier.dart';
import 'create_route_state.dart';
import 'driver_routes_notifier.dart';
import 'mapbox_providers.dart';

final routeRemoteDataSourceProvider = Provider<RouteRemoteDataSource>((ref) {
  return RouteRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

final driverRouteRepositoryProvider = Provider<DriverRouteRepository>((ref) {
  return DriverRouteRepositoryImpl(
    remoteDataSource: ref.watch(routeRemoteDataSourceProvider),
    mapboxRepository: ref.watch(mapboxRepositoryProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

final createRouteNotifierProvider =
    StateNotifierProvider.autoDispose<CreateRouteNotifier, CreateRouteState>(
        (ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final driverId = user?.id ?? '';

  return CreateRouteNotifier(
    mapboxRepository: ref.watch(mapboxRepositoryProvider),
    routeRepository: ref.watch(driverRouteRepositoryProvider),
    driverId: driverId,
  );
});

final driverRoutesProvider = StateNotifierProvider.autoDispose<
    DriverRoutesNotifier, AsyncValue<List<RouteEntity>>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final driverId = user?.id ?? '';

  return DriverRoutesNotifier(
    repository: ref.watch(driverRouteRepositoryProvider),
    driverId: driverId,
  );
});

final geocodingSearchProvider = FutureProvider.autoDispose
    .family<List<GeocodingResult>, String>((ref, query) async {
  if (query.trim().length < 3) return [];

  final repository = ref.watch(mapboxRepositoryProvider);
  final result = await repository.search(query);
  return result.fold(
    (_) => <GeocodingResult>[],
    (results) => results,
  );
});
