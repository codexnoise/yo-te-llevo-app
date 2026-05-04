import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/map/presentation/screens/home_map_screen.dart';
import '../../features/matching/presentation/screens/match_results_screen.dart';
import '../../features/matching/presentation/screens/search_trip_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/vehicle_setup_screen.dart';
import '../../features/ratings/presentation/screens/rating_screen.dart';
import '../../features/routes/presentation/screens/create_route_screen.dart';
import '../../features/routes/presentation/screens/driver_routes_screen.dart';
import '../../features/trips/presentation/screens/occurrence_details_screen.dart';
import '../../features/trips/presentation/screens/series_management_screen.dart';
import '../../features/trips/presentation/screens/trip_detail_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import '../../features/trips/presentation/screens/upcoming_trips_screen.dart';
import 'go_router_refresh_stream.dart';

/// Decide si una navegación debe ser redirigida por el guard de auth.
/// Extraído como función pura para poder testearlo sin Firebase real.
String? computeAuthRedirect({
  required bool isLoggedIn,
  required String location,
}) {
  final isPublicRoute = location == '/splash' ||
      location == '/login' ||
      location == '/register';

  if (!isLoggedIn && !isPublicRoute) return '/login';
  if (isLoggedIn && (location == '/login' || location == '/register')) {
    return '/home';
  }
  if (isLoggedIn && location == '/splash') return '/home';
  return null;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(firebaseAuth.authStateChanges()),
    redirect: (context, state) => computeAuthRedirect(
      isLoggedIn: firebaseAuth.currentUser != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchTripScreen(),
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
      GoRoute(
        path: '/rate/:matchId/:toUserId',
        name: 'rate',
        builder: (context, state) => RatingScreen(
          matchId: state.pathParameters['matchId']!,
          toUserId: state.pathParameters['toUserId']!,
        ),
      ),
      // Detalle de una ocurrencia recurrente / único viaje (spec viajes
      // recurrentes §6.3). Coexiste con `/trips/:matchId` mientras dure la
      // migración entre `Match.status` y `TripOccurrence.status`.
      GoRoute(
        path: '/occurrences/:id',
        name: 'occurrence-detail',
        builder: (context, state) => OccurrenceDetailsScreen(
          occurrenceId: state.pathParameters['id']!,
        ),
      ),
      // Administración de la serie (driver-only): pausar/reanudar/cancelar.
      GoRoute(
        path: '/series/:matchId',
        name: 'series-management',
        builder: (context, state) => SeriesManagementScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      // Atajo opcional al listado de próximas ocurrencias (spec viajes
      // recurrentes §6.3). Útil para deep-links de notificaciones futuras.
      GoRoute(
        path: '/upcoming',
        name: 'upcoming',
        builder: (context, state) => const UpcomingTripsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeMapScreen(),
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

