import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Claves de feature flags servidas vía Firebase Remote Config.
class FeatureFlagKeys {
  FeatureFlagKeys._();

  /// Activa el flujo de viajes recurrentes (`TripOccurrence`, UI de próximas
  /// ocurrencias, cancelación con scope). Default: `false`.
  static const String recurringTripsEnabled = 'recurring_trips_enabled';
}

/// Wrapper sobre [FirebaseRemoteConfig]. Expone lecturas tipadas y oculta el
/// ciclo de vida (init, defaults, fetchAndActivate). Diseñado para ser
/// inyectado vía Riverpod.
class FeatureFlags {
  FeatureFlags(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  /// Inicializa Remote Config con defaults y settings sensatos para debug
  /// vs release. Debe llamarse una vez al arranque de la app, después de
  /// `Firebase.initializeApp()`.
  static Future<FeatureFlags> initialize() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval:
          kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));
    await rc.setDefaults(const {
      FeatureFlagKeys.recurringTripsEnabled: false,
    });
    try {
      await rc.fetchAndActivate();
    } catch (_) {
      // Sin red: trabajamos con defaults. No bloqueamos el arranque.
    }
    return FeatureFlags(rc);
  }

  bool get recurringTripsEnabled =>
      _remoteConfig.getBool(FeatureFlagKeys.recurringTripsEnabled);

  /// Permite forzar refresh manual desde pantallas de debug.
  Future<bool> refresh() => _remoteConfig.fetchAndActivate();

  /// Stream que emite cuando Remote Config recibe nuevos valores en tiempo
  /// real (Realtime Remote Config). Útil para que la UI reaccione sin
  /// reiniciar la app.
  Stream<RemoteConfigUpdate> get updates => _remoteConfig.onConfigUpdated;
}

/// Provider Riverpod. Se inyecta en `ProviderScope.overrides` desde `main`
/// con la instancia ya inicializada — antes del primer `runApp`.
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  throw UnimplementedError(
    'featureFlagsProvider debe ser overrideado con FeatureFlags.initialize() '
    'desde main.dart antes de runApp().',
  );
});

/// Conveniencia: lee el flag de viajes recurrentes y se rebuild cuando
/// Remote Config emite update en tiempo real.
final recurringTripsEnabledProvider = StreamProvider<bool>((ref) async* {
  final flags = ref.watch(featureFlagsProvider);
  yield flags.recurringTripsEnabled;
  await for (final _ in flags.updates) {
    yield flags.recurringTripsEnabled;
  }
});
