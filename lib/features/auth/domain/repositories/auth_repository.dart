import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  /// Stream that emits the current user uid (or null when signed out).
  Stream<String?> get authStateChanges;

  String? get currentUserId;

  Future<Either<Failure, String>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, String>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signOut();
}
