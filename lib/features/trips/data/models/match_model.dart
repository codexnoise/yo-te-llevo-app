import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/domain/entities/match_status.dart';

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
  static const String fPricingType = 'type';
  static const String fPricingAmount = 'amount';

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
      startDate: _parseStartDate(schedule[fScheduleStartDate]),
      price: (pricing[fPricingAmount] as num?)?.toDouble() ?? 0,
      pricingType: (pricing[fPricingType] as String?) ?? 'perTrip',
      createdAt: _parseTimestamp(data[fCreatedAt]) ?? DateTime.now(),
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
      fSchedule: {
        fScheduleType: match.tripType.name,
        fScheduleDays: match.days,
        fScheduleStartDate: match.startDate != null
            ? Timestamp.fromDate(match.startDate!)
            : null,
      },
      fPricing: {
        fPricingType: match.pricingType,
        fPricingAmount: match.price,
      },
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
      fSchedule: {
        fScheduleType: match.tripType.name,
        fScheduleDays: match.days,
        fScheduleStartDate: match.startDate != null
            ? Timestamp.fromDate(match.startDate!)
            : null,
      },
      fPricing: {
        fPricingType: match.pricingType,
        fPricingAmount: match.price,
      },
      fCreatedAt: Timestamp.fromDate(match.createdAt),
      fUpdatedAt: Timestamp.fromDate(match.createdAt),
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

  static List<String> _parseDays(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? _parseStartDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    return null;
  }
}
