import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cancel_scope_dialog.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/cancel_scope.dart';
import '../../domain/entities/occurrence_status.dart';
import '../../domain/entities/trip_occurrence.dart';
import '../providers/trip_occurrence_providers.dart';

/// Pantalla driver-only para administrar una serie recurrente: pausar,
/// reanudar, cancelar serie. Lista todas las ocurrencias (futuras + pasadas)
/// agrupadas por estado.
class SeriesManagementScreen extends ConsumerWidget {
  final String matchId;
  const SeriesManagementScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(seriesOccurrencesProvider(matchId));
    final actionState = ref.watch(occurrenceActionsProvider);

    ref.listen<AsyncValue<void>>(occurrenceActionsProvider, (_, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Administrar serie')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(err.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (list) => _buildContent(
          context,
          ref,
          list,
          user?.id ?? '',
          actionState.isLoading,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<TripOccurrence> list,
    String viewerId,
    bool busy,
  ) {
    final notifier = ref.read(occurrenceActionsProvider.notifier);
    final upcoming = list
        .where((o) => o.status == OccurrenceStatus.scheduled)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past = list
        .where((o) => o.status != OccurrenceStatus.scheduled)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await notifier.pauseSeries(matchId);
                        if (!context.mounted) return;
                        if (ok) _toast(context, 'Serie pausada');
                      },
                icon: const Icon(Icons.pause),
                label: const Text('Pausar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await notifier.resumeSeries(matchId);
                        if (!context.mounted) return;
                        if (ok) _toast(context, 'Serie reanudada');
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reanudar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  final scope = await showCancelScopeDialog(
                    context,
                    showSeriesOption: false,
                    title: '¿Cancelar serie completa?',
                    body: 'Se cancelarán todas las ocurrencias futuras.',
                  );
                  if (scope != CancelScope.occurrence) return;
                  final ok = await notifier.cancelSeries(
                    matchId,
                    byUserId: viewerId,
                  );
                  if (!context.mounted) return;
                  if (ok) _toast(context, 'Serie cancelada');
                },
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar serie'),
        ),
        const SizedBox(height: 24),
        if (upcoming.isNotEmpty) ...[
          const _SectionTitle('Próximas'),
          for (final o in upcoming) _OccurrenceTile(o: o),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionTitle('Historial'),
          for (final o in past) _OccurrenceTile(o: o),
        ],
        if (upcoming.isEmpty && past.isEmpty) const _EmptyState(),
      ],
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _OccurrenceTile extends StatelessWidget {
  final TripOccurrence o;
  const _OccurrenceTile({required this.o});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        DateFormat("EEE d MMM 'a las' HH:mm", 'es')
            .format(o.scheduledAt.toLocal()),
      ),
      subtitle: Text(
        _statusLabel(o.status),
        style: TextStyle(color: _statusColor(o.status), fontSize: 12),
      ),
      dense: true,
    );
  }

  String _statusLabel(OccurrenceStatus s) => switch (s) {
        OccurrenceStatus.scheduled => 'Programado',
        OccurrenceStatus.active => 'En curso',
        OccurrenceStatus.completed => 'Completado',
        OccurrenceStatus.cancelled => 'Cancelado',
        OccurrenceStatus.noShow => 'No-show',
      };

  Color _statusColor(OccurrenceStatus s) => switch (s) {
        OccurrenceStatus.scheduled => AppColors.info,
        OccurrenceStatus.active => AppColors.secondary,
        OccurrenceStatus.completed => AppColors.success,
        OccurrenceStatus.cancelled => AppColors.error,
        OccurrenceStatus.noShow => AppColors.warning,
      };
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Sin ocurrencias en esta serie',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
