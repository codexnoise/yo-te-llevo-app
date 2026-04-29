import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/trip_occurrence_firestore_ds.dart';
import '../../data/repositories/trip_occurrence_repository_impl.dart';
import '../../domain/entities/trip_occurrence.dart';
import '../../domain/repositories/trip_occurrence_repository.dart';
import 'trips_providers.dart';
import 'occurrence_actions_notifier.dart';

final tripOccurrenceRemoteDsProvider =
    Provider<TripOccurrenceRemoteDataSource>((ref) {
  return TripOccurrenceFirestoreDataSource(ref.watch(firestoreProvider));
});

final tripOccurrenceRepositoryProvider = Provider<TripOccurrenceRepository>((ref) {
  return TripOccurrenceRepositoryImpl(
    remote: ref.watch(tripOccurrenceRemoteDsProvider),
    matchRemote: ref.watch(tripRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

/// Stream con las próximas ocurrencias del usuario actual (en cualquier
/// rol). Filtra `scheduledAt >= now` y limita a 10.
final upcomingOccurrencesProvider =
    StreamProvider.autoDispose<List<TripOccurrence>>((ref) async* {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    yield const [];
    return;
  }
  final repo = ref.watch(tripOccurrenceRepositoryProvider);
  await for (final Either<Failure, List<TripOccurrence>> event
      in repo.watchUpcoming(user.id)) {
    yield event.fold(
      (failure) => throw StateError(failure.message),
      (list) => list,
    );
  }
});

/// Stream de una ocurrencia específica por id, para la pantalla de detalle.
final occurrenceByIdProvider =
    StreamProvider.autoDispose.family<TripOccurrence, String>(
        (ref, occurrenceId) async* {
  final repo = ref.watch(tripOccurrenceRepositoryProvider);
  await for (final Either<Failure, TripOccurrence> event
      in repo.watchById(occurrenceId)) {
    yield event.fold(
      (failure) => throw StateError(failure.message),
      (o) => o,
    );
  }
});

/// Stream de todas las ocurrencias de una serie (ordenadas asc por
/// `scheduledAt`). Para `SeriesManagementScreen`.
final seriesOccurrencesProvider =
    StreamProvider.autoDispose.family<List<TripOccurrence>, String>(
        (ref, matchId) async* {
  final repo = ref.watch(tripOccurrenceRepositoryProvider);
  await for (final Either<Failure, List<TripOccurrence>> event
      in repo.watchBySeries(matchId)) {
    yield event.fold(
      (failure) => throw StateError(failure.message),
      (list) => list,
    );
  }
});

/// Acciones sobre ocurrencias y series. La lista en pantalla se mantiene
/// reactiva via los providers de arriba.
final occurrenceActionsProvider = StateNotifierProvider.autoDispose<
    OccurrenceActionsNotifier, AsyncValue<void>>((ref) {
  return OccurrenceActionsNotifier(ref.watch(tripOccurrenceRepositoryProvider));
});
