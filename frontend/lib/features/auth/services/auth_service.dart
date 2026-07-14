import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Contrat d'interface pour le service d'authentification.
abstract class AuthService {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
}

/// Implémentation simulée du service d'authentification pour les tests et la maquette.
class MockAuthService implements AuthService {
  // Liste des utilisateurs simulés
  final Map<String, _MockUser> _mockUsers = {
    'admin@wallan.gn': _MockUser('1', 'Admin Samba', 'admin123', UserRole.admin),
    'patient@wallan.gn': _MockUser('2', 'Mamadou Diallo', 'patient123', UserRole.patient),
    'proche@wallan.gn': _MockUser('3', 'Sow Proche', 'proche123', UserRole.relative),
    'relative@wallan.gn': _MockUser('4', 'Diallo Proche', 'relative123', UserRole.relative),
  };

  @override
  Future<UserModel> login(String email, String password) async {
    // Simuler un délai de connexion réseau
    await Future.delayed(const Duration(milliseconds: 1500));

    final normalizedEmail = email.trim().toLowerCase();
    final mockUser = _mockUsers[normalizedEmail];

    if (mockUser == null) {
      throw Exception('Identifiants incorrects : utilisateur non trouvé.');
    }

    if (mockUser.password != password) {
      throw Exception('Identifiants incorrects : mot de passe invalide.');
    }

    return UserModel(
      id: mockUser.id,
      email: normalizedEmail,
      name: mockUser.name,
      role: mockUser.role,
    );
  }

  @override
  Future<void> logout() async {
    // Simuler un court délai de déconnexion
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Classe interne représentant un utilisateur simulé en base de données.
class _MockUser {
  final String id;
  final String name;
  final String password;
  final UserRole role;

  _MockUser(this.id, this.name, this.password, this.role);
}

/// Provider Riverpod exposant l'implémentation simulée du service d'authentification.
final authServiceProvider = Provider<AuthService>((ref) {
  return MockAuthService();
});
