import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/router/app_router.dart';

void main() {
  group('computeAuthRedirect', () {
    test('unauthenticated user on /splash is not redirected', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: false,
        location: '/splash',
      );
      expect(redirect, isNull);
    });

    test('unauthenticated user on /login is not redirected', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: false,
        location: '/login',
      );
      expect(redirect, isNull);
    });

    test('unauthenticated user on /register is not redirected', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: false,
        location: '/register',
      );
      expect(redirect, isNull);
    });

    test('unauthenticated user on /trips is redirected to /login', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: false,
        location: '/trips',
      );
      expect(redirect, '/login');
    });

    test('unauthenticated user on /home is redirected to /login', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: false,
        location: '/home',
      );
      expect(redirect, '/login');
    });

    test('authenticated user on /login is redirected to /home', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: true,
        location: '/login',
      );
      expect(redirect, '/home');
    });

    test('authenticated user on /register is redirected to /home', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: true,
        location: '/register',
      );
      expect(redirect, '/home');
    });

    test('authenticated user on /splash is redirected to /home', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: true,
        location: '/splash',
      );
      expect(redirect, '/home');
    });

    test('authenticated user on /home is allowed', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: true,
        location: '/home',
      );
      expect(redirect, isNull);
    });

    test('authenticated user on /trips/:id is allowed', () {
      final redirect = computeAuthRedirect(
        isLoggedIn: true,
        location: '/trips/abc',
      );
      expect(redirect, isNull);
    });
  });
}
