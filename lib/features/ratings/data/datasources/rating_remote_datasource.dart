import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/rating_model.dart';

abstract class RatingRemoteDataSource {
  Future<void> createRating(RatingModel rating);

  Future<bool> hasRated({
    required String fromUserId,
    required String matchId,
  });

  Future<List<RatingModel>> getRatingsForUser(String userId);
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final FirebaseFirestore _firestore;

  RatingRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore.collection(FirebaseConstants.ratingsCollection);

  @override
  Future<void> createRating(RatingModel rating) async {
    try {
      await _ratings.doc(rating.id).set(rating.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<bool> hasRated({
    required String fromUserId,
    required String matchId,
  }) async {
    try {
      final snap = await _ratings
          .where(RatingModel.fFromUserId, isEqualTo: fromUserId)
          .where(RatingModel.fMatchId, isEqualTo: matchId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<List<RatingModel>> getRatingsForUser(String userId) async {
    try {
      final snap = await _ratings
          .where(RatingModel.fToUserId, isEqualTo: userId)
          .get();
      return snap.docs.map(RatingModel.fromFirestore).toList();
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
        return 'Recurso no encontrado';
      default:
        return e.message ?? 'Error de Firestore (${e.code})';
    }
  }
}
