import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/cancel_scope.dart';
import '../../domain/entities/match_series_status.dart';
import '../../domain/entities/occurrence_status.dart';
import '../../domain/entities/trip_occurrence.dart';
import '../models/match_model.dart';
import '../models/trip_occurrence_model.dart';

abstract class TripOccurrenceRemoteDataSource {
  /// Crea una ocurrencia con doc ID determinístico — usa `set` con `merge`
  /// para idempotencia.
  Future<TripOccurrence> createOccurrence(TripOccurrence occurrence);

  /// Actualiza el status de una ocurrencia con timestamps adecuados.
  Future<void> updateStatus(
    String occurrenceId, {
    required OccurrenceStatus next,
    String? cancelledBy,
    String? cancellationReason,
    CancelScope? cancelScope,
  });

  Future<TripOccurrence> getOccurrence(String occurrenceId);

  Stream<TripOccurrence> watchOccurrence(String occurrenceId);

  /// Stream combinado de ocurrencias del usuario (en cualquiera de los dos
  /// roles) ordenadas por `scheduledAt` ascendente, filtrando
  /// `scheduledAt >= now` y limitando.
  Stream<List<TripOccurrence>> watchUpcoming(
    String userId, {
    int limit = 10,
  });

  Stream<List<TripOccurrence>> watchBySeries(String matchId);

  /// Lista las futuras `scheduled` de una serie. Usado para batch-cancelar
  /// cuando el usuario decide `CancelScope.series`.
  Future<List<TripOccurrence>> getFutureScheduledOf(String matchId);

  /// Cancela en batch todas las futuras `scheduled` de la serie + actualiza
  /// el `Match.seriesStatus` a `cancelled` en una transacción.
  Future<void> cancelSeriesBatch(
    String matchId, {
    required String byUserId,
    String? reason,
  });

  /// Cambia el `seriesStatus` del template en `/matches/{matchId}`.
  Future<void> updateSeriesStatus(String matchId, MatchSeriesStatus next);
}

class TripOccurrenceFirestoreDataSource
    implements TripOccurrenceRemoteDataSource {
  final FirebaseFirestore _firestore;

  TripOccurrenceFirestoreDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _occurrences =>
      _firestore.collection(FirebaseConstants.tripOccurrencesCollection);

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection(FirebaseConstants.matchesCollection);

  @override
  Future<TripOccurrence> createOccurrence(TripOccurrence occurrence) async {
    try {
      final docId = TripOccurrenceModel.docIdFor(
        matchId: occurrence.matchId,
        scheduledAt: occurrence.scheduledAt,
      );
      final ref = _occurrences.doc(docId);
      await ref.set(
        TripOccurrenceModel.toCreateMap(occurrence.copyWith()),
        SetOptions(merge: true),
      );
      final snap = await ref.get();
      return TripOccurrenceModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> updateStatus(
    String occurrenceId, {
    required OccurrenceStatus next,
    String? cancelledBy,
    String? cancellationReason,
    CancelScope? cancelScope,
  }) async {
    try {
      final updates = <String, dynamic>{
        TripOccurrenceModel.fStatus: next.name,
        TripOccurrenceModel.fUpdatedAt: FieldValue.serverTimestamp(),
      };
      switch (next) {
        case OccurrenceStatus.active:
          updates[TripOccurrenceModel.fStartedAt] =
              FieldValue.serverTimestamp();
        case OccurrenceStatus.completed:
          updates[TripOccurrenceModel.fCompletedAt] =
              FieldValue.serverTimestamp();
        case OccurrenceStatus.cancelled:
          updates[TripOccurrenceModel.fCancelledAt] =
              FieldValue.serverTimestamp();
          if (cancelledBy != null) {
            updates[TripOccurrenceModel.fCancelledBy] = cancelledBy;
          }
          if (cancellationReason != null) {
            updates[TripOccurrenceModel.fCancellationReason] =
                cancellationReason;
          }
          if (cancelScope != null) {
            updates[TripOccurrenceModel.fCancelScope] = cancelScope.wireValue;
          }
        case OccurrenceStatus.scheduled:
        case OccurrenceStatus.noShow:
          break;
      }
      await _occurrences.doc(occurrenceId).update(updates);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<TripOccurrence> getOccurrence(String occurrenceId) async {
    try {
      final snap = await _occurrences.doc(occurrenceId).get();
      if (!snap.exists) {
        throw const ServerException(message: 'Ocurrencia no encontrada');
      }
      return TripOccurrenceModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Stream<TripOccurrence> watchOccurrence(String occurrenceId) {
    return _occurrences.doc(occurrenceId).snapshots().map((snap) {
      if (!snap.exists) {
        throw const ServerException(message: 'Ocurrencia no encontrada');
      }
      return TripOccurrenceModel.fromFirestore(snap);
    });
  }

  @override
  Stream<List<TripOccurrence>> watchUpcoming(
    String userId, {
    int limit = 10,
  }) {
    final nowTs = Timestamp.fromDate(DateTime.now().toUtc());
    final byPassenger = _occurrences
        .where(TripOccurrenceModel.fPassengerId, isEqualTo: userId)
        .where(TripOccurrenceModel.fScheduledAt, isGreaterThanOrEqualTo: nowTs)
        .orderBy(TripOccurrenceModel.fScheduledAt)
        .limit(limit)
        .snapshots();

    final byDriver = _occurrences
        .where(TripOccurrenceModel.fDriverId, isEqualTo: userId)
        .where(TripOccurrenceModel.fScheduledAt, isGreaterThanOrEqualTo: nowTs)
        .orderBy(TripOccurrenceModel.fScheduledAt)
        .limit(limit)
        .snapshots();

    return _combineSnapshotStreams(byPassenger, byDriver, limit: limit);
  }

  @override
  Stream<List<TripOccurrence>> watchBySeries(String matchId) {
    return _occurrences
        .where(TripOccurrenceModel.fMatchId, isEqualTo: matchId)
        .orderBy(TripOccurrenceModel.fScheduledAt)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TripOccurrenceModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<List<TripOccurrence>> getFutureScheduledOf(String matchId) async {
    try {
      final nowTs = Timestamp.fromDate(DateTime.now().toUtc());
      final snap = await _occurrences
          .where(TripOccurrenceModel.fMatchId, isEqualTo: matchId)
          .where(TripOccurrenceModel.fStatus,
              isEqualTo: OccurrenceStatus.scheduled.name)
          .where(TripOccurrenceModel.fScheduledAt,
              isGreaterThanOrEqualTo: nowTs)
          .get();
      return snap.docs
          .map((doc) => TripOccurrenceModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> cancelSeriesBatch(
    String matchId, {
    required String byUserId,
    String? reason,
  }) async {
    try {
      final futures = await getFutureScheduledOf(matchId);
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();
      for (final occurrence in futures) {
        batch.update(_occurrences.doc(occurrence.id), {
          TripOccurrenceModel.fStatus: OccurrenceStatus.cancelled.name,
          TripOccurrenceModel.fCancelledAt: now,
          TripOccurrenceModel.fCancelledBy: byUserId,
          TripOccurrenceModel.fCancellationReason: ?reason,
          TripOccurrenceModel.fCancelScope: CancelScope.series.wireValue,
          TripOccurrenceModel.fUpdatedAt: now,
        });
      }
      batch.update(_matches.doc(matchId), {
        MatchModel.fSeriesStatus: MatchSeriesStatus.cancelled.name,
        MatchModel.fStatus: 'cancelled',
        MatchModel.fUpdatedAt: now,
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> updateSeriesStatus(
    String matchId,
    MatchSeriesStatus next,
  ) async {
    try {
      await _matches.doc(matchId).update({
        MatchModel.fSeriesStatus: next.name,
        MatchModel.fUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permisos para esta operación';
      case 'unavailable':
        return 'Servicio temporalmente no disponible';
      case 'not-found':
        return 'Ocurrencia no encontrada';
      default:
        return e.message ?? 'Error de Firestore (${e.code})';
    }
  }
}

/// Fusiona dos streams de QuerySnapshot dedupeando por id, aplicando el
/// `limit` global tras el merge para no devolver más de N elementos
/// combinados.
Stream<List<TripOccurrence>> _combineSnapshotStreams(
  Stream<QuerySnapshot<Map<String, dynamic>>> a,
  Stream<QuerySnapshot<Map<String, dynamic>>> b, {
  required int limit,
}) {
  late StreamController<List<TripOccurrence>> controller;

  Map<String, TripOccurrence> passengerSide = {};
  Map<String, TripOccurrence> driverSide = {};

  void emit() {
    final merged = <String, TripOccurrence>{}
      ..addAll(passengerSide)
      ..addAll(driverSide);
    final list = merged.values.toList()
      ..sort((x, y) => x.scheduledAt.compareTo(y.scheduledAt));
    if (list.length > limit) {
      controller.add(list.sublist(0, limit));
    } else {
      controller.add(list);
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subA;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subB;

  controller = StreamController<List<TripOccurrence>>(
    onListen: () {
      subA = a.listen(
        (snap) {
          passengerSide = {
            for (final doc in snap.docs)
              doc.id: TripOccurrenceModel.fromFirestore(doc),
          };
          emit();
        },
        onError: controller.addError,
      );
      subB = b.listen(
        (snap) {
          driverSide = {
            for (final doc in snap.docs)
              doc.id: TripOccurrenceModel.fromFirestore(doc),
          };
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );

  return controller.stream;
}
