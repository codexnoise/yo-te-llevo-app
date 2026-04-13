enum UserRole {
  passenger,
  driver,
  both;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.passenger,
    );
  }
}
