import 'package:equatable/equatable.dart';

/// Calificación mutua post-viaje (spec §8.1).
///
/// Un rating vive en `/ratings/{ratingId}` y es inmutable: una vez escrito
/// no se actualiza ni se borra. Las rules de Firestore lo enforzan
/// (`firestore.rules` §ratings).
class RatingEntity extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String matchId;
  final int stars;
  final String? comment;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.matchId,
    required this.stars,
    required this.createdAt,
    this.comment,
  });

  RatingEntity copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? matchId,
    int? stars,
    String? comment,
    DateTime? createdAt,
  }) {
    return RatingEntity(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      matchId: matchId ?? this.matchId,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        matchId,
        stars,
        comment,
        createdAt,
      ];
}
