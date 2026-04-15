import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../../routes/domain/entities/pricing_type.dart';
import '../../../routes/domain/entities/route_entity.dart';

class MatchCandidate extends Equatable {
  final RouteEntity route;
  final LatLng pickupPoint;
  final String pickupAddress;
  final LatLng dropoffPoint;
  final String dropoffAddress;
  final double distanceToPickupMeters;
  final double distanceToDropoffMeters;
  final double detourSeconds;
  final double detourMeters;
  final List<LatLng> fullRouteWithDetour;
  final double price;
  final PricingType pricingType;

  const MatchCandidate({
    required this.route,
    required this.pickupPoint,
    required this.pickupAddress,
    required this.dropoffPoint,
    required this.dropoffAddress,
    required this.distanceToPickupMeters,
    required this.distanceToDropoffMeters,
    required this.detourSeconds,
    required this.detourMeters,
    required this.fullRouteWithDetour,
    required this.price,
    required this.pricingType,
  });

  String get walkingToPickupLabel => _formatWalkingDistance(distanceToPickupMeters);

  String get walkingToDropoffLabel => _formatWalkingDistance(distanceToDropoffMeters);

  String get detourLabel {
    final minutes = (detourSeconds / 60).round();
    return '+$minutes min desvío';
  }

  String get priceLabel => '\$${price.toStringAsFixed(2)} ${pricingType.suffix}';

  static String _formatWalkingDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m caminando';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km caminando';
  }

  @override
  List<Object> get props => [
        route,
        pickupPoint,
        pickupAddress,
        dropoffPoint,
        dropoffAddress,
        distanceToPickupMeters,
        distanceToDropoffMeters,
        detourSeconds,
        detourMeters,
        fullRouteWithDetour,
        price,
        pricingType,
      ];
}
