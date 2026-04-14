import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/driver_route_repository.dart';

class DriverRoutesNotifier
    extends StateNotifier<AsyncValue<List<RouteEntity>>> {
  final DriverRouteRepository _repository;
  final String _driverId;

  DriverRoutesNotifier({
    required DriverRouteRepository repository,
    required String driverId,
  })  : _repository = repository,
        _driverId = driverId,
        super(const AsyncValue.loading()) {
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    state = const AsyncValue.loading();
    final result = await _repository.getDriverRoutes(_driverId);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (routes) => AsyncValue.data(routes),
    );
  }

  Future<void> deactivateRoute(String routeId) async {
    final result = await _repository.deactivateRoute(routeId);
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => _loadRoutes(),
    );
  }

  Future<void> refresh() => _loadRoutes();
}
