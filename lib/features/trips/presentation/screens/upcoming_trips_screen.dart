import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/occurrence_status.dart';
import '../../domain/entities/trip_occurrence.dart';
import '../providers/trip_occurrence_providers.dart';

/// Pantalla "Próximos viajes" — lista de `TripOccurrence` del usuario en
/// cualquiera de los dos roles, ordenadas por `scheduledAt` ascendente y
/// agrupadas por día relativo (Hoy / Mañana / fecha completa).
class UpcomingTripsScreen extends ConsumerWidget {
  const UpcomingTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(upcomingOccurrencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Próximos viajes')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(err.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(upcomingOccurrencesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              itemBuilder: (_, i) => _OccurrenceCard(
                occurrence: list[i],
                viewerId: user?.id ?? '',
                onTap: () => context.push('/occurrences/${list[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OccurrenceCard extends StatelessWidget {
  final TripOccurrence occurrence;
  final String viewerId;
  final VoidCallback onTap;

  const _OccurrenceCard({
    required this.occurrence,
    required this.viewerId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPassenger = occurrence.isPassengerView(viewerId);
    final dateLabel = _formatDateRelative(occurrence.scheduledAt);
    final timeLabel = DateFormat.Hm().format(occurrence.scheduledAt.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(
            isPassenger ? Icons.directions_car : Icons.person,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          '$dateLabel · $timeLabel',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isPassenger
              ? 'Como pasajero · ${occurrence.tripType.name == 'recurring' ? 'Serie semanal' : 'Único'}'
              : 'Como conductor · ${occurrence.tripType.name == 'recurring' ? 'Serie semanal' : 'Único'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _StatusBadge(status: occurrence.status),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OccurrenceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _descriptor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  (Color, String) _descriptor(OccurrenceStatus s) {
    switch (s) {
      case OccurrenceStatus.scheduled:
        return (AppColors.info, 'Programado');
      case OccurrenceStatus.active:
        return (AppColors.secondary, 'En curso');
      case OccurrenceStatus.completed:
        return (AppColors.success, 'Completado');
      case OccurrenceStatus.cancelled:
        return (AppColors.error, 'Cancelado');
      case OccurrenceStatus.noShow:
        return (AppColors.warning, 'No-show');
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 56, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No tienes viajes programados',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Cuando aceptes una ruta, aparecerán acá tus próximas fechas.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateRelative(DateTime utc) {
  final local = utc.toLocal();
  final today = DateTime.now();
  final tomorrow = today.add(const Duration(days: 1));
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(local, today)) return 'Hoy';
  if (sameDay(local, tomorrow)) return 'Mañana';
  return DateFormat('EEE d MMM', 'es').format(local);
}
