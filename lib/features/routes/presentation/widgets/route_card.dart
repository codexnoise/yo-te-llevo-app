import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/helpers/route_format_helpers.dart';

class RouteCard extends StatelessWidget {
  final RouteEntity route;
  final VoidCallback? onDeactivate;

  const RouteCard({
    super.key,
    required this.route,
    this.onDeactivate,
  });

  static const _dayLabels = {
    'mon': 'L',
    'tue': 'M',
    'wed': 'Mi',
    'thu': 'J',
    'fri': 'V',
    'sat': 'S',
    'sun': 'D',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Origin
            Row(
              children: [
                const Icon(Icons.trip_origin,
                    size: 16, color: AppColors.pickupMarker),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.originAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Destination
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.dropoffMarker),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.destinationAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Schedule days
            Wrap(
              spacing: 4,
              children: route.schedule.days.map((day) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _dayLabels[day] ?? day,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Info row
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(route.schedule.departureTime,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.straighten,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                    RouteFormatHelpers.formatDistance(route.distanceMeters),
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.timer,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                    RouteFormatHelpers.formatDuration(
                        route.durationSeconds.round()),
                    style: const TextStyle(fontSize: 12)),
                const Spacer(),
                const Icon(Icons.event_seat,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${route.availableSeats}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),

            // Price + deactivate
            Row(
              children: [
                Text(
                  route.pricing.formatted,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (onDeactivate != null)
                  TextButton.icon(
                    onPressed: onDeactivate,
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Desactivar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
