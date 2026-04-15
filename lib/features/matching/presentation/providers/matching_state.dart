import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/match_candidate.dart';
import '../../domain/entities/match_search_input.dart';

class MatchingState extends Equatable {
  final bool isSearching;
  final List<MatchCandidate> candidates;
  final Failure? error;
  final MatchSearchInput? lastInput;

  const MatchingState({
    required this.isSearching,
    required this.candidates,
    required this.error,
    required this.lastInput,
  });

  const MatchingState.initial()
      : isSearching = false,
        candidates = const [],
        error = null,
        lastInput = null;

  MatchingState copyWith({
    bool? isSearching,
    List<MatchCandidate>? candidates,
    Failure? error,
    MatchSearchInput? lastInput,
    bool clearError = false,
  }) {
    return MatchingState(
      isSearching: isSearching ?? this.isSearching,
      candidates: candidates ?? this.candidates,
      error: clearError ? null : (error ?? this.error),
      lastInput: lastInput ?? this.lastInput,
    );
  }

  @override
  List<Object?> get props => [isSearching, candidates, error, lastInput];
}
