import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/ratings/data/models/rating_model.dart';

void main() {
  group('RatingModel.fromMap', () {
    test('parses a full rating document', () {
      final data = {
        RatingModel.fFromUserId: 'u1',
        RatingModel.fToUserId: 'u2',
        RatingModel.fMatchId: 'm1',
        RatingModel.fStars: 4,
        RatingModel.fComment: 'Excelente conductor',
        RatingModel.fCreatedAt: Timestamp.fromDate(DateTime(2026, 4, 15)),
      };

      final model = RatingModel.fromMap('r1', data);

      expect(model.id, 'r1');
      expect(model.fromUserId, 'u1');
      expect(model.toUserId, 'u2');
      expect(model.matchId, 'm1');
      expect(model.stars, 4);
      expect(model.comment, 'Excelente conductor');
      expect(model.createdAt, DateTime(2026, 4, 15));
    });

    test('tolerates null comment', () {
      final model = RatingModel.fromMap('r1', {
        RatingModel.fFromUserId: 'u1',
        RatingModel.fToUserId: 'u2',
        RatingModel.fMatchId: 'm1',
        RatingModel.fStars: 5,
        RatingModel.fComment: null,
        RatingModel.fCreatedAt: Timestamp.fromDate(DateTime(2026, 4, 15)),
      });

      expect(model.comment, isNull);
    });

    test('fallbacks for missing fields', () {
      final model = RatingModel.fromMap('r1', {});

      expect(model.fromUserId, '');
      expect(model.toUserId, '');
      expect(model.matchId, '');
      expect(model.stars, 0);
      expect(model.comment, isNull);
    });
  });

  group('RatingModel.toFirestore', () {
    test('serializes without server timestamp for tests', () {
      final model = RatingModel(
        id: 'r1',
        fromUserId: 'u1',
        toUserId: 'u2',
        matchId: 'm1',
        stars: 3,
        createdAt: DateTime(2026, 4, 15, 12, 30),
        comment: 'ok',
      );

      final map = model.toFirestore(useServerTimestamp: false);

      expect(map[RatingModel.fFromUserId], 'u1');
      expect(map[RatingModel.fToUserId], 'u2');
      expect(map[RatingModel.fMatchId], 'm1');
      expect(map[RatingModel.fStars], 3);
      expect(map[RatingModel.fComment], 'ok');
      expect(map[RatingModel.fCreatedAt], isA<Timestamp>());
    });

    test('serializes with server timestamp by default', () {
      final model = RatingModel(
        id: 'r1',
        fromUserId: 'u1',
        toUserId: 'u2',
        matchId: 'm1',
        stars: 5,
        createdAt: DateTime(2026, 4, 15),
      );

      final map = model.toFirestore();

      expect(map[RatingModel.fCreatedAt], isA<FieldValue>());
    });
  });

  test('round-trip fromMap ↔ toFirestore preserves content', () {
    final original = RatingModel(
      id: 'r1',
      fromUserId: 'u1',
      toUserId: 'u2',
      matchId: 'm1',
      stars: 2,
      createdAt: DateTime(2026, 4, 15, 9, 0),
      comment: 'comentario',
    );

    final map = original.toFirestore(useServerTimestamp: false);
    final restored = RatingModel.fromMap('r1', map);

    expect(restored, original);
  });

  test('fromEntity and toEntity are symmetric', () {
    final model = RatingModel(
      id: 'r1',
      fromUserId: 'u1',
      toUserId: 'u2',
      matchId: 'm1',
      stars: 5,
      createdAt: DateTime(2026, 4, 15),
      comment: 'top',
    );

    final entity = model.toEntity();
    final back = RatingModel.fromEntity(entity);

    expect(back, model);
  });
}
