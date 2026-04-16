import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../routes/presentation/providers/driver_route_providers.dart';
import '../../data/datasources/trip_remote_datasource.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import 'trips_notifier.dart';

final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>((ref) {
  return TripRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(
    remote: ref.watch(tripRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    routeRepository: ref.watch(driverRouteRepositoryProvider),
  );
});

/// Stream de viajes activos (pending/accepted/active) del usuario actual
/// en ambos roles. Deduplica y ordena por createdAt desc.
final activeTripsStreamProvider =
    StreamProvider.autoDispose<List<TripEntity>>((ref) async* {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    yield const [];
    return;
  }
  final repo = ref.watch(tripRepositoryProvider);
  await for (final Either<Failure, List<TripEntity>> event
      in repo.watchActiveTrips(user.id)) {
    yield event.fold(
      (failure) => throw StateError(failure.message),
      (trips) => trips,
    );
  }
});

/// Historial de viajes completados del usuario actual.
final tripHistoryProvider =
    FutureProvider.autoDispose<List<TripEntity>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const [];
  final repo = ref.watch(tripRepositoryProvider);
  final result = await repo.getHistory(user.id);
  return result.fold(
    (failure) => throw StateError(failure.message),
    (trips) => trips,
  );
});

/// Stream de un viaje específico por id, para la pantalla de detalle.
final tripDetailStreamProvider =
    StreamProvider.autoDispose.family<TripEntity, String>((ref, matchId) async* {
  final repo = ref.watch(tripRepositoryProvider);
  await for (final Either<Failure, TripEntity> event
      in repo.watchTrip(matchId)) {
    yield event.fold(
      (failure) => throw StateError(failure.message),
      (trip) => trip,
    );
  }
});

/// Acciones sobre trips (request/respond/cancel/start/complete). La lista se
/// mantiene reactiva via [activeTripsStreamProvider].
final tripsNotifierProvider =
    StateNotifierProvider.autoDispose<TripsNotifier, AsyncValue<void>>((ref) {
  return TripsNotifier(ref.watch(tripRepositoryProvider));
});
