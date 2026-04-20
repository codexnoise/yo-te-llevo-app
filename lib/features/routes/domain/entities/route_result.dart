import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';

class RouteResult extends Equatable {
  final String polylineEncoded;
  final List<LatLng> polylineDecoded;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.polylineEncoded,
    required this.polylineDecoded,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  @override
  List<Object> get props => [
        polylineEncoded,
        distanceMeters,
        durationSeconds,
      ];
}
