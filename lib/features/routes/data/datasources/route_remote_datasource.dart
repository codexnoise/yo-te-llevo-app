import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/geohash_utils.dart';
import '../../../../core/utils/lat_lng.dart';
import '../models/route_model.dart';

abstract class RouteRemoteDataSource {
  Future<RouteModel> createRoute(RouteModel route);
  Future<List<RouteModel>> getDriverRoutes(String driverId);
  Future<void> deactivateRoute(String routeId);
  Future<void> updateRoute(RouteModel route);
  Future<List<RouteModel>> findRoutesNearby(LatLng point,
      {String field = RouteModel.fGeohashOrigin});
  Future<RouteModel> getRoute(String routeId);
}

class RouteRemoteDataSourceImpl implements RouteRemoteDataSource {
  final FirebaseFirestore _firestore;

  RouteRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _routes =>
      _firestore.collection(FirebaseConstants.routesCollection);

  @override
  Future<RouteModel> createRoute(RouteModel route) async {
    try {
      final docRef =
          await _routes.add(route.toFirestore(useServerTimestamp: true));
      final snap = await docRef.get();
      return RouteModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<List<RouteModel>> getDriverRoutes(String driverId) async {
    try {
      final snap = await _routes
          .where(RouteModel.fDriverId, isEqualTo: driverId)
          .where(RouteModel.fIsActive, isEqualTo: true)
          .orderBy(RouteModel.fCreatedAt, descending: true)
          .get();

      return snap.docs.map(RouteModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> deactivateRoute(String routeId) async {
    try {
      await _routes.doc(routeId).update({
        RouteModel.fIsActive: false,
        RouteModel.fUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> updateRoute(RouteModel route) async {
    try {
      await _routes.doc(route.id).update(route.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<List<RouteModel>> findRoutesNearby(LatLng point,
      {String field = RouteModel.fGeohashOrigin}) async {
    try {
      final ranges = GeohashUtils.queryRanges(point);

      final futures = ranges.map((range) {
        return _routes
            .where(field, isGreaterThanOrEqualTo: range.start)
            .where(field, isLessThan: range.end)
            .where(RouteModel.fIsActive, isEqualTo: true)
            .get();
      });

      final snapshots = await Future.wait(futures);

      final routesById = <String, RouteModel>{};
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          routesById.putIfAbsent(doc.id, () => RouteModel.fromFirestore(doc));
        }
      }

      return routesById.values.toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<RouteModel> getRoute(String routeId) async {
    try {
      final snap = await _routes.doc(routeId).get();
      if (!snap.exists) {
        throw const ServerException(message: 'Ruta no encontrada');
      }
      return RouteModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permisos para realizar esta operación';
      case 'unavailable':
        return 'Servicio temporalmente no disponible';
      case 'not-found':
        return 'Ruta no encontrada';
      default:
        return e.message ?? 'Error de Firestore (${e.code})';
    }
  }
}
