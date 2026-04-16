import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/vehicle_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserEntity>> getUser(String uid);

  Future<Either<Failure, void>> createUser(UserEntity user);

  Future<Either<Failure, void>> updateUser(UserEntity user);

  Future<Either<Failure, VehicleEntity?>> getVehicle(String uid);

  Future<Either<Failure, void>> saveVehicle(String uid, VehicleEntity vehicle);

  /// Actualiza el token FCM del usuario. Se llama desde [NotificationService]
  /// al inicio de sesión y cuando `onTokenRefresh` emite uno nuevo. Pasar
  /// null limpia el token (p. ej. tras logout).
  Future<Either<Failure, void>> updateFcmToken(String uid, String? token);
}
