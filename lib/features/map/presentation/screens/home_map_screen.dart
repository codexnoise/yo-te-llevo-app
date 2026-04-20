import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../routes/domain/entities/route_entity.dart';
import '../../../routes/presentation/providers/driver_route_providers.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PolylineAnnotationManager? _polylineManager;
  List<RouteEntity> _lastPaintedRoutes = const [];

  // Centro por defecto: Cuenca, Ecuador.
  static final _defaultCenter = mapbox.Point(
    coordinates: mapbox.Position(-79.0045, -2.9001),
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isDriver = user?.isDriver ?? false;
    final isPassenger = user?.isPassenger ?? false;

    if (isDriver) {
      ref.listen<AsyncValue<List<RouteEntity>>>(driverRoutesProvider,
          (prev, next) {
        final routes = next.valueOrNull ?? const <RouteEntity>[];
        _paintRoutes(routes);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          mapbox.MapWidget(
            cameraOptions: mapbox.CameraOptions(
              center: _defaultCenter,
              zoom: 12,
            ),
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isDriver)
                  FloatingActionButton.extended(
                    heroTag: 'home-driver-routes',
                    onPressed: () => context.push('/driver-routes'),
                    backgroundColor: AppColors.secondary,
                    icon: const Icon(Icons.alt_route),
                    label: const Text('Mis rutas'),
                  ),
                if (isDriver && isPassenger) const SizedBox(height: 12),
                if (isPassenger)
                  FloatingActionButton.extended(
                    heroTag: 'home-search-trip',
                    onPressed: () => context.push('/search'),
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar viaje'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(mapbox.MapboxMap map) async {
    _mapboxMap = map;
    _polylineManager =
        await map.annotations.createPolylineAnnotationManager();

    final routes =
        ref.read(driverRoutesProvider).valueOrNull ?? const <RouteEntity>[];
    if (routes.isNotEmpty) {
      _paintRoutes(routes);
    }
  }

  Future<void> _paintRoutes(List<RouteEntity> routes) async {
    if (_polylineManager == null) return;
    if (identical(routes, _lastPaintedRoutes)) return;

    await _polylineManager!.deleteAll();

    for (final route in routes) {
      if (route.polylinePoints.length < 2) continue;
      final coords = route.polylinePoints
          .map((p) => mapbox.Position(p.longitude, p.latitude))
          .toList();
      await _polylineManager!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: coords),
        lineColor: AppColors.routePolyline.toARGB32(),
        lineWidth: 4,
      ));
    }

    _lastPaintedRoutes = routes;
    _fitToRoutes(routes);
  }

  void _fitToRoutes(List<RouteEntity> routes) {
    final points = routes.expand((r) => r.polylinePoints).toList();
    if (points.isEmpty) return;

    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    _mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            (minLng + maxLng) / 2,
            (minLat + maxLat) / 2,
          ),
        ),
        zoom: 11,
      ),
      mapbox.MapAnimationOptions(duration: 500),
    );
  }

}
