// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI un AuthModel séparé du UserModel ?
//
// La réponse de l'API /auth/login/ contient PLUS que juste les données user.
// Elle contient aussi les tokens JWT. On sépare donc :
//   - AuthModel  : structure complète de la réponse API (tokens + user)
//   - UserModel  : données de l'utilisateur seul (utilisé dans toute l'app)
//
// Cette séparation respecte le principe SOLID — Single Responsibility.
// Le AuthModel est une "enveloppe" de transport, le UserModel est le "contenu".
// ─────────────────────────────────────────────────────────────────────────────

/// Modèle représentant la réponse complète de l'API lors de l'authentification.
///
/// Exemple de JSON retourné par Django REST Framework (Simple JWT) :
/// ```json
/// {
///   "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
///   "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
///   "user": {
///     "id": "1",
///     "email": "admin@wallan.gn",
///     "name": "Admin Samba",
///     "phone": "+224 620 00 00 01",
///     "role": "admin"
///   }
/// }
/// ```
class AuthResponseModel {
  /// Token d'accès JWT (courte durée : 5-15 min côté Django).
  final String accessToken;

  /// Token de rafraîchissement JWT (longue durée : 1-7 jours côté Django).
  final String refreshToken;

  /// Informations de l'utilisateur authentifié.
  final AuthUserData user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  /// Désérialise la réponse JSON de l'API Django REST Framework.
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;
    return AuthResponseModel(
      accessToken: (json['access'] ?? json['accessToken'] ?? '') as String,
      refreshToken: (json['refresh'] ?? json['refreshToken'] ?? '') as String,
      user: userData != null
          ? AuthUserData.fromJson(userData)
          : const AuthUserData(
              id: '1',
              email: 'admin@wallan.health',
              name: 'Utilisateur',
              role: 'admin',
            ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
/// Données de l'utilisateur telles que retournées par l'API auth.
///
/// Distinct de UserModel pour ne pas coupler le modèle de présentation
/// à la structure exacte de la réponse backend (qui peut changer).
// ─────────────────────────────────────────────────────────────────────────────
class AuthUserData {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role; // String brut depuis l'API, converti en UserRole dans UserModel

  const AuthUserData({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
  });

  factory AuthUserData.fromJson(Map<String, dynamic> json) {
    return AuthUserData(
      // Conversion sécurisée : toString() évite les crashes si le backend envoie un int
      id: json['id'].toString(),
      email: json['email'] as String,
      // Support "name" ou "full_name" selon la convention backend
      name: (json['name'] ?? json['full_name'] ?? '') as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Modèle pour les erreurs de validation retournées par Django.
///
/// Django REST Framework retourne les erreurs sous forme de Map :
/// ```json
/// { "email": ["Ce champ est obligatoire."], "password": ["Trop court."] }
/// ```
/// ou bien un message global :
/// ```json
/// { "detail": "No active account found with the given credentials" }
/// ```
// ─────────────────────────────────────────────────────────────────────────────
class ApiErrorModel {
  final String message;

  const ApiErrorModel({required this.message});

  /// Extrait le premier message d'erreur pertinent de la réponse Django.
  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    // Cas 1 : Erreur globale "detail" (ex: mauvais identifiants)
    if (json.containsKey('detail')) {
      return ApiErrorModel(message: json['detail'] as String);
    }

    // Cas 2 : Erreurs de validation par champ (ex: email invalide)
    // On prend le premier message d'erreur de la première clé
    for (final key in json.keys) {
      final value = json[key];
      if (value is List && value.isNotEmpty) {
        return ApiErrorModel(message: '${_fieldLabel(key)}: ${value.first}');
      }
      if (value is String) {
        return ApiErrorModel(message: value);
      }
    }

    return const ApiErrorModel(message: 'Une erreur inattendue est survenue.');
  }

  /// Traduit les noms de champs API en libellés lisibles.
  static String _fieldLabel(String key) {
    const labels = {
      'email': 'Email',
      'password': 'Mot de passe',
      'name': 'Nom',
      'phone': 'Téléphone',
      'role': 'Rôle',
      'non_field_errors': 'Erreur',
    };
    return labels[key] ?? key;
  }
}
