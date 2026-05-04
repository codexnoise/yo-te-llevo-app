import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/occurrence_status.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_occurrence.dart';
import '../providers/trip_occurrence_providers.dart';
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
    final flagAsync = ref.watch(recurringTripsEnabledProvider);
    final flagOn = flagAsync.valueOrNull ?? false;
    return flagOn ? const _UpcomingOccurrencesTab() : const _LegacyActiveTab();
  }
}

/// Versión legacy basada en `Match.status` (pre viajes recurrentes).
class _LegacyActiveTab extends ConsumerWidget {
  const _LegacyActiveTab();

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

/// Versión nueva: lista de `TripOccurrence` futuras.
class _UpcomingOccurrencesTab extends ConsumerWidget {
  const _UpcomingOccurrencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(upcomingOccurrencesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(message: err.toString()),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyView(
            icon: Icons.event_available,
            message: 'No tienes viajes programados',
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(upcomingOccurrencesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) => _OccurrenceTile(
              o: list[i],
              viewerId: user?.id ?? '',
            ),
          ),
        );
      },
    );
  }
}

class _OccurrenceTile extends ConsumerWidget {
  final TripOccurrence o;
  final String viewerId;
  const _OccurrenceTile({required this.o, required this.viewerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPassenger = o.isPassengerView(viewerId);
    final dateLabel = _relativeDate(o.scheduledAt.toLocal());
    final time = DateFormat.Hm().format(o.scheduledAt.toLocal());
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () => context.push('/occurrences/${o.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(
            isPassenger ? Icons.directions_car : Icons.person,
            color: AppColors.primary,
          ),
        ),
        title: Text('$dateLabel · $time',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_statusLabel(o.status),
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  String _statusLabel(OccurrenceStatus s) => switch (s) {
        OccurrenceStatus.scheduled => 'Programado',
        OccurrenceStatus.active => 'En curso',
        OccurrenceStatus.completed => 'Completado',
        OccurrenceStatus.cancelled => 'Cancelado',
        OccurrenceStatus.noShow => 'No-show',
      };

  static String _relativeDate(DateTime local) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay(local, today)) return 'Hoy';
    if (sameDay(local, tomorrow)) return 'Mañana';
    return DateFormat('EEE d MMM', 'es').format(local);
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
