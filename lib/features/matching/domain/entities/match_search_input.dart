import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';

class MatchSearchInput extends Equatable {
  final LatLng origin;
  final LatLng destination;
  final List<String> days;
  final String? departureTime;

  const MatchSearchInput({
    required this.origin,
    required this.destination,
    required this.days,
    this.departureTime,
  });

  @override
  List<Object?> get props => [origin, destination, days, departureTime];
}
