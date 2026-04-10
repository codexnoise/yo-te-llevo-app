import 'package:equatable/equatable.dart';

import 'route_result_model.dart';

class DetourResultModel extends Equatable {
  final double extraSeconds;
  final double extraMeters;
  final double totalDurationSeconds;
  final double totalDistanceMeters;
  final RouteResultModel fullRoute;

  const DetourResultModel({
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
