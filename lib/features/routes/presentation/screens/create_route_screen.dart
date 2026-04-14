import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/create_route_state.dart';
import '../providers/driver_route_providers.dart';
import '../widgets/location_search_bar.dart';
import '../widgets/route_config_form.dart';
import '../widgets/route_map_widget.dart';
import '../widgets/route_preview_card.dart';

class CreateRouteScreen extends ConsumerStatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  ConsumerState<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends ConsumerState<CreateRouteScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRouteNotifierProvider);

    ref.listen<CreateRouteState>(createRouteNotifierProvider, (prev, next) {
      if (next.isRouteCreated && !(prev?.isRouteCreated ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta creada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPage == 0 ? 'Nueva Ruta - Mapa' : 'Nueva Ruta - Configurar'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildMapPage(state),
          _buildConfigPage(state),
        ],
      ),
    );
  }

  Widget _buildMapPage(CreateRouteState state) {
    final notifier = ref.read(createRouteNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LocationSearchBar(
            label: 'Origen',
            initialValue: state.originAddress,
            onResultSelected: notifier.setOriginFromSearch,
          ),
          const SizedBox(height: 8),
          LocationSearchBar(
            label: 'Destino',
            initialValue: state.destinationAddress,
            onResultSelected: notifier.setDestinationFromSearch,
          ),
          const SizedBox(height: 8),
          const Expanded(child: RouteMapWidget()),
          if (state.hasRoute) ...[
            const SizedBox(height: 8),
            RoutePreviewCard(
              routeResult: state.routeResult!,
              originAddress: state.originAddress,
              destinationAddress: state.destinationAddress,
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.hasRoute
                  ? () => _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                  : null,
              child: const Text('Siguiente'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigPage(CreateRouteState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.hasRoute)
            RoutePreviewCard(
              routeResult: state.routeResult!,
              originAddress: state.originAddress,
              destinationAddress: state.destinationAddress,
            ),
          const SizedBox(height: 16),
          const RouteConfigForm(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: const Text('Volver al mapa'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isSaving
                      ? null
                      : () => ref
                          .read(createRouteNotifierProvider.notifier)
                          .saveRoute(),
                  child: state.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar Ruta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
