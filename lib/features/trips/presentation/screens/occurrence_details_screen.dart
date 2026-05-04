import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cancel_scope_dialog.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../matching/domain/entities/match.dart';
import '../../domain/entities/cancel_scope.dart';
import '../../domain/entities/occurrence_status.dart';
import '../../domain/entities/trip_occurrence.dart';
import '../providers/trip_occurrence_providers.dart';

/// Detalle de una `TripOccurrence`. Muestra fecha, contraparte, dirección y
/// expone los botones de iniciar/finalizar (sólo conductor) y cancelar
/// (cualquier participante). La cancelación abre `cancel_scope_dialog`.
class OccurrenceDetailsScreen extends ConsumerWidget {
  final String occurrenceId;
  const OccurrenceDetailsScreen({super.key, required this.occurrenceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(occurrenceByIdProvider(occurrenceId));
    final actionState = ref.watch(occurrenceActionsProvider);

    ref.listen<AsyncValue<void>>(occurrenceActionsProvider, (_, next) {
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
        data: (occurrence) => _buildContent(
          context,
          ref,
          occurrence,
          user?.id ?? '',
          actionState.isLoading,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    TripOccurrence o,
    String viewerId,
    bool busy,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusChip(status: o.status),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.event,
            label: 'Fecha',
            value: DateFormat("EEE d MMM 'a las' HH:mm", 'es')
                .format(o.scheduledAt.toLocal()),
          ),
          _InfoRow(
            icon: Icons.payments,
            label: 'Cobro',
            value: '\$${(o.priceCents / 100).toStringAsFixed(2)}',
          ),
          _InfoRow(
            icon: Icons.replay,
            label: 'Tipo',
            value: o.tripType == MatchTripType.recurring
                ? 'Serie recurrente'
                : 'Viaje único',
          ),
          const SizedBox(height: 24),
          _buildActions(context, ref, o, viewerId, busy),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    TripOccurrence o,
    String viewerId,
    bool busy,
  ) {
    if (viewerId.isEmpty) return const SizedBox.shrink();
    final notifier = ref.read(occurrenceActionsProvider.notifier);
    final buttons = <Widget>[];

    if (o.canStart(viewerId)) {
      buttons.add(_primaryButton(
        label: 'Iniciar viaje',
        busy: busy,
        onPressed: () async {
          final ok = await notifier.start(o.id);
          if (!context.mounted) return;
          if (ok) _toast(context, 'Viaje iniciado');
        },
      ));
    }

    if (o.canComplete(viewerId)) {
      buttons.add(_primaryButton(
        label: 'Finalizar viaje',
        busy: busy,
        onPressed: () async {
          final ok = await notifier.complete(o.id);
          if (!context.mounted) return;
          if (ok) _toast(context, 'Viaje finalizado');
        },
      ));
    }

    if (o.canCancel(viewerId)) {
      buttons
        ..add(const SizedBox(height: 8))
        ..add(_outlinedButton(
          label: 'Cancelar viaje',
          busy: busy,
          destructive: true,
          onPressed: () async {
            final scope = await showCancelScopeDialog(
              context,
              showSeriesOption: o.tripType == MatchTripType.recurring,
            );
            if (scope == null) return;
            final ok = scope == CancelScope.series
                ? await notifier.cancelSeriesFromOccurrence(
                    o.id,
                    byUserId: viewerId,
                  )
                : await notifier.cancelOccurrence(
                    o.id,
                    byUserId: viewerId,
                  );
            if (!context.mounted) return;
            if (ok) {
              _toast(
                context,
                scope == CancelScope.series
                    ? 'Serie cancelada'
                    : 'Viaje cancelado',
              );
            }
          },
        ));
    }

    if (o.tripType == MatchTripType.recurring && viewerId == o.driverId) {
      buttons
        ..add(const SizedBox(height: 8))
        ..add(_outlinedButton(
          label: 'Administrar serie',
          busy: busy,
          onPressed: () => context.push('/series/${o.matchId}'),
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
}

class _StatusChip extends StatelessWidget {
  final OccurrenceStatus status;
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
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
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
