import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta un [Stream] a [Listenable] para usarlo como `refreshListenable`
/// de go_router. Notifica a los listeners cada vez que el stream emite.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
