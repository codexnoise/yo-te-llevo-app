import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../matching/domain/entities/match.dart';
import '../../domain/entities/occurrence_status.dart';
import '../../domain/entities/trip_occurrence.dart';

/// Serialización Firestore para `TripOccurrence` en `/trip_occurrences/{id}`.
///
/// Doc ID determinístico: `<matchId>_<yyyyMMddHHmm>` en UTC. Permite que
/// las Cloud Functions sean idempotentes — re-ejecutar el trigger no crea
/// duplicados, sólo hace merge.
class TripOccurrenceModel {
  static const String fMatchId = 'matchId';
  static const String fPassengerId = 'passengerId';
  static const String fDriverId = 'driverId';
  static const String fRouteId = 'routeId';
  static const String fScheduledAt = 'scheduledAt';
  static const String fStatus = 'status';
  static const String fTripType = 'tripType';
  static const String fCreatedAt = 'createdAt';
  static const String fUpdatedAt = 'updatedAt';
  static const String fStartedAt = 'startedAt';
  static const String fCompletedAt = 'completedAt';
  static const String fCancelledAt = 'cancelledAt';
  static const String fCancelledBy = 'cancelledBy';
  static const String fCancellationReason = 'cancellationReason';
  static const String fCancelScope = 'cancelScope';
  static const String fPriceCents = 'priceCents';
  static const String fRemindersSent = 'remindersSent';
  static const String fTimezone = 'timezone';

  static const String fReminderH12 = 'h12';
  static const String fReminderH1 = 'h1';
  static const String fReminderStart15m = 'start15m';

  const TripOccurrenceModel();

  /// Genera el doc ID determinístico para una ocurrencia.
  static String docIdFor({
    required String matchId,
    required DateTime scheduledAt,
  }) {
    final utc = scheduledAt.toUtc();
    final stamp =
        '${utc.year.toString().padLeft(4, '0')}${utc.month.toString().padLeft(2, '0')}${utc.day.toString().padLeft(2, '0')}'
        '${utc.hour.toString().padLeft(2, '0')}${utc.minute.toString().padLeft(2, '0')}';
    return '${matchId}_$stamp';
  }

  static TripOccurrence fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de occurrence vacío: ${doc.id}');
    }
    return fromMap(doc.id, data);
  }

  static TripOccurrence fromMap(String id, Map<String, dynamic> data) {
    final remindersRaw =
        (data[fRemindersSent] as Map<String, dynamic>?) ?? const {};
    return TripOccurrence(
      id: id,
      matchId: data[fMatchId] as String? ?? '',
      passengerId: data[fPassengerId] as String? ?? '',
      driverId: data[fDriverId] as String? ?? '',
      routeId: data[fRouteId] as String? ?? '',
      scheduledAt: _parseTimestamp(data[fScheduledAt]) ?? DateTime.now(),
      status:
          OccurrenceStatus.fromString(data[fStatus] as String? ?? 'scheduled'),
      tripType: _parseTripType(data[fTripType] as String?),
      createdAt: _parseTimestamp(data[fCreatedAt]) ?? DateTime.now(),
      startedAt: _parseTimestamp(data[fStartedAt]),
      completedAt: _parseTimestamp(data[fCompletedAt]),
      cancelledAt: _parseTimestamp(data[fCancelledAt]),
      cancelledBy: data[fCancelledBy] as String?,
      cancellationReason: data[fCancellationReason] as String?,
      priceCents: (data[fPriceCents] as num?)?.toInt() ?? 0,
      remindersSent: OccurrenceReminders(
        h12: remindersRaw[fReminderH12] as bool? ?? false,
        h1: remindersRaw[fReminderH1] as bool? ?? false,
        start15m: remindersRaw[fReminderStart15m] as bool? ?? false,
      ),
      timezone: (data[fTimezone] as String?) ?? 'America/Guayaquil',
    );
  }

  static Map<String, dynamic> toCreateMap(TripOccurrence o) {
    return {
      fMatchId: o.matchId,
      fPassengerId: o.passengerId,
      fDriverId: o.driverId,
      fRouteId: o.routeId,
      fScheduledAt: Timestamp.fromDate(o.scheduledAt.toUtc()),
      fStatus: o.status.name,
      fTripType: o.tripType.name,
      fPriceCents: o.priceCents,
      fRemindersSent: _remindersMap(o.remindersSent),
      fTimezone: o.timezone,
      fCreatedAt: FieldValue.serverTimestamp(),
      fUpdatedAt: FieldValue.serverTimestamp(),
    };
  }

  /// Para tests / fakes — sin server timestamps.
  static Map<String, dynamic> toMap(TripOccurrence o) {
    return {
      fMatchId: o.matchId,
      fPassengerId: o.passengerId,
      fDriverId: o.driverId,
      fRouteId: o.routeId,
      fScheduledAt: Timestamp.fromDate(o.scheduledAt.toUtc()),
      fStatus: o.status.name,
      fTripType: o.tripType.name,
      fPriceCents: o.priceCents,
      fRemindersSent: _remindersMap(o.remindersSent),
      fTimezone: o.timezone,
      fCreatedAt: Timestamp.fromDate(o.createdAt),
      fUpdatedAt: Timestamp.fromDate(o.createdAt),
      if (o.startedAt != null) fStartedAt: Timestamp.fromDate(o.startedAt!),
      if (o.completedAt != null)
        fCompletedAt: Timestamp.fromDate(o.completedAt!),
      if (o.cancelledAt != null)
        fCancelledAt: Timestamp.fromDate(o.cancelledAt!),
      if (o.cancelledBy != null) fCancelledBy: o.cancelledBy,
      if (o.cancellationReason != null)
        fCancellationReason: o.cancellationReason,
    };
  }

  static Map<String, bool> _remindersMap(OccurrenceReminders r) => {
        fReminderH12: r.h12,
        fReminderH1: r.h1,
        fReminderStart15m: r.start15m,
      };

  static MatchTripType _parseTripType(String? raw) {
    switch (raw) {
      case 'recurring':
        return MatchTripType.recurring;
      case 'oneTime':
      default:
        return MatchTripType.oneTime;
    }
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
