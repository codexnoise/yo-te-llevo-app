import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getUser(String uid);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<VehicleModel?> getVehicle(String uid);
  Future<void> saveVehicle(String uid, VehicleModel vehicle);
  Future<void> updateFcmToken(String uid, String? token);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProfileRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  DocumentReference<Map<String, dynamic>> _vehicleDoc(String uid) => _users
      .doc(uid)
      .collection(FirebaseConstants.vehicleSubcollection)
      .doc(FirebaseConstants.currentVehicleDoc);

  @override
  Future<UserModel> getUser(String uid) async {
    try {
      final snap = await _users.doc(uid).get();
      if (!snap.exists) {
        throw const ServerException(message: 'Perfil no encontrado');
      }
      return UserModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> createUser(UserModel user) async {
    try {
      await _users
          .doc(user.id)
          .set(user.toFirestore(useServerTimestamp: true));
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _users.doc(user.id).update(user.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<VehicleModel?> getVehicle(String uid) async {
    try {
      final snap = await _vehicleDoc(uid).get();
      if (!snap.exists) return null;
      return VehicleModel.fromFirestore(snap);
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> saveVehicle(String uid, VehicleModel vehicle) async {
    try {
      await _vehicleDoc(uid).set(vehicle.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(message: _firestoreMessage(e));
    }
  }

  @override
  Future<void> updateFcmToken(String uid, String? token) async {
    try {
      await _users.doc(uid).update({UserModel.fFcmToken: token});
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
        return 'Recurso no encontrado';
      default:
        return e.message ?? 'Error de Firestore (${e.code})';
    }
  }
}
