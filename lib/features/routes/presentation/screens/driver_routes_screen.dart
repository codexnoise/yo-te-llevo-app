import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/driver_route_providers.dart';
import '../widgets/route_card.dart';

class DriverRoutesScreen extends ConsumerWidget {
  const DriverRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(driverRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Rutas')),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(driverRoutesProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (routes) {
          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes rutas registradas',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create-route'),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear ruta'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(driverRoutesProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return RouteCard(
                  route: route,
                  onDeactivate: () => _confirmDeactivate(
                    context,
                    ref,
                    route.id,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-route'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeactivate(
      BuildContext context, WidgetRef ref, String routeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar ruta'),
        content: const Text(
            '¿Estás seguro de que deseas desactivar esta ruta? '
            'Ya no estará disponible para pasajeros.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(driverRoutesProvider.notifier)
                  .deactivateRoute(routeId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }
}
