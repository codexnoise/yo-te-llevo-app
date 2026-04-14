import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/lat_lng.dart';
import '../../../../core/utils/polyline_codec.dart';
import '../../domain/entities/pricing_type.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_pricing.dart';
import '../../domain/entities/route_schedule.dart';

class RouteModel extends RouteEntity {
  static const String fDriverId = 'driverId';
  static const String fOriginLat = 'originLat';
  static const String fOriginLng = 'originLng';
  static const String fOriginAddress = 'originAddress';
  static const String fDestinationLat = 'destinationLat';
  static const String fDestinationLng = 'destinationLng';
  static const String fDestinationAddress = 'destinationAddress';
  static const String fPolyline = 'polyline';
  static const String fGeohashOrigin = 'geohashOrigin';
  static const String fGeohashDestination = 'geohashDestination';
  static const String fDistance = 'distance';
  static const String fDuration = 'duration';
  static const String fSchedule = 'schedule';
  static const String fPricing = 'pricing';
  static const String fAvailableSeats = 'availableSeats';
  static const String fIsActive = 'isActive';
  static const String fCreatedAt = 'createdAt';
  static const String fUpdatedAt = 'updatedAt';

  const RouteModel({
    required super.id,
    required super.driverId,
    required super.origin,
    required super.originAddress,
    required super.destination,
    required super.destinationAddress,
    required super.polylineEncoded,
    required super.polylinePoints,
    required super.geohashOrigin,
    required super.geohashDestination,
    required super.distanceMeters,
    required super.durationSeconds,
    required super.schedule,
    required super.pricing,
    required super.availableSeats,
    required super.isActive,
    required super.createdAt,
  });

  factory RouteModel.fromEntity(RouteEntity entity) {
    return RouteModel(
      id: entity.id,
      driverId: entity.driverId,
      origin: entity.origin,
      originAddress: entity.originAddress,
      destination: entity.destination,
      destinationAddress: entity.destinationAddress,
      polylineEncoded: entity.polylineEncoded,
      polylinePoints: entity.polylinePoints,
      geohashOrigin: entity.geohashOrigin,
      geohashDestination: entity.geohashDestination,
      distanceMeters: entity.distanceMeters,
      durationSeconds: entity.durationSeconds,
      schedule: entity.schedule,
      pricing: entity.pricing,
      availableSeats: entity.availableSeats,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  RouteEntity toEntity() {
    return RouteEntity(
      id: id,
      driverId: driverId,
      origin: origin,
      originAddress: originAddress,
      destination: destination,
      destinationAddress: destinationAddress,
      polylineEncoded: polylineEncoded,
      polylinePoints: polylinePoints,
      geohashOrigin: geohashOrigin,
      geohashDestination: geohashDestination,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      schedule: schedule,
      pricing: pricing,
      availableSeats: availableSeats,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  factory RouteModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de ruta vacío: ${doc.id}');
    }
    return RouteModel.fromMap(doc.id, data);
  }

  factory RouteModel.fromMap(String id, Map<String, dynamic> data) {
    final createdAtRaw = data[fCreatedAt];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    final scheduleMap = data[fSchedule] as Map<String, dynamic>? ?? {};
    final pricingMap = data[fPricing] as Map<String, dynamic>? ?? {};

    final polylineEncoded = data[fPolyline] as String? ?? '';

    return RouteModel(
      id: id,
      driverId: data[fDriverId] as String? ?? '',
      origin: LatLng(
        (data[fOriginLat] as num?)?.toDouble() ?? 0,
        (data[fOriginLng] as num?)?.toDouble() ?? 0,
      ),
      originAddress: data[fOriginAddress] as String? ?? '',
      destination: LatLng(
        (data[fDestinationLat] as num?)?.toDouble() ?? 0,
        (data[fDestinationLng] as num?)?.toDouble() ?? 0,
      ),
      destinationAddress: data[fDestinationAddress] as String? ?? '',
      polylineEncoded: polylineEncoded,
      polylinePoints: polylineEncoded.isNotEmpty
          ? PolylineCodec.decode(polylineEncoded)
          : [],
      geohashOrigin: data[fGeohashOrigin] as String? ?? '',
      geohashDestination: data[fGeohashDestination] as String? ?? '',
      distanceMeters: (data[fDistance] as num?)?.toDouble() ?? 0,
      durationSeconds: (data[fDuration] as num?)?.toDouble() ?? 0,
      schedule: RouteSchedule(
        days: (scheduleMap['days'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        departureTime: scheduleMap['departureTime'] as String? ?? '07:00',
        returnTime: scheduleMap['returnTime'] as String?,
      ),
      pricing: RoutePricing(
        type: PricingType.fromString(
            pricingMap['type'] as String? ?? 'perTrip'),
        amount: (pricingMap['amount'] as num?)?.toDouble() ?? 0,
        currency: pricingMap['currency'] as String? ?? 'USD',
      ),
      availableSeats: (data[fAvailableSeats] as num?)?.toInt() ?? 1,
      isActive: data[fIsActive] as bool? ?? true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      fDriverId: driverId,
      fOriginLat: origin.latitude,
      fOriginLng: origin.longitude,
      fOriginAddress: originAddress,
      fDestinationLat: destination.latitude,
      fDestinationLng: destination.longitude,
      fDestinationAddress: destinationAddress,
      fPolyline: polylineEncoded,
      fGeohashOrigin: geohashOrigin,
      fGeohashDestination: geohashDestination,
      fDistance: distanceMeters,
      fDuration: durationSeconds,
      fSchedule: {
        'days': schedule.days,
        'departureTime': schedule.departureTime,
        'returnTime': schedule.returnTime,
      },
      fPricing: {
        'type': pricing.type.name,
        'amount': pricing.amount,
        'currency': pricing.currency,
      },
      fAvailableSeats: availableSeats,
      fIsActive: isActive,
      fCreatedAt: useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      fUpdatedAt: FieldValue.serverTimestamp(),
    };
  }
}
