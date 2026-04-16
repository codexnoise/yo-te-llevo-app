import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/trip.dart';
import '../providers/trips_providers.dart';
import '../widgets/trip_card.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Viajes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ActiveTripsTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripsTab extends ConsumerWidget {
  const _ActiveTripsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(activeTripsStreamProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(message: err.toString()),
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptyView(
            icon: Icons.directions_car_outlined,
            message: 'No tienes viajes activos',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(activeTripsStreamProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: trips.length,
            itemBuilder: (_, i) => _buildCard(context, trips[i], user?.id),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, TripEntity trip, String? userId) {
    return TripCard(
      trip: trip,
      viewerId: userId ?? '',
      onTap: () => context.go('/trips/${trip.id}'),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(tripHistoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(message: err.toString()),
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptyView(
            icon: Icons.history,
            message: 'Aún no tienes viajes completados',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tripHistoryProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: trips.length,
            itemBuilder: (_, i) => TripCard(
              trip: trips[i],
              viewerId: user?.id ?? '',
              onTap: () => context.go('/trips/${trips[i].id}'),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
