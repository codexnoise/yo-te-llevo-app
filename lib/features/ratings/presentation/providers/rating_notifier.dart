import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';

/// StateNotifier de envío de calificación (spec §8.3).
///
/// Estado: `AsyncValue<void>`. Al éxito queda en `data(null)`; al error
/// queda en `error(message)`. La UI escucha para mostrar SnackBar y navegar
/// al cerrar la pantalla.
class RatingNotifier extends StateNotifier<AsyncValue<void>> {
  final RatingRepository _ratingRepo;
  final ProfileRepository _profileRepo;
  final String _matchId;
  final Uuid _uuid;

  RatingNotifier(
    this._ratingRepo,
    this._profileRepo,
    this._matchId, {
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        super(const AsyncValue.data(null));

  /// Retorna `true` si la calificación se persistió y el perfil del
  /// destinatario fue recalculado correctamente.
  ///
  /// Valida (§8.3):
  /// - `stars` en rango 1..5.
  /// - `fromUserId != toUserId` (no auto-calificación).
  /// - `hasRated == false` para bloquear duplicados (client-side).
  Future<bool> submit({
    required String fromUserId,
    required String toUserId,
    required int stars,
    String? comment,
  }) async {
    if (stars < 1 || stars > 5) {
      state = AsyncValue.error(
        'La calificación debe estar entre 1 y 5 estrellas',
        StackTrace.current,
      );
      return false;
    }

    if (fromUserId == toUserId) {
      state = AsyncValue.error(
        'No puedes calificarte a ti mismo',
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncValue.loading();

    final alreadyRated = await _ratingRepo.hasRated(
      fromUserId: fromUserId,
      matchId: _matchId,
    );
    final duplicate = alreadyRated.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return true;
      },
      (value) => value,
    );
    if (duplicate) {
      if (alreadyRated.isRight()) {
        // `hasRated` respondió correctamente con `true`.
        state = AsyncValue.error(
          'Ya calificaste este viaje',
          StackTrace.current,
        );
      }
      return false;
    }

    final trimmed = comment?.trim();
    final rating = RatingEntity(
      id: _uuid.v4(),
      fromUserId: fromUserId,
      toUserId: toUserId,
      matchId: _matchId,
      stars: stars,
      comment: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      createdAt: DateTime.now(),
    );

    final submitResult = await _ratingRepo.submitRating(rating);
    if (_isLeft(submitResult)) return false;

    // Recálculo cliente-side del promedio + totalTrips (spec §8.2). Spec
    // marca como aceptable en MVP; deuda explícita de moverlo a Cloud
    // Function está registrada en yo-te-llevo-pending.md.
    final ratingsResult = await _ratingRepo.getRatingsForUser(toUserId);
    final ratings = ratingsResult.fold<List<RatingEntity>?>(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (list) => list,
    );
    if (ratings == null) return false;

    final newAverage = _averageStars(ratings);

    final userResult = await _profileRepo.getUser(toUserId);
    final user = userResult.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (value) => value,
    );
    if (user == null) return false;

    final updated = user.copyWith(
      rating: newAverage,
      totalTrips: user.totalTrips + 1,
    );
    final updateResult = await _profileRepo.updateUser(updated);
    if (_isLeft(updateResult)) return false;

    state = const AsyncValue.data(null);
    return true;
  }

  bool _isLeft(Either<Failure, void> result) {
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return true;
      },
      (_) => false,
    );
  }

  double _averageStars(List<RatingEntity> ratings) {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold<int>(0, (sum, r) => sum + r.stars);
    return total / ratings.length;
  }
}
