import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/connectivity_provider.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/rating_remote_datasource.dart';
import '../../data/repositories/rating_repository_impl.dart';
import '../../domain/repositories/rating_repository.dart';
import 'rating_notifier.dart';

final ratingRemoteDataSourceProvider = Provider<RatingRemoteDataSource>((ref) {
  return RatingRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepositoryImpl(
    remote: ref.watch(ratingRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

/// Notifier por matchId. Familia para que múltiples pantallas de rating
/// abiertas (edge case) no compartan estado de envío.
final ratingNotifierProvider = StateNotifierProvider.autoDispose
    .family<RatingNotifier, AsyncValue<void>, String>((ref, matchId) {
  return RatingNotifier(
    ref.watch(ratingRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    matchId,
  );
});

/// Check rápido para saber si el usuario actual ya calificó este match.
/// Bloquea el envío en UI antes de que el usuario llene el formulario.
final hasRatedProvider = FutureProvider.autoDispose.family<bool, ({
  String matchId,
  String fromUserId,
})>((ref, params) async {
  final repo = ref.watch(ratingRepositoryProvider);
  final result = await repo.hasRated(
    fromUserId: params.fromUserId,
    matchId: params.matchId,
  );
  // En caso de fallo de red/permisos, asumimos `false` para no bloquear la
  // UX; el datasource se encargará de rechazar el duplicado al enviar.
  return result.fold((_) => false, (value) => value);
});

/// Perfil del usuario a calificar. Encapsula el `getUser` del
/// ProfileRepository para leerlo cómodamente desde `RatingScreen`.
final ratedUserProvider =
    FutureProvider.autoDispose.family<UserEntity?, String>((ref, userId) async {
  final result = await ref.watch(profileRepositoryProvider).getUser(userId);
  return result.fold((_) => null, (user) => user);
});
