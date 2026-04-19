import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/rating_providers.dart';

/// Pantalla de calificación mutua post-viaje (spec §8, ruta
/// `/rate/:matchId/:toUserId`).
class RatingScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String toUserId;

  const RatingScreen({
    super.key,
    required this.matchId,
    required this.toUserId,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _stars = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final ok = await ref
        .read(ratingNotifierProvider(widget.matchId).notifier)
        .submit(
          fromUserId: currentUser.id,
          toUserId: widget.toUserId,
          stars: _stars,
          comment: _commentController.text,
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu calificación!')),
      );
      context.go('/trips');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final ratedAsync = ref.watch(ratedUserProvider(widget.toUserId));
    final notifierState = ref.watch(ratingNotifierProvider(widget.matchId));

    final hasRatedAsync = currentUser == null
        ? const AsyncValue<bool>.data(false)
        : ref.watch(hasRatedProvider((
            matchId: widget.matchId,
            fromUserId: currentUser.id,
          )));

    ref.listen<AsyncValue<void>>(
      ratingNotifierProvider(widget.matchId),
      (_, next) {
        next.whenOrNull(
          error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err.toString())),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Calificar')),
      body: ratedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(err.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No se encontró el usuario a calificar.'),
              ),
            );
          }
          final alreadyRated = hasRatedAsync.valueOrNull ?? false;
          return _buildForm(
            user: user,
            alreadyRated: alreadyRated,
            busy: notifierState.isLoading,
          );
        },
      ),
    );
  }

  Widget _buildForm({
    required UserEntity user,
    required bool alreadyRated,
    required bool busy,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${user.totalTrips} viajes · ${user.rating.toStringAsFixed(1)} ★',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Cómo estuvo el viaje?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _StarSelector(
            value: _stars,
            enabled: !alreadyRated && !busy,
            onChanged: (value) => setState(() => _stars = value),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            enabled: !alreadyRated && !busy,
            maxLength: 280,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (alreadyRated)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Ya calificaste este viaje.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: (alreadyRated || busy || _stars == 0) ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar calificación'),
          ),
        ],
      ),
    );
  }
}

class _StarSelector extends StatelessWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _StarSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        final filled = star <= value;
        return IconButton(
          onPressed: enabled ? () => onChanged(star) : null,
          iconSize: 40,
          tooltip: '$star estrella${star == 1 ? '' : 's'}',
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? Colors.amber : AppColors.textSecondary,
          ),
        );
      }),
    );
  }
}
