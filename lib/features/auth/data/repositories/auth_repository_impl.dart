import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<String?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  String? get currentUserId => _remoteDataSource.currentUserId;

  @override
  Future<Either<Failure, String>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final uid = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      return Right(uid);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final uid = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(uid);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
