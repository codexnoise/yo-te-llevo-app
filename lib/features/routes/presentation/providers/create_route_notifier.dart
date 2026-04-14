import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/geohash_utils.dart';
import '../../data/models/geocoding_result_model.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_pricing.dart';
import '../../domain/entities/route_schedule.dart';
import '../../domain/repositories/driver_route_repository.dart';
import '../../domain/repositories/mapbox_repository.dart';
import '../../../../core/utils/lat_lng.dart';
import 'create_route_state.dart';

class CreateRouteNotifier extends StateNotifier<CreateRouteState> {
  final MapboxRepository _mapboxRepository;
  final DriverRouteRepository _routeRepository;
  final String _driverId;

  CreateRouteNotifier({
    required MapboxRepository mapboxRepository,
    required DriverRouteRepository routeRepository,
    required String driverId,
  })  : _mapboxRepository = mapboxRepository,
        _routeRepository = routeRepository,
        _driverId = driverId,
        super(const CreateRouteState());

  void setOrigin(LatLng point) {
    state = state.copyWith(
      origin: () => point,
      originAddress: () => null,
      routeResult: () => null,
      errorMessage: () => null,
    );
    _reverseGeocode(point, isOrigin: true);
    if (state.canFetchRoute) _fetchRoute();
  }

  void setOriginFromSearch(GeocodingResultModel result) {
    state = state.copyWith(
      origin: () => result.coordinates,
      originAddress: () => result.fullAddress,
      routeResult: () => null,
      errorMessage: () => null,
    );
    if (state.canFetchRoute) _fetchRoute();
  }

  void setDestination(LatLng point) {
    state = state.copyWith(
      destination: () => point,
      destinationAddress: () => null,
      routeResult: () => null,
      errorMessage: () => null,
    );
    _reverseGeocode(point, isOrigin: false);
    if (state.canFetchRoute) _fetchRoute();
  }

  void setDestinationFromSearch(GeocodingResultModel result) {
    state = state.copyWith(
      destination: () => result.coordinates,
      destinationAddress: () => result.fullAddress,
      routeResult: () => null,
      errorMessage: () => null,
    );
    if (state.canFetchRoute) _fetchRoute();
  }

  void updateSchedule(RouteSchedule schedule) {
    state = state.copyWith(schedule: schedule);
  }

  void updatePricing(RoutePricing pricing) {
    state = state.copyWith(pricing: pricing);
  }

  void updateAvailableSeats(int seats) {
    state = state.copyWith(availableSeats: seats);
  }

  Future<void> _fetchRoute() async {
    if (state.origin == null || state.destination == null) return;

    state = state.copyWith(isLoadingRoute: true, errorMessage: () => null);

    final result = await _mapboxRepository.getRoute([
      state.origin!,
      state.destination!,
    ]);

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingRoute: false,
        errorMessage: () => failure.message,
      ),
      (routeResult) => state = state.copyWith(
        isLoadingRoute: false,
        routeResult: () => routeResult,
      ),
    );
  }

  Future<void> _reverseGeocode(LatLng point, {required bool isOrigin}) async {
    final result = await _mapboxRepository.reverseGeocode(point);
    result.fold(
      (_) {},
      (address) {
        if (isOrigin) {
          state = state.copyWith(originAddress: () => address);
        } else {
          state = state.copyWith(destinationAddress: () => address);
        }
      },
    );
  }

  Future<void> saveRoute() async {
    // Validaciones
    if (state.origin == null || state.destination == null) {
      state = state.copyWith(
          errorMessage: () => 'Selecciona origen y destino');
      return;
    }
    if (state.routeResult == null) {
      state = state.copyWith(
          errorMessage: () => 'Espera a que se calcule la ruta');
      return;
    }
    if (state.schedule.days.isEmpty) {
      state = state.copyWith(
          errorMessage: () => 'Selecciona al menos un día');
      return;
    }
    if (state.pricing.amount <= 0) {
      state = state.copyWith(
          errorMessage: () => 'Ingresa un precio válido');
      return;
    }
    if (state.availableSeats <= 0) {
      state = state.copyWith(
          errorMessage: () => 'Ingresa asientos disponibles');
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    final geohashOrigin = GeohashUtils.encode(state.origin!);
    final geohashDestination = GeohashUtils.encode(state.destination!);

    final route = RouteEntity(
      id: '',
      driverId: _driverId,
      origin: state.origin!,
      originAddress: state.originAddress ?? '',
      destination: state.destination!,
      destinationAddress: state.destinationAddress ?? '',
      polylineEncoded: state.routeResult!.polylineEncoded,
      polylinePoints: state.routeResult!.polylineDecoded,
      geohashOrigin: geohashOrigin,
      geohashDestination: geohashDestination,
      distanceMeters: state.routeResult!.distanceMeters,
      durationSeconds: state.routeResult!.durationSeconds,
      schedule: state.schedule,
      pricing: state.pricing,
      availableSeats: state.availableSeats,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final result = await _routeRepository.createRoute(route);

    result.fold(
      (failure) => state = state.copyWith(
        isSaving: false,
        errorMessage: () => failure.message,
      ),
      (_) => state = state.copyWith(
        isSaving: false,
        isRouteCreated: true,
      ),
    );
  }

  void reset() {
    state = const CreateRouteState();
  }
}
