import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/match_search_input.dart';
import '../../domain/repositories/matching_repository.dart';
import 'matching_state.dart';

class MatchingNotifier extends StateNotifier<MatchingState> {
  final MatchingRepository _repository;

  MatchingNotifier(this._repository) : super(const MatchingState.initial());

  Future<void> searchMatches(MatchSearchInput input) async {
    state = state.copyWith(
      isSearching: true,
      lastInput: input,
      clearError: true,
    );

    final result = await _repository.searchMatches(input);

    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isSearching: false,
        error: failure,
        candidates: const [],
      ),
      (candidates) => state = state.copyWith(
        isSearching: false,
        candidates: candidates,
        clearError: true,
      ),
    );
  }

  void clear() {
    state = const MatchingState.initial();
  }
}
