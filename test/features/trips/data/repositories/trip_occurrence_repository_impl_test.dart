import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:yo_te_llevo/core/errors/exceptions.dart';
import 'package:yo_te_llevo/core/errors/failures.dart';
import 'package:yo_te_llevo/core/network/network_info.dart';
import 'package:yo_te_llevo/core/utils/lat_lng.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match.dart';
import 'package:yo_te_llevo/features/matching/domain/entities/match_status.dart';
import 'package:yo_te_llevo/features/trips/data/datasources/trip_occurrence_firestore_ds.dart';
import 'package:yo_te_llevo/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:yo_te_llevo/features/trips/data/repositories/trip_occurrence_repository_impl.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/cancel_scope.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/match_series_status.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/occurrence_status.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/trip_occurrence.dart';

class MockOccurrenceDs extends Mock implements TripOccurrenceRemoteDataSource {}

class MockMatchDs extends Mock implements TripRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class _FakeOccurrence extends Fake implements TripOccurrence {}

Match _match({
  MatchTripType tripType = MatchTripType.recurring,
  MatchSeriesStatus? seriesStatus = MatchSeriesStatus.active,
  String pricingType = 'weekly',
  double price = 10.0,
  String? departureTime = '07:30',
  List<String> days = const ['mon', 'wed'],
  DateTime? startDate,
}) {
  return Match(
    id: 'm1',
    passengerId: 'p1',
    driverId: 'd1',
    routeId: 'r1',
    status: MatchStatus.accepted,
    pickupPoint: const LatLng(0, 0),
    pickupAddress: 'pickup',
    dropoffPoint: const LatLng(0, 0.03),
    dropoffAddress: 'dropoff',
    distanceToPickupMeters: 100,
    distanceToDropoffMeters: 200,
    detourSeconds: 60,
    tripType: tripType,
    days: days,
    startDate: startDate,
    price: price,
    pricingType: pricingType,
    createdAt: DateTime.utc(2026, 4, 26),
    seriesStatus: seriesStatus,
    departureTime: departureTime,
    timezone: 'America/Guayaquil',
  );
}

TripOccurrence _occurrence({
  String id = 'm1_202604271230',
  OccurrenceStatus status = OccurrenceStatus.scheduled,
  DateTime? scheduledAt,
}) {
  return TripOccurrence(
    id: id,
    matchId: 'm1',
    passengerId: 'p1',
    driverId: 'd1',
    routeId: 'r1',
    scheduledAt: scheduledAt ?? DateTime.utc(2026, 4, 27, 12, 30),
    status: status,
    tripType: MatchTripType.recurring,
    createdAt: DateTime.utc(2026, 4, 26),
    priceCents: 1000,
    remindersSent: const OccurrenceReminders(),
    timezone: 'America/Guayaquil',
  );
}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(_FakeOccurrence());
    registerFallbackValue(OccurrenceStatus.scheduled);
    registerFallbackValue(MatchSeriesStatus.active);
    registerFallbackValue(CancelScope.occurrence);
  });

  late MockOccurrenceDs occurrenceDs;
  late MockMatchDs matchDs;
  late MockNetworkInfo network;
  late TripOccurrenceRepositoryImpl repo;

  setUp(() {
    occurrenceDs = MockOccurrenceDs();
    matchDs = MockMatchDs();
    network = MockNetworkInfo();
    repo = TripOccurrenceRepositoryImpl(
      remote: occurrenceDs,
      matchRemote: matchDs,
      networkInfo: network,
    );
    when(() => network.isConnected).thenAnswer((_) async => true);
  });

  group('seedInitialOccurrences', () {
    test('genera 2 ocurrencias para serie recurring activa', () async {
      when(() => matchDs.getMatch('m1')).thenAnswer(
        (_) async => _match(
          startDate: DateTime.utc(2026, 4, 27, 0),
        ),
      );
      when(() => occurrenceDs.createOccurrence(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as TripOccurrence,
      );

      final result = await repo.seedInitialOccurrences('m1');

      expect(result, isA<Right<Failure, List<TripOccurrence>>>());
      result.fold(
        (_) => fail('expected right'),
        (list) => expect(list, hasLength(2)),
      );
      verify(() => occurrenceDs.createOccurrence(any())).called(2);
    });

    test('weekly: la 2da ocurrencia del mismo ciclo cobra 0', () async {
      when(() => matchDs.getMatch('m1')).thenAnswer(
        (_) async => _match(
          startDate: DateTime.utc(2026, 4, 27, 0),
          pricingType: 'weekly',
          price: 10,
        ),
      );
      final captured = <TripOccurrence>[];
      when(() => occurrenceDs.createOccurrence(any())).thenAnswer((inv) async {
        final o = inv.positionalArguments.first as TripOccurrence;
        captured.add(o);
        return o;
      });

      await repo.seedInitialOccurrences('m1');

      expect(captured, hasLength(2));
      expect(captured[0].priceCents, 1000); // primer lunes
      expect(captured[1].priceCents, 0); // miércoles misma semana
    });

    test('genera 1 ocurrencia para tripType=oneTime', () async {
      when(() => matchDs.getMatch('m1')).thenAnswer(
        (_) async => _match(
          tripType: MatchTripType.oneTime,
          seriesStatus: null,
          startDate: DateTime.utc(2026, 4, 27, 12),
          pricingType: 'perTrip',
        ),
      );
      when(() => occurrenceDs.createOccurrence(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as TripOccurrence,
      );

      final result = await repo.seedInitialOccurrences('m1');
      result.fold(
        (_) => fail('expected right'),
        (list) => expect(list, hasLength(1)),
      );
    });
  });

  group('cancel', () {
    test('scope=occurrence solo actualiza la ocurrencia', () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenAnswer(
        (_) async => _occurrence(),
      );
      when(() => occurrenceDs.updateStatus(
            any(),
            next: any(named: 'next'),
            cancelledBy: any(named: 'cancelledBy'),
            cancellationReason: any(named: 'cancellationReason'),
            cancelScope: any(named: 'cancelScope'),
          )).thenAnswer((_) async {});

      final result = await repo.cancel(
        'o1',
        scope: CancelScope.occurrence,
        byUserId: 'p1',
      );

      expect(result.isRight(), isTrue);
      verify(() => occurrenceDs.updateStatus(
            'o1',
            next: OccurrenceStatus.cancelled,
            cancelledBy: 'p1',
            cancellationReason: null,
            cancelScope: CancelScope.occurrence,
          )).called(1);
      verifyNever(() => occurrenceDs.cancelSeriesBatch(
            any(),
            byUserId: any(named: 'byUserId'),
            reason: any(named: 'reason'),
          ));
    });

    test('scope=series además invoca cancelSeriesBatch', () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenAnswer(
        (_) async => _occurrence(),
      );
      when(() => occurrenceDs.updateStatus(
            any(),
            next: any(named: 'next'),
            cancelledBy: any(named: 'cancelledBy'),
            cancellationReason: any(named: 'cancellationReason'),
            cancelScope: any(named: 'cancelScope'),
          )).thenAnswer((_) async {});
      when(() => occurrenceDs.cancelSeriesBatch(
            any(),
            byUserId: any(named: 'byUserId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      final result = await repo.cancel(
        'o1',
        scope: CancelScope.series,
        byUserId: 'p1',
      );

      expect(result.isRight(), isTrue);
      verify(() => occurrenceDs.cancelSeriesBatch(
            'm1',
            byUserId: 'p1',
            reason: null,
          )).called(1);
    });

    test('rechaza cancelar si la ocurrencia ya está completed', () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenAnswer(
        (_) async => _occurrence(status: OccurrenceStatus.completed),
      );

      final result = await repo.cancel(
        'o1',
        scope: CancelScope.occurrence,
        byUserId: 'p1',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('completeOccurrence', () {
    test('exitoso: actualiza status y materializa siguiente para recurring',
        () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenAnswer(
        (_) async => _occurrence(status: OccurrenceStatus.active),
      );
      when(() => occurrenceDs.updateStatus(
            any(),
            next: any(named: 'next'),
            cancelledBy: any(named: 'cancelledBy'),
            cancellationReason: any(named: 'cancellationReason'),
            cancelScope: any(named: 'cancelScope'),
          )).thenAnswer((_) async {});
      when(() => matchDs.getMatch('m1')).thenAnswer((_) async => _match());
      when(() => occurrenceDs.getFutureScheduledOf('m1'))
          .thenAnswer((_) async => const []);
      when(() => occurrenceDs.createOccurrence(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as TripOccurrence,
      );

      final result = await repo.completeOccurrence('o1');

      expect(result.isRight(), isTrue);
      verify(() => occurrenceDs.createOccurrence(any())).called(1);
    });

    test('rechaza si la ocurrencia no está active', () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenAnswer(
        (_) async => _occurrence(status: OccurrenceStatus.scheduled),
      );

      final result = await repo.completeOccurrence('o1');

      expect(result.isLeft(), isTrue);
      verifyNever(() => occurrenceDs.updateStatus(
            any(),
            next: any(named: 'next'),
          ));
    });

    test('para serie pausada no genera siguiente', () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenAnswer(
        (_) async => _occurrence(status: OccurrenceStatus.active),
      );
      when(() => occurrenceDs.updateStatus(
            any(),
            next: any(named: 'next'),
            cancelledBy: any(named: 'cancelledBy'),
            cancellationReason: any(named: 'cancellationReason'),
            cancelScope: any(named: 'cancelScope'),
          )).thenAnswer((_) async {});
      when(() => matchDs.getMatch('m1')).thenAnswer(
        (_) async => _match(seriesStatus: MatchSeriesStatus.paused),
      );

      final result = await repo.completeOccurrence('o1');

      expect(result.isRight(), isTrue);
      verifyNever(() => occurrenceDs.createOccurrence(any()));
    });
  });

  group('startOccurrence', () {
    test('rechaza transición scheduled → completed (debe pasar por active)',
        () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenAnswer(
        (_) async => _occurrence(status: OccurrenceStatus.cancelled),
      );

      final result = await repo.startOccurrence('o1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('offline', () {
    test('cancel devuelve NetworkFailure si no hay red', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      final result = await repo.cancel(
        'o1',
        scope: CancelScope.occurrence,
        byUserId: 'p1',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('expected left'),
      );
    });
  });

  group('exceptions del datasource se mapean', () {
    test('ServerException → ServerFailure', () async {
      when(() => occurrenceDs.getOccurrence('o1')).thenThrow(
        const ServerException(message: 'boom'),
      );
      final result = await repo.cancel(
        'o1',
        scope: CancelScope.occurrence,
        byUserId: 'p1',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected left'),
      );
    });
  });
}
