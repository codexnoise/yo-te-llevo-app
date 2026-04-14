import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import 'route_pricing.dart';
import 'route_schedule.dart';

class RouteEntity extends Equatable {
  final String id;
  final String driverId;
  final LatLng origin;
  final String originAddress;
  final LatLng destination;
  final String destinationAddress;
  final String polylineEncoded;
  final List<LatLng> polylinePoints;
  final String geohashOrigin;
  final String geohashDestination;
  final double distanceMeters;
  final double durationSeconds;
  final RouteSchedule schedule;
  final RoutePricing pricing;
  final int availableSeats;
  final bool isActive;
  final DateTime createdAt;

  const RouteEntity({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.originAddress,
    required this.destination,
    required this.destinationAddress,
    required this.polylineEncoded,
    required this.polylinePoints,
    required this.geohashOrigin,
    required this.geohashDestination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.schedule,
    required this.pricing,
    required this.availableSeats,
    required this.isActive,
    required this.createdAt,
  });

  RouteEntity copyWith({
    String? id,
    String? driverId,
    LatLng? origin,
    String? originAddress,
    LatLng? destination,
    String? destinationAddress,
    String? polylineEncoded,
    List<LatLng>? polylinePoints,
    String? geohashOrigin,
    String? geohashDestination,
    double? distanceMeters,
    double? durationSeconds,
    RouteSchedule? schedule,
    RoutePricing? pricing,
    int? availableSeats,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      origin: origin ?? this.origin,
      originAddress: originAddress ?? this.originAddress,
      destination: destination ?? this.destination,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      polylineEncoded: polylineEncoded ?? this.polylineEncoded,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      geohashOrigin: geohashOrigin ?? this.geohashOrigin,
      geohashDestination: geohashDestination ?? this.geohashDestination,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      schedule: schedule ?? this.schedule,
      pricing: pricing ?? this.pricing,
      availableSeats: availableSeats ?? this.availableSeats,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [
        id,
        driverId,
        origin,
        originAddress,
        destination,
        destinationAddress,
        polylineEncoded,
        polylinePoints,
        geohashOrigin,
        geohashDestination,
        distanceMeters,
        durationSeconds,
        schedule,
        pricing,
        availableSeats,
        isActive,
        createdAt,
      ];
}
