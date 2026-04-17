import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/matching/presentation/screens/match_results_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/vehicle_setup_screen.dart';
import '../../features/routes/presentation/screens/create_route_screen.dart';
import '../../features/routes/presentation/screens/driver_routes_screen.dart';
import '../../features/trips/presentation/screens/trip_detail_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import '../theme/app_colors.dart';
import 'go_router_refresh_stream.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn = firebaseAuth.currentUser != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/vehicle-setup',
        name: 'vehicle-setup',
        builder: (context, state) => const VehicleSetupScreen(),
      ),
      GoRoute(
        path: '/create-route',
        name: 'create-route',
        builder: (context, state) => const CreateRouteScreen(),
      ),
      GoRoute(
        path: '/driver-routes',
        name: 'driver-routes',
        builder: (context, state) => const DriverRoutesScreen(),
      ),
      GoRoute(
        path: '/search/results',
        name: 'search-results',
        builder: (context, state) => const MatchResultsScreen(),
      ),
      // Detalle de viaje: fuera del shell para que ocupe pantalla completa.
      GoRoute(
        path: '/trips/:matchId',
        name: 'trip-detail',
        builder: (context, state) => TripDetailScreen(
          matchId: state.pathParameters['matchId']!,
        ),
        routes: [
          GoRoute(
            path: 'chat',
            name: 'trip-chat',
            builder: (context, state) => ChatScreen(
              matchId: state.pathParameters['matchId']!,
            ),
          ),
        ],
      ),
      // Stub para M8 (rating).
      GoRoute(
        path: '/rate/:matchId/:toUserId',
        name: 'rate',
        builder: (context, state) => _PendingModuleScreen(
          title: 'Calificar',
          message:
              'El sistema de calificaciones se habilita en el Módulo 8.',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const _PlaceholderScreen(title: 'Mapa'),
          ),
          GoRoute(
            path: '/trips',
            name: 'trips',
            builder: (context, state) => const TripsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Viajes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/trips')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/trips');
      case 2:
        context.go('/profile');
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('$title - En construcción', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _PendingModuleScreen extends StatelessWidget {
  final String title;
  final String message;

  const _PendingModuleScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
