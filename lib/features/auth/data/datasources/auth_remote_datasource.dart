import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';

abstract class AuthRemoteDataSource {
  Stream<String?> get authStateChanges;
  String? get currentUserId;

  Future<String> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<String> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl(this._firebaseAuth);

  @override
  Stream<String?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  @override
  Future<String> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException(
            message: 'No se pudo crear la cuenta', code: 'no-uid');
      }
      return uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException(
            message: 'No se pudo iniciar sesión', code: 'no-uid');
      }
      return uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapAuthError(e), code: e.code);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El email no es válido';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres)';
      case 'operation-not-allowed':
        return 'Email/contraseña no está habilitado en Firebase';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Credenciales incorrectas';
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      default:
        return e.message ?? 'Error de autenticación (${e.code})';
    }
  }
}
