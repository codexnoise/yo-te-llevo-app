import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/trip.dart';
import '../providers/trips_providers.dart';

class TripDetailScreen extends ConsumerWidget {
  final String matchId;

  const TripDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(tripDetailStreamProvider(matchId));
    final actionState = ref.watch(tripsNotifierProvider);

    ref.listen<AsyncValue<void>>(tripsNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del viaje')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(err.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (trip) => _buildContent(
          context,
          ref,
          trip,
          user?.id ?? '',
          actionState.isLoading,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    TripEntity trip,
    String viewerId,
    bool busy,
  ) {
    final counterpart = trip.counterpart;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusChip(status: trip.status),
          const SizedBox(height: 16),
          if (counterpart != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: counterpart.photoUrl != null
                      ? NetworkImage(counterpart.photoUrl!)
                      : null,
                  child: counterpart.photoUrl == null
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counterpart.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(counterpart.rating.toStringAsFixed(1)),
                          const SizedBox(width: 8),
                          Text(
                            '${counterpart.totalTrips} viajes',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (counterpart.phone != null)
                        Text(
                          counterpart.phone!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _InfoRow(
            icon: Icons.trip_origin,
            label: 'Recogida',
            value: trip.match.pickupAddress,
            color: AppColors.pickupMarker,
          ),
          _InfoRow(
            icon: Icons.location_on,
            label: 'Bajada',
            value: trip.match.dropoffAddress,
            color: AppColors.dropoffMarker,
          ),
          if (trip.route != null)
            _InfoRow(
              icon: Icons.route,
              label: 'Ruta',
              value:
                  '${trip.route!.originAddress} → ${trip.route!.destinationAddress}',
              color: AppColors.primary,
            ),
          _InfoRow(
            icon: Icons.payments,
            label: 'Precio',
            value: '\$${trip.match.price.toStringAsFixed(2)}',
            color: AppColors.primary,
          ),
          if (trip.match.days.isNotEmpty)
            _InfoRow(
              icon: Icons.calendar_month,
              label: 'Días',
              value: trip.match.days.join(', '),
              color: AppColors.textSecondary,
            ),
          const SizedBox(height: 24),
          _buildActions(context, ref, trip, viewerId, busy),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    TripEntity trip,
    String viewerId,
    bool busy,
  ) {
    if (viewerId.isEmpty) return const SizedBox.shrink();
    final notifier = ref.read(tripsNotifierProvider.notifier);
    final buttons = <Widget>[];

    if (trip.canRespond(viewerId)) {
      buttons
        ..add(_primaryButton(
          label: 'Aceptar',
          busy: busy,
          onPressed: () async {
            final ok = await notifier.accept(trip.id);
            if (!context.mounted) return;
            if (ok) _toast(context, 'Solicitud aceptada');
          },
        ))
        ..add(const SizedBox(height: 8))
        ..add(_outlinedButton(
          label: 'Rechazar',
          busy: busy,
          onPressed: () async {
            final ok = await notifier.reject(trip.id);
            if (!context.mounted) return;
            if (ok) _toast(context, 'Solicitud rechazada');
          },
        ));
    }

    if (trip.canStart(viewerId)) {
      buttons.add(_primaryButton(
        label: 'Iniciar viaje',
        busy: busy,
        onPressed: () async {
          final ok = await notifier.start(trip.id);
          if (!context.mounted) return;
          if (ok) _toast(context, 'Viaje iniciado');
        },
      ));
    }

    if (trip.canComplete(viewerId)) {
      buttons.add(_primaryButton(
        label: 'Finalizar viaje',
        busy: busy,
        onPressed: () async {
          final ok = await notifier.complete(trip.id);
          if (!context.mounted) return;
          if (ok) _toast(context, 'Viaje finalizado');
        },
      ));
    }

    if (trip.canCancel && trip.isParticipant(viewerId)) {
      buttons
        ..add(const SizedBox(height: 8))
        ..add(_outlinedButton(
          label: 'Cancelar viaje',
          busy: busy,
          destructive: true,
          onPressed: () async {
            final confirmed = await _confirm(
              context,
              title: '¿Cancelar viaje?',
              body: 'Esta acción no se puede deshacer.',
            );
            if (!confirmed) return;
            final ok = await notifier.cancel(trip.id);
            if (!context.mounted) return;
            if (ok) _toast(context, 'Viaje cancelado');
          },
        ));
    }

    if (trip.canOpenChat) {
      buttons
        ..add(const SizedBox(height: 8))
        ..add(_outlinedButton(
          label: 'Chatear',
          busy: busy,
          onPressed: () => context.go('/trips/${trip.id}/chat'),
        ));
    }

    if (trip.canRate) {
      final toUserId = trip.isPassengerView(viewerId)
          ? trip.match.driverId
          : trip.match.passengerId;
      buttons
        ..add(const SizedBox(height: 8))
        ..add(_primaryButton(
          label: 'Calificar',
          busy: busy,
          onPressed: () => context.go('/rate/${trip.id}/$toUserId'),
        ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }

  Widget _primaryButton({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }

  Widget _outlinedButton({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
    bool destructive = false,
  }) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: destructive
          ? OutlinedButton.styleFrom(foregroundColor: AppColors.error)
          : null,
      child: Text(label),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _StatusChip extends StatelessWidget {
  final MatchStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _descriptor(status);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  (Color, String) _descriptor(MatchStatus s) {
    switch (s) {
      case MatchStatus.pending:
        return (AppColors.warning, 'Pendiente');
      case MatchStatus.accepted:
        return (AppColors.info, 'Aceptado');
      case MatchStatus.active:
        return (AppColors.secondary, 'En curso');
      case MatchStatus.completed:
        return (AppColors.success, 'Completado');
      case MatchStatus.rejected:
        return (AppColors.error, 'Rechazado');
      case MatchStatus.cancelled:
        return (AppColors.textSecondary, 'Cancelado');
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
