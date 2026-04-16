import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../domain/entities/match_candidate.dart';

class MatchCandidateCard extends StatelessWidget {
  final MatchCandidate candidate;
  final UserEntity? driver;
  final VoidCallback? onTap;
  final VoidCallback? onRequest;
  final bool requesting;

  const MatchCandidateCard({
    super.key,
    required this.candidate,
    this.driver,
    this.onTap,
    this.onRequest,
    this.requesting = false,
  });

  @override
  Widget build(BuildContext context) {
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
                    radius: 22,
                    backgroundImage: driver?.photoUrl != null
                        ? NetworkImage(driver!.photoUrl!)
                        : null,
                    child: driver?.photoUrl == null
                        ? const Icon(Icons.person, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver?.name ?? 'Conductor',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              (driver?.rating ?? 5.0).toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text(
                              candidate.route.schedule.departureTime,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    candidate.priceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.directions_walk,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(candidate.walkingToPickupLabel,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.alt_route,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(candidate.detourLabel,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: requesting ? null : onRequest,
                  child: requesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Solicitar viaje'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
