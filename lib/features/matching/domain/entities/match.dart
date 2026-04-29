import 'package:equatable/equatable.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../../trips/domain/entities/match_series_status.dart';
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

  /// Estado del template de la serie. Sólo aplica a `tripType=recurring`.
  /// Para `oneTime` es null y se usa [status] como fuente de verdad.
  final MatchSeriesStatus? seriesStatus;

  /// Próxima ocurrencia pendiente. Lo mantiene la CF `onMatchAccepted` /
  /// `onOccurrenceStatusChanged`. Útil para query del scheduler y para
  /// mostrarlo en home sin leer la colección de ocurrencias.
  final DateTime? nextOccurrenceAt;

  /// Última ocurrencia completada o cancelada — usada por la lógica de
  /// pricing (cobrar 1× por ciclo) y por la métrica de salud de serie.
  final DateTime? lastOccurrenceAt;

  /// Fecha límite de la recurrencia. Null = indefinida.
  final DateTime? endDate;

  /// Hora de salida `HH:mm`. Denormalizado desde `RouteEntity.schedule.departureTime`.
  final String? departureTime;

  /// IANA timezone (default `America/Guayaquil` para Cuenca).
  final String timezone;

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
    this.seriesStatus,
    this.nextOccurrenceAt,
    this.lastOccurrenceAt,
    this.endDate,
    this.departureTime,
    this.timezone = 'America/Guayaquil',
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
        seriesStatus,
        nextOccurrenceAt,
        lastOccurrenceAt,
        endDate,
        departureTime,
        timezone,
      ];
}
