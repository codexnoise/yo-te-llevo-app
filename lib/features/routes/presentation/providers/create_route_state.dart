import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../domain/entities/pricing_type.dart';
import '../../domain/entities/route_pricing.dart';
import '../../domain/entities/route_result.dart';
import '../../domain/entities/route_schedule.dart';

class CreateRouteState extends Equatable {
  final LatLng? origin;
  final String? originAddress;
  final LatLng? destination;
  final String? destinationAddress;
  final RouteResult? routeResult;
  final RouteSchedule schedule;
  final RoutePricing pricing;
  final int availableSeats;
  final bool isLoadingRoute;
  final bool isSaving;
  final String? errorMessage;
  final bool isRouteCreated;

  const CreateRouteState({
    this.origin,
    this.originAddress,
    this.destination,
    this.destinationAddress,
    this.routeResult,
    this.schedule = const RouteSchedule(
      days: ['mon', 'tue', 'wed', 'thu', 'fri'],
      departureTime: '07:00',
    ),
    this.pricing = const RoutePricing(
      type: PricingType.perTrip,
      amount: 0,
    ),
    this.availableSeats = 3,
    this.isLoadingRoute = false,
    this.isSaving = false,
    this.errorMessage,
    this.isRouteCreated = false,
  });

  CreateRouteState copyWith({
    LatLng? Function()? origin,
    String? Function()? originAddress,
    LatLng? Function()? destination,
    String? Function()? destinationAddress,
    RouteResult? Function()? routeResult,
    RouteSchedule? schedule,
    RoutePricing? pricing,
    int? availableSeats,
    bool? isLoadingRoute,
    bool? isSaving,
    String? Function()? errorMessage,
    bool? isRouteCreated,
  }) {
    return CreateRouteState(
      origin: origin != null ? origin() : this.origin,
      originAddress:
          originAddress != null ? originAddress() : this.originAddress,
      destination:
          destination != null ? destination() : this.destination,
      destinationAddress: destinationAddress != null
          ? destinationAddress()
          : this.destinationAddress,
      routeResult:
          routeResult != null ? routeResult() : this.routeResult,
      schedule: schedule ?? this.schedule,
      pricing: pricing ?? this.pricing,
      availableSeats: availableSeats ?? this.availableSeats,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
      isRouteCreated: isRouteCreated ?? this.isRouteCreated,
    );
  }

  bool get canFetchRoute => origin != null && destination != null;

  bool get hasRoute => routeResult != null;

  @override
  List<Object?> get props => [
        origin,
        originAddress,
        destination,
        destinationAddress,
        routeResult,
        schedule,
        pricing,
        availableSeats,
        isLoadingRoute,
        isSaving,
        errorMessage,
        isRouteCreated,
      ];
}
