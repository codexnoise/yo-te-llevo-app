import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../models/match_model.dart';

abstract class TripRemoteDataSource {
  Future<Match> createMatch(Match match);

  /// Actualiza `status` + `updatedAt`. El datasource no valida transiciones:
  /// la spec las enforza en Firestore rules. El repo puede validar pre-update
  /// para UX.
  Future<void> updateStatus(String matchId, MatchStatus status);

  Future<Match> getMatch(String matchId);

  Stream<Match> watchMatch(String matchId);

  /// Stream combinado: rutas donde el usuario es pasajero o conductor con
  /// status ∈ [pending, accepted, active]. Fusiona dos queries en memoria y
  /// deduplica por id.
  Stream<List<Match>> watchActiveTrips(String userId);

  Future<List<Match>> getHistory(String userId, {int limit = 50});
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final FirebaseFirestore _firestore;

  TripRemoteDataSourceImpl(this._firestore);

  static const List<String> _activeStatuses = [
    'pending',
    'accepted',
    'active',
  ];

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection(FirebaseConstants.matchesCollection);

  @override
  Future<Match> createMatch(Match match) async {
    try {
      final ref = await _matches.add(MatchModel.toCreateMap(match));
      final snap = await ref.get();
      return MatchModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> updateStatus(String matchId, MatchStatus status) async {
    try {
      await _matches.doc(matchId).update({
        MatchModel.fStatus: status.name,
        MatchModel.fUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<Match> getMatch(String matchId) async {
    try {
      final snap = await _matches.doc(matchId).get();
      if (!snap.exists) {
        throw const ServerException(message: 'Viaje no encontrado');
      }
      return MatchModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Stream<Match> watchMatch(String matchId) {
    return _matches.doc(matchId).snapshots().map((snap) {
      if (!snap.exists) {
        throw const ServerException(message: 'Viaje no encontrado');
      }
      return MatchModel.fromFirestore(snap);
    });
  }

  @override
  Stream<List<Match>> watchActiveTrips(String userId) {
    final byPassenger = _matches
        .where(MatchModel.fPassengerId, isEqualTo: userId)
        .where(MatchModel.fStatus, whereIn: _activeStatuses)
        .snapshots();

    final byDriver = _matches
        .where(MatchModel.fDriverId, isEqualTo: userId)
        .where(MatchModel.fStatus, whereIn: _activeStatuses)
        .snapshots();

    return _combineSnapshotStreams(byPassenger, byDriver);
  }

  @override
  Future<List<Match>> getHistory(String userId, {int limit = 50}) async {
    try {
      final futures = [
        _matches
            .where(MatchModel.fPassengerId, isEqualTo: userId)
            .where(MatchModel.fStatus, isEqualTo: MatchStatus.completed.name)
            .orderBy(MatchModel.fCreatedAt, descending: true)
            .limit(limit)
            .get(),
        _matches
            .where(MatchModel.fDriverId, isEqualTo: userId)
            .where(MatchModel.fStatus, isEqualTo: MatchStatus.completed.name)
            .orderBy(MatchModel.fCreatedAt, descending: true)
            .limit(limit)
            .get(),
      ];
      final snapshots = await Future.wait(futures);
      final byId = <String, Match>{};
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          byId.putIfAbsent(doc.id, () => MatchModel.fromFirestore(doc));
        }
      }
      final list = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (list.length > limit) return list.sublist(0, limit);
      return list;
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
        return 'Viaje no encontrado';
      default:
        return e.message ?? 'Error de Firestore (${e.code})';
    }
  }
}

/// Fusiona dos streams de QuerySnapshot en un único `Stream<List<Match>>`
/// dedupeando por id del documento. Emite cada vez que cualquiera de los
/// dos streams actualiza.
Stream<List<Match>> _combineSnapshotStreams(
  Stream<QuerySnapshot<Map<String, dynamic>>> a,
  Stream<QuerySnapshot<Map<String, dynamic>>> b,
) {
  late StreamController<List<Match>> controller;

  Map<String, Match> passengerSide = {};
  Map<String, Match> driverSide = {};

  void emit() {
    final merged = <String, Match>{}
      ..addAll(passengerSide)
      ..addAll(driverSide);
    final list = merged.values.toList()
      ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    controller.add(list);
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subA;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subB;

  controller = StreamController<List<Match>>(
    onListen: () {
      subA = a.listen(
        (snap) {
          passengerSide = {
            for (final doc in snap.docs) doc.id: MatchModel.fromFirestore(doc),
          };
          emit();
        },
        onError: controller.addError,
      );
      subB = b.listen(
        (snap) {
          driverSide = {
            for (final doc in snap.docs) doc.id: MatchModel.fromFirestore(doc),
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
