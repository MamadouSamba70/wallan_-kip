// Modèle représentant un utilisateur authentifié dans l'application Wallan.
// Enrichi avec le champ téléphone et les helpers JSON pour la future intégration API.

/// Les rôles disponibles dans l'application Wallan.
enum UserRole {
  admin,
  patient,
  relative,
}

/// Extension pour afficher un libellé lisible par humain pour chaque rôle.
extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.patient:
        return 'Patient';
      case UserRole.relative:
        return 'Proche';
    }
  }

  /// Convertit une chaîne JSON en UserRole.
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'patient':
        return UserRole.patient;
      case 'relative':
      case 'proche':
        return UserRole.relative;
      default:
        return UserRole.patient;
    }
  }
}

/// Modèle de données de l'utilisateur connecté.
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone; // Ajout du numéro de téléphone (Semaine 2)
  final UserRole role;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
  });

  /// Crée un UserModel à partir d'un JSON (pour la future API REST).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: UserRoleExtension.fromString(json['role'] as String),
    );
  }

  /// Convertit un UserModel en JSON (pour les requêtes API).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
    };
  }

  /// Crée une copie modifiée du UserModel.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}
