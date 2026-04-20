import 'package:equatable/equatable.dart';

import 'route_result.dart';

class DetourResult extends Equatable {
  final double extraSeconds;
  final double extraMeters;
  final double totalDurationSeconds;
  final double totalDistanceMeters;
  final RouteResult fullRoute;

  const DetourResult({
    required this.extraSeconds,
    required this.extraMeters,
    required this.totalDurationSeconds,
    required this.totalDistanceMeters,
    required this.fullRoute,
  });

  @override
  List<Object> get props => [
        extraSeconds,
        extraMeters,
        totalDurationSeconds,
        totalDistanceMeters,
        fullRoute,
      ];
}
