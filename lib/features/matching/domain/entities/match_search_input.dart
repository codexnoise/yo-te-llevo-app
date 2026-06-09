import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import 'match.dart';

class MatchSearchInput extends Equatable {
  final LatLng origin;
  final LatLng destination;
  final List<String> days;
  final String? departureTime;

  /// Tipo de match deseado por el pasajero. `oneTime` es un único trayecto;
  /// `recurring` es una suscripción semanal acotada por [endDate].
  final MatchTripType tripType;

  /// Fecha absoluta de fin de la serie. Sólo se usa si
  /// `tripType == recurring`. Null = serie indefinida.
  final DateTime? endDate;

  const MatchSearchInput({
    required this.origin,
    required this.destination,
    required this.days,
    this.departureTime,
    this.tripType = MatchTripType.oneTime,
    this.endDate,
  });

  @override
  List<Object?> get props =>
      [origin, destination, days, departureTime, tripType, endDate];
}
