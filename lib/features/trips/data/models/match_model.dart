import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../../domain/entities/match_series_status.dart';

/// Serialización Firestore para un [Match] en `/matches/{matchId}`.
///
/// La spec §6.2 pide que `schedule` y `pricing` se almacenen como mapas
/// anidados; el resto de campos son planos.
class MatchModel {
  static const String fPassengerId = 'passengerId';
  static const String fDriverId = 'driverId';
  static const String fRouteId = 'routeId';
  static const String fStatus = 'status';
  static const String fPickupLat = 'pickupLat';
  static const String fPickupLng = 'pickupLng';
  static const String fPickupAddress = 'pickupAddress';
  static const String fDropoffLat = 'dropoffLat';
  static const String fDropoffLng = 'dropoffLng';
  static const String fDropoffAddress = 'dropoffAddress';
  static const String fDistanceToPickup = 'distanceToPickup';
  static const String fDistanceToDropoff = 'distanceToDropoff';
  static const String fDetourDuration = 'detourDuration';
  static const String fSchedule = 'schedule';
  static const String fPricing = 'pricing';
  static const String fCreatedAt = 'createdAt';
  static const String fUpdatedAt = 'updatedAt';

  static const String fScheduleType = 'type';
  static const String fScheduleDays = 'days';
  static const String fScheduleStartDate = 'startDate';
  static const String fScheduleDepartureTime = 'departureTime';
  static const String fScheduleEndDate = 'endDate';
  static const String fScheduleTimezone = 'timezone';
  static const String fPricingType = 'type';
  static const String fPricingAmount = 'amount';

  // Campos de recurrencia v1 — viven al nivel raíz del doc para no anidar
  // demasiado y facilitar índices Firestore.
  static const String fSeriesStatus = 'seriesStatus';
  static const String fNextOccurrenceAt = 'nextOccurrenceAt';
  static const String fLastOccurrenceAt = 'lastOccurrenceAt';

  const MatchModel();

  /// Construye un [Match] a partir de un snapshot. [id] toma el
  /// documentId.
  static Match fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de match vacío: ${doc.id}');
    }
    return fromMap(doc.id, data);
  }

  static Match fromMap(String id, Map<String, dynamic> data) {
    final schedule = (data[fSchedule] as Map<String, dynamic>?) ?? const {};
    final pricing = (data[fPricing] as Map<String, dynamic>?) ?? const {};

    return Match(
      id: id,
      passengerId: data[fPassengerId] as String? ?? '',
      driverId: data[fDriverId] as String? ?? '',
      routeId: data[fRouteId] as String? ?? '',
      status: MatchStatus.fromString(data[fStatus] as String? ?? 'pending'),
      pickupPoint: LatLng(
        (data[fPickupLat] as num?)?.toDouble() ?? 0,
        (data[fPickupLng] as num?)?.toDouble() ?? 0,
      ),
      pickupAddress: data[fPickupAddress] as String? ?? '',
      dropoffPoint: LatLng(
        (data[fDropoffLat] as num?)?.toDouble() ?? 0,
        (data[fDropoffLng] as num?)?.toDouble() ?? 0,
      ),
      dropoffAddress: data[fDropoffAddress] as String? ?? '',
      distanceToPickupMeters:
          (data[fDistanceToPickup] as num?)?.toDouble() ?? 0,
      distanceToDropoffMeters:
          (data[fDistanceToDropoff] as num?)?.toDouble() ?? 0,
      detourSeconds: (data[fDetourDuration] as num?)?.toDouble() ?? 0,
      tripType: _parseTripType(schedule[fScheduleType] as String?),
      days: _parseDays(schedule[fScheduleDays]),
      startDate: _parseTimestamp(schedule[fScheduleStartDate]),
      endDate: _parseTimestamp(schedule[fScheduleEndDate]),
      departureTime: schedule[fScheduleDepartureTime] as String?,
      timezone: (schedule[fScheduleTimezone] as String?) ?? 'America/Guayaquil',
      price: (pricing[fPricingAmount] as num?)?.toDouble() ?? 0,
      pricingType: (pricing[fPricingType] as String?) ?? 'perTrip',
      createdAt: _parseTimestamp(data[fCreatedAt]) ?? DateTime.now(),
      seriesStatus: _parseSeriesStatus(data[fSeriesStatus] as String?),
      nextOccurrenceAt: _parseTimestamp(data[fNextOccurrenceAt]),
      lastOccurrenceAt: _parseTimestamp(data[fLastOccurrenceAt]),
    );
  }

  /// Serialización para `set` / `add`. Usa `FieldValue.serverTimestamp` para
  /// createdAt/updatedAt cuando es una creación.
  static Map<String, dynamic> toCreateMap(Match match) {
    return {
      fPassengerId: match.passengerId,
      fDriverId: match.driverId,
      fRouteId: match.routeId,
      fStatus: match.status.name,
      fPickupLat: match.pickupPoint.latitude,
      fPickupLng: match.pickupPoint.longitude,
      fPickupAddress: match.pickupAddress,
      fDropoffLat: match.dropoffPoint.latitude,
      fDropoffLng: match.dropoffPoint.longitude,
      fDropoffAddress: match.dropoffAddress,
      fDistanceToPickup: match.distanceToPickupMeters,
      fDistanceToDropoff: match.distanceToDropoffMeters,
      fDetourDuration: match.detourSeconds,
      fSchedule: _scheduleMap(match),
      fPricing: {
        fPricingType: match.pricingType,
        fPricingAmount: match.price,
      },
      if (match.seriesStatus != null) fSeriesStatus: match.seriesStatus!.name,
      if (match.nextOccurrenceAt != null)
        fNextOccurrenceAt: Timestamp.fromDate(match.nextOccurrenceAt!),
      if (match.lastOccurrenceAt != null)
        fLastOccurrenceAt: Timestamp.fromDate(match.lastOccurrenceAt!),
      fCreatedAt: FieldValue.serverTimestamp(),
      fUpdatedAt: FieldValue.serverTimestamp(),
    };
  }

  /// Serialización completa (p. ej. para tests de round-trip). No usa
  /// server timestamps.
  static Map<String, dynamic> toMap(Match match) {
    return {
      fPassengerId: match.passengerId,
      fDriverId: match.driverId,
      fRouteId: match.routeId,
      fStatus: match.status.name,
      fPickupLat: match.pickupPoint.latitude,
      fPickupLng: match.pickupPoint.longitude,
      fPickupAddress: match.pickupAddress,
      fDropoffLat: match.dropoffPoint.latitude,
      fDropoffLng: match.dropoffPoint.longitude,
      fDropoffAddress: match.dropoffAddress,
      fDistanceToPickup: match.distanceToPickupMeters,
      fDistanceToDropoff: match.distanceToDropoffMeters,
      fDetourDuration: match.detourSeconds,
      fSchedule: _scheduleMap(match),
      fPricing: {
        fPricingType: match.pricingType,
        fPricingAmount: match.price,
      },
      if (match.seriesStatus != null) fSeriesStatus: match.seriesStatus!.name,
      if (match.nextOccurrenceAt != null)
        fNextOccurrenceAt: Timestamp.fromDate(match.nextOccurrenceAt!),
      if (match.lastOccurrenceAt != null)
        fLastOccurrenceAt: Timestamp.fromDate(match.lastOccurrenceAt!),
      fCreatedAt: Timestamp.fromDate(match.createdAt),
      fUpdatedAt: Timestamp.fromDate(match.createdAt),
    };
  }

  static Map<String, dynamic> _scheduleMap(Match match) {
    return {
      fScheduleType: match.tripType.name,
      fScheduleDays: match.days,
      fScheduleStartDate: match.startDate != null
          ? Timestamp.fromDate(match.startDate!)
          : null,
      if (match.endDate != null)
        fScheduleEndDate: Timestamp.fromDate(match.endDate!),
      if (match.departureTime != null)
        fScheduleDepartureTime: match.departureTime,
      fScheduleTimezone: match.timezone,
    };
  }

  static MatchTripType _parseTripType(String? raw) {
    switch (raw) {
      case 'recurring':
        return MatchTripType.recurring;
      case 'oneTime':
      default:
        return MatchTripType.oneTime;
    }
  }

  static MatchSeriesStatus? _parseSeriesStatus(String? raw) {
    if (raw == null) return null;
    return MatchSeriesStatus.fromString(raw);
  }

  static List<String> _parseDays(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
