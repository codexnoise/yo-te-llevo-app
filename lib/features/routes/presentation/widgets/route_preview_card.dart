import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/route_result_model.dart';
import '../../domain/helpers/route_format_helpers.dart';

class RoutePreviewCard extends StatelessWidget {
  final RouteResultModel routeResult;
  final String? originAddress;
  final String? destinationAddress;

  const RoutePreviewCard({
    super.key,
    required this.routeResult,
    this.originAddress,
    this.destinationAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (originAddress != null && originAddress!.isNotEmpty)
              _buildAddressRow(
                icon: Icons.trip_origin,
                color: AppColors.pickupMarker,
                address: originAddress!,
              ),
            if (destinationAddress != null &&
                destinationAddress!.isNotEmpty) ...[
              if (originAddress != null) const SizedBox(height: 4),
              _buildAddressRow(
                icon: Icons.location_on,
                color: AppColors.dropoffMarker,
                address: destinationAddress!,
              ),
            ],
            const Divider(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.straighten,
                  label: RouteFormatHelpers.formatDistance(
                      routeResult.distanceMeters),
                ),
                const SizedBox(width: 16),
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: RouteFormatHelpers.formatDuration(
                      routeResult.durationSeconds.round()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color color,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
