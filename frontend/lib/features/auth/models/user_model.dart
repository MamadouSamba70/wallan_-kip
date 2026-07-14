enum UserRole {
  admin,
  patient,
  relative,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  /// Factory constructors can be added here in the future if we connect to a backend API (fromJson/toJson).
}
