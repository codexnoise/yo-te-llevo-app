import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/profile/presentation/providers/profile_providers.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    NotificationService.instance.attachRouter(router);

    ref.listen(authStateProvider, (previous, next) {
      final uid = next.valueOrNull?.uid;
      if (uid != null && uid != _lastUserId) {
        _lastUserId = uid;
        NotificationService.instance.registerForUser(
          uid,
          ref.read(profileRepositoryProvider),
        );
      } else if (uid == null && _lastUserId != null) {
        final outgoing = _lastUserId!;
        _lastUserId = null;
        NotificationService.instance.clearForUser(outgoing);
      }
    });

    return MaterialApp.router(
      title: 'Yo Te Llevo',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
