import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import 'match_status.dart';

enum MatchTripType { oneTime, recurring }

class Match extends Equatable {
  final String id;
  final String passengerId;
  final String driverId;
  final String routeId;
  final MatchStatus status;
  final LatLng pickupPoint;
  final String pickupAddress;
  final LatLng dropoffPoint;
  final String dropoffAddress;
  final double distanceToPickupMeters;
  final double distanceToDropoffMeters;
  final double detourSeconds;
  final MatchTripType tripType;
  final List<String> days;
  final DateTime? startDate;
  final double price;
  final String pricingType;
  final DateTime createdAt;

  const Match({
    required this.id,
    required this.passengerId,
    required this.driverId,
    required this.routeId,
    required this.status,
    required this.pickupPoint,
    required this.pickupAddress,
    required this.dropoffPoint,
    required this.dropoffAddress,
    required this.distanceToPickupMeters,
    required this.distanceToDropoffMeters,
    required this.detourSeconds,
    required this.tripType,
    required this.days,
    required this.startDate,
    required this.price,
    required this.pricingType,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        passengerId,
        driverId,
        routeId,
        status,
        pickupPoint,
        pickupAddress,
        dropoffPoint,
        dropoffAddress,
        distanceToPickupMeters,
        distanceToDropoffMeters,
        detourSeconds,
        tripType,
        days,
        startDate,
        price,
        pricingType,
        createdAt,
      ];
}
