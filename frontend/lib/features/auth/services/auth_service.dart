import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Contrat d'interface pour le service d'authentification.
/// Permet de brancher facilement un service réel à la place du mock.
abstract class AuthService {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  });
  Future<void> logout();
}

// ─────────────────────────────────────────────────────────────────────────────
/// Implémentation simulée du service d'authentification.
/// Simule les appels réseau avec des délais pour tester l'UI de chargement.
// ─────────────────────────────────────────────────────────────────────────────
class MockAuthService implements AuthService {
  /// Base de données en mémoire des utilisateurs simulés.
  final Map<String, _MockUser> _mockUsers = {
    'admin@wallan.gn': _MockUser(
      id: '1',
      name: 'Admin Samba',
      password: 'admin123',
      phone: '+224 620 00 00 01',
      role: UserRole.admin,
    ),
    'patient@wallan.gn': _MockUser(
      id: '2',
      name: 'Mamadou Diallo',
      password: 'patient123',
      phone: '+224 620 00 00 02',
      role: UserRole.patient,
    ),
    'proche@wallan.gn': _MockUser(
      id: '3',
      name: 'Sow Proche',
      password: 'proche123',
      phone: '+224 620 00 00 03',
      role: UserRole.relative,
    ),
    'relative@wallan.gn': _MockUser(
      id: '4',
      name: 'Diallo Famille',
      password: 'relative123',
      phone: '+224 620 00 00 04',
      role: UserRole.relative,
    ),
  };

  // ── Login ──────────────────────────────────────────────────────────────────
  @override
  Future<UserModel> login(String email, String password) async {
    // Simule la latence réseau (1.5 secondes)
    await Future.delayed(const Duration(milliseconds: 1500));

    final normalizedEmail = email.trim().toLowerCase();
    final mockUser = _mockUsers[normalizedEmail];

    if (mockUser == null) {
      throw Exception('Aucun compte trouvé avec cet email.');
    }

    if (mockUser.password != password) {
      throw Exception('Mot de passe incorrect. Veuillez réessayer.');
    }

    return UserModel(
      id: mockUser.id,
      email: normalizedEmail,
      name: mockUser.name,
      phone: mockUser.phone,
      role: mockUser.role,
    );
  }

  // ── Register ───────────────────────────────────────────────────────────────
  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    // Simule la latence réseau (2 secondes pour l'inscription)
    await Future.delayed(const Duration(seconds: 2));

    final normalizedEmail = email.trim().toLowerCase();

    // Vérifie si l'email est déjà utilisé
    if (_mockUsers.containsKey(normalizedEmail)) {
      throw Exception('Un compte existe déjà avec cet email.');
    }

    // Convertit le rôle (string) en enum UserRole
    final userRole = UserRoleExtension.fromString(role);

    // Crée l'utilisateur simulé et l'ajoute à la base
    final newId = (_mockUsers.length + 1).toString();
    final newUser = _MockUser(
      id: newId,
      name: name.trim(),
      password: password,
      phone: phone.trim(),
      role: userRole,
    );

    _mockUsers[normalizedEmail] = newUser;

    // Retourne le UserModel du nouvel utilisateur
    return UserModel(
      id: newId,
      email: normalizedEmail,
      name: name.trim(),
      phone: phone.trim(),
      role: userRole,
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Classe interne représentant un utilisateur dans la base de données simulée.
// ─────────────────────────────────────────────────────────────────────────────
class _MockUser {
  final String id;
  final String name;
  final String password;
  final String? phone;
  final UserRole role;

  const _MockUser({
    required this.id,
    required this.name,
    required this.password,
    this.phone,
    required this.role,
  });
}

/// Provider Riverpod exposant l'implémentation simulée du service d'authentification.
/// À remplacer par `RealAuthService` lors de l'intégration backend.
final authServiceProvider = Provider<AuthService>((ref) {
  return MockAuthService();
});
