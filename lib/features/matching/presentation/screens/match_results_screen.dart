import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../trips/presentation/providers/trips_providers.dart';
import '../../domain/entities/match_candidate.dart';
import '../providers/matching_providers.dart';
import '../providers/matching_state.dart';
import '../widgets/match_candidate_card.dart';

/// Lookup autoDispose de un usuario por uid — usado para enriquecer cada
/// card con la foto/nombre/rating del conductor.
final _driverProfileProvider = FutureProvider.autoDispose
    .family<UserEntity?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  final ProfileRepository repo = ref.watch(profileRepositoryProvider);
  final result = await repo.getUser(uid);
  return result.fold((_) => null, (user) => user);
});

class MatchResultsScreen extends ConsumerWidget {
  const MatchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchingNotifierProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final actionState = ref.watch(tripsNotifierProvider);

    ref.listen<AsyncValue<void>>(tripsNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Conductores disponibles')),
      body: _body(context, ref, state, currentUser?.id, actionState.isLoading),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    MatchingState state,
    String? userId,
    bool busy,
  ) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(state.error!.message, textAlign: TextAlign.center),
        ),
      );
    }
    final List<MatchCandidate> candidates = state.candidates;
    if (candidates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off,
                  size: 56, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text(
                'No encontramos conductores compatibles con tu búsqueda.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: candidates.length,
      itemBuilder: (_, i) => _buildCard(
        context,
        ref,
        candidates[i],
        userId,
        busy,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    MatchCandidate candidate,
    String? userId,
    bool busy,
  ) {
    final driverAsync =
        ref.watch(_driverProfileProvider(candidate.route.driverId));
    return MatchCandidateCard(
      candidate: candidate,
      driver: driverAsync.valueOrNull,
      requesting: busy,
      onRequest: userId == null
          ? null
          : () => _request(context, ref, candidate, userId),
    );
  }

  Future<void> _request(
    BuildContext context,
    WidgetRef ref,
    MatchCandidate candidate,
    String passengerId,
  ) async {
    final notifier = ref.read(tripsNotifierProvider.notifier);
    final trip = await notifier.requestTrip(
      candidate: candidate,
      passengerId: passengerId,
    );
    if (!context.mounted) return;
    if (trip != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada')),
      );
      context.go('/trips/${trip.id}');
    }
  }
}
