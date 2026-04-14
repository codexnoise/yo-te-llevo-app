import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/lat_lng.dart';
import '../providers/create_route_state.dart';
import '../providers/driver_route_providers.dart';

enum MapSelectionMode { origin, destination }

class RouteMapWidget extends ConsumerStatefulWidget {
  const RouteMapWidget({super.key});

  @override
  ConsumerState<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends ConsumerState<RouteMapWidget> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PolylineAnnotationManager? _polylineManager;
  mapbox.PointAnnotationManager? _pointManager;
  MapSelectionMode _selectionMode = MapSelectionMode.origin;

  // Default center: Ecuador
  static final _defaultCenter = mapbox.Point(
    coordinates: mapbox.Position(-78.4678, -0.1807),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRouteNotifierProvider);

    ref.listen<CreateRouteState>(createRouteNotifierProvider,
        (prev, next) {
      if (prev?.routeResult != next.routeResult ||
          prev?.origin != next.origin ||
          prev?.destination != next.destination) {
        _updateAnnotations(next);
      }
    });

    return Column(
      children: [
        _buildModeSelector(),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: mapbox.MapWidget(
              cameraOptions: mapbox.CameraOptions(
                center: _defaultCenter,
                zoom: 12,
              ),
              onMapCreated: _onMapCreated,
              onTapListener: _onMapTap,
            ),
          ),
        ),
        if (state.isLoadingRoute)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Origen',
              icon: Icons.trip_origin,
              color: AppColors.pickupMarker,
              isSelected: _selectionMode == MapSelectionMode.origin,
              onTap: () =>
                  setState(() => _selectionMode = MapSelectionMode.origin),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeButton(
              label: 'Destino',
              icon: Icons.location_on,
              color: AppColors.dropoffMarker,
              isSelected: _selectionMode == MapSelectionMode.destination,
              onTap: () => setState(
                  () => _selectionMode = MapSelectionMode.destination),
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
    _pointManager = await map.annotations.createPointAnnotationManager();

    final state = ref.read(createRouteNotifierProvider);
    if (state.origin != null || state.destination != null) {
      _updateAnnotations(state);
    }
  }

  void _onMapTap(mapbox.MapContentGestureContext context) {
    final point = context.point;
    final latLng = LatLng(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );

    final notifier = ref.read(createRouteNotifierProvider.notifier);
    if (_selectionMode == MapSelectionMode.origin) {
      notifier.setOrigin(latLng);
      setState(() => _selectionMode = MapSelectionMode.destination);
    } else {
      notifier.setDestination(latLng);
    }
  }

  Future<void> _updateAnnotations(CreateRouteState state) async {
    if (_mapboxMap == null) return;

    // Clear existing annotations
    await _polylineManager?.deleteAll();
    await _pointManager?.deleteAll();

    // Draw polyline
    if (state.routeResult != null &&
        state.routeResult!.polylineDecoded.length >= 2) {
      final points = state.routeResult!.polylineDecoded
          .map((p) => mapbox.Point(
              coordinates: mapbox.Position(p.longitude, p.latitude)))
          .toList();

      await _polylineManager?.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: points.map((p) => p.coordinates).toList()),
        lineColor: AppColors.routePolyline.toARGB32(),
        lineWidth: 4,
      ));
    }

    // Add origin marker
    if (state.origin != null) {
      await _addMarker(state.origin!, AppColors.pickupMarker);
    }

    // Add destination marker
    if (state.destination != null) {
      await _addMarker(state.destination!, AppColors.dropoffMarker);
    }

    // Fit camera to bounds
    _fitBounds(state);
  }

  Future<void> _addMarker(LatLng point, Color color) async {
    await _pointManager?.create(mapbox.PointAnnotationOptions(
      geometry: mapbox.Point(
        coordinates: mapbox.Position(point.longitude, point.latitude),
      ),
      iconSize: 1.5,
      iconColor: color.toARGB32(),
      textField: color == AppColors.pickupMarker ? 'A' : 'B',
      textSize: 12,
      textColor: Colors.white.toARGB32(),
    ));
  }

  void _fitBounds(CreateRouteState state) {
    if (state.origin == null && state.destination == null) return;

    final points = <LatLng>[
      if (state.origin != null) state.origin!,
      if (state.destination != null) state.destination!,
    ];

    if (points.length == 1) {
      _mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates:
                mapbox.Position(points[0].longitude, points[0].latitude),
          ),
          zoom: 14,
        ),
        mapbox.MapAnimationOptions(duration: 500),
      );
      return;
    }

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

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
