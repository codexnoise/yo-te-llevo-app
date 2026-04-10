import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../../../core/utils/polyline_codec.dart';

class RouteResultModel extends Equatable {
  final String polylineEncoded;
  final List<LatLng> polylineDecoded;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResultModel({
    required this.polylineEncoded,
    required this.polylineDecoded,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteResultModel.fromDirectionsResponse(Map<String, dynamic> json) {
    final route = (json['routes'] as List).first as Map<String, dynamic>;
    final geometry = route['geometry'] as String;
    final distance = (route['distance'] as num).toDouble();
    final duration = (route['duration'] as num).toDouble();

    return RouteResultModel(
      polylineEncoded: geometry,
      polylineDecoded: PolylineCodec.decode(geometry),
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  @override
  List<Object> get props => [
        polylineEncoded,
        distanceMeters,
        durationSeconds,
      ];
}
