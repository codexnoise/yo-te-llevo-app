import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../matching/domain/entities/match_status.dart';
import '../../domain/entities/trip.dart';

class TripCard extends StatelessWidget {
  final TripEntity trip;
  final String viewerId;
  final VoidCallback? onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.viewerId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counterpartLabel = trip.counterpart?.name ??
        (trip.isPassengerView(viewerId) ? 'Conductor' : 'Pasajero');
    final routeLabel = trip.route != null
        ? '${trip.route!.originAddress} → ${trip.route!.destinationAddress}'
        : '${trip.match.pickupAddress} → ${trip.match.dropoffAddress}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: trip.counterpart?.photoUrl != null
                        ? NetworkImage(trip.counterpart!.photoUrl!)
                        : null,
                    child: trip.counterpart?.photoUrl == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          counterpartLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (trip.counterpart != null)
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                trip.counterpart!.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: trip.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.place,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      routeLabel,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.payments,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '\$${trip.match.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(trip.match.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$m/$y';
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _descriptor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
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
