import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/haversine.dart';
import '../../../../core/utils/lat_lng.dart';
import '../../../../core/utils/polyline_codec.dart';
import '../../../../core/utils/polyline_utils.dart';
import '../../../routes/domain/entities/detour_result.dart';
import '../../../routes/domain/entities/route_entity.dart';
import '../../../routes/domain/repositories/driver_route_repository.dart';
import '../../../routes/domain/repositories/mapbox_repository.dart';
import '../../domain/entities/match_candidate.dart';
import '../../domain/entities/match_search_input.dart';

/// Intermediate result of phase 2 — geoespacialmente viable, pendiente de
/// verificación de desvío con Mapbox en phase 3.
class Phase2Result {
  final RouteEntity route;
  final List<LatLng> polyline;
  final NearestPointResult pickup;
  final NearestPointResult dropoff;

  const Phase2Result({
    required this.route,
    required this.polyline,
    required this.pickup,
    required this.dropoff,
  });
}

class MatchingEngine {
  final DriverRouteRepository _routeRepo;
  final MapboxRepository _mapboxRepo;
  final int phase3ChunkSize;

  MatchingEngine(
    this._routeRepo,
    this._mapboxRepo, {
    this.phase3ChunkSize = 5,
  });

  List<RouteEntity> phase1Filter(
    List<RouteEntity> routes,
    MatchSearchInput input,
  ) {
    return routes.where((route) => _passesPhase1(route, input)).toList();
  }

  bool _passesPhase1(RouteEntity route, MatchSearchInput input) {
    if (!route.isActive) return false;
    if (route.availableSeats <= 0) return false;

    final dayMatch = route.schedule.days.any(input.days.contains);
    if (!dayMatch) return false;

    const threshold = AppConstants.haversineFilterMeters;

    final originNearRoute =
        haversineDistance(input.origin, route.origin) <= threshold ||
            haversineDistance(input.origin, route.destination) <= threshold;
    if (!originNearRoute) return false;

    final destinationNearRoute =
        haversineDistance(input.destination, route.origin) <= threshold ||
            haversineDistance(input.destination, route.destination) <= threshold;
    if (!destinationNearRoute) return false;

    return true;
  }

  Future<List<Phase2Result>> phase2Polyline(
    List<RouteEntity> routes,
    MatchSearchInput input,
  ) async {
    final results = <Phase2Result>[];

    for (final route in routes) {
      final polyline = await _resolvePolyline(route);
      if (polyline == null || polyline.length < 2) continue;

      final pickup = nearestPointOnPolyline(input.origin, polyline);
      if (pickup.distance > AppConstants.toleranceRadiusMeters) continue;

      final dropoff = nearestPointOnPolyline(input.destination, polyline);
      if (dropoff.distance > AppConstants.toleranceRadiusMeters) continue;

      if (!isCorrectDirection(pickup.segmentIndex, dropoff.segmentIndex)) {
        continue;
      }

      results.add(Phase2Result(
        route: route,
        polyline: polyline,
        pickup: pickup,
        dropoff: dropoff,
      ));
    }

    return results;
  }

  Future<List<LatLng>?> _resolvePolyline(RouteEntity route) async {
    final cached = _mapboxRepo.getCachedPolyline(route.id);
    final cachedValue = cached.fold((_) => null, (s) => s);
    if (cachedValue != null && cachedValue.isNotEmpty) {
      return PolylineCodec.decode(cachedValue);
    }

    if (route.polylinePoints.isNotEmpty) {
      return route.polylinePoints;
    }

    final fetched = await _mapboxRepo.getRoute([route.origin, route.destination]);
    return fetched.fold((_) => null, (r) {
      _mapboxRepo.cachePolyline(route.id, r.polylineEncoded);
      return r.polylineDecoded;
    });
  }

  Future<List<MatchCandidate>> phase3Detour(
    List<Phase2Result> phase2Results,
  ) async {
    final candidates = <MatchCandidate>[];

    for (var i = 0; i < phase2Results.length; i += phase3ChunkSize) {
      final chunk = phase2Results.skip(i).take(phase3ChunkSize).toList();
      final chunkResults = await Future.wait(
        chunk.map(_buildCandidateSafe),
      );
      candidates.addAll(chunkResults.whereType<MatchCandidate>());
    }

    return candidates;
  }

  Future<MatchCandidate?> _buildCandidateSafe(Phase2Result p2) async {
    try {
      final detourFuture = _mapboxRepo.calculateDetour(
        driverOrigin: p2.route.origin,
        driverDestination: p2.route.destination,
        passengerPickup: p2.pickup.point,
        passengerDropoff: p2.dropoff.point,
        originalDurationSeconds: p2.route.durationSeconds,
        originalDistanceMeters: p2.route.distanceMeters,
      );
      final pickupAddressFuture = _mapboxRepo.reverseGeocode(p2.pickup.point);
      final dropoffAddressFuture = _mapboxRepo.reverseGeocode(p2.dropoff.point);

      final results = await Future.wait([
        detourFuture,
        pickupAddressFuture,
        dropoffAddressFuture,
      ]);

      final detourEither = results[0] as dynamic;
      final pickupAddrEither = results[1] as dynamic;
      final dropoffAddrEither = results[2] as dynamic;

      final detour = detourEither.fold((_) => null, (d) => d as DetourResult);
      if (detour == null) return null;
      if (detour.extraSeconds > AppConstants.maxDetourSeconds) return null;

      final pickupAddress = pickupAddrEither.fold(
        (_) => '',
        (s) => s as String,
      );
      final dropoffAddress = dropoffAddrEither.fold(
        (_) => '',
        (s) => s as String,
      );

      return MatchCandidate(
        route: p2.route,
        pickupPoint: p2.pickup.point,
        pickupAddress: pickupAddress,
        dropoffPoint: p2.dropoff.point,
        dropoffAddress: dropoffAddress,
        distanceToPickupMeters: p2.pickup.distance,
        distanceToDropoffMeters: p2.dropoff.distance,
        detourSeconds: detour.extraSeconds,
        detourMeters: detour.extraMeters,
        fullRouteWithDetour: detour.fullRoute.polylineDecoded,
        price: p2.route.pricing.amount,
        pricingType: p2.route.pricing.type,
      );
    } catch (_) {
      return null;
    }
  }

  List<MatchCandidate> rank(List<MatchCandidate> candidates) {
    final sorted = [...candidates];
    sorted.sort((a, b) {
      final byPickup = a.distanceToPickupMeters.compareTo(b.distanceToPickupMeters);
      if (byPickup != 0) return byPickup;
      final byDetour = a.detourSeconds.compareTo(b.detourSeconds);
      if (byDetour != 0) return byDetour;
      return a.price.compareTo(b.price);
    });
    return sorted;
  }

  Future<List<MatchCandidate>> run(
    List<RouteEntity> phase0Routes,
    MatchSearchInput input,
  ) async {
    if (phase0Routes.isEmpty) return const [];

    final phase1 = phase1Filter(phase0Routes, input);
    if (phase1.isEmpty) return const [];

    final phase2 = await phase2Polyline(phase1, input);
    if (phase2.isEmpty) return const [];

    final phase3 = await phase3Detour(phase2);
    if (phase3.isEmpty) return const [];

    return rank(phase3);
  }

  DriverRouteRepository get routeRepo => _routeRepo;
}
