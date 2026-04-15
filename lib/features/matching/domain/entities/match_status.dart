enum MatchStatus {
  pending,
  accepted,
  rejected,
  active,
  completed,
  cancelled;

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MatchStatus.pending,
    );
  }
}
