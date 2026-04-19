import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/rating.dart';

/// Serialización Firestore para un [RatingEntity] en `/ratings/{ratingId}`
/// (spec §8.1).
class RatingModel extends RatingEntity {
  static const String fFromUserId = 'fromUserId';
  static const String fToUserId = 'toUserId';
  static const String fMatchId = 'matchId';
  static const String fStars = 'stars';
  static const String fComment = 'comment';
  static const String fCreatedAt = 'createdAt';

  const RatingModel({
    required super.id,
    required super.fromUserId,
    required super.toUserId,
    required super.matchId,
    required super.stars,
    required super.createdAt,
    super.comment,
  });

  factory RatingModel.fromEntity(RatingEntity entity) {
    return RatingModel(
      id: entity.id,
      fromUserId: entity.fromUserId,
      toUserId: entity.toUserId,
      matchId: entity.matchId,
      stars: entity.stars,
      createdAt: entity.createdAt,
      comment: entity.comment,
    );
  }

  RatingEntity toEntity() {
    return RatingEntity(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      matchId: matchId,
      stars: stars,
      createdAt: createdAt,
      comment: comment,
    );
  }

  factory RatingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de rating vacío: ${doc.id}');
    }
    return RatingModel.fromMap(doc.id, data);
  }

  factory RatingModel.fromMap(String id, Map<String, dynamic> data) {
    final createdAtRaw = data[fCreatedAt];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    return RatingModel(
      id: id,
      fromUserId: data[fFromUserId] as String? ?? '',
      toUserId: data[fToUserId] as String? ?? '',
      matchId: data[fMatchId] as String? ?? '',
      stars: (data[fStars] as num?)?.toInt() ?? 0,
      comment: data[fComment] as String?,
      createdAt: createdAt,
    );
  }

  /// Serialización para `set`. Si [useServerTimestamp] es true, `createdAt`
  /// se envía como [FieldValue.serverTimestamp] — caso típico de creación.
  Map<String, dynamic> toFirestore({bool useServerTimestamp = true}) {
    return {
      fFromUserId: fromUserId,
      fToUserId: toUserId,
      fMatchId: matchId,
      fStars: stars,
      fComment: comment,
      fCreatedAt: useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }
}
