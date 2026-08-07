import 'user_model.dart';

/// État de l'authentification utilisé par l'AuthViewModel.
/// Gère à la fois les états de Login et Register.
class AuthState {
  /// Indique si une opération asynchrone est en cours (login ou register).
  final bool isLoading;

  /// Message d'erreur à afficher à l'utilisateur. null si pas d'erreur.
  final String? errorMessage;

  /// Message de succès (ex: inscription réussie). null si pas de succès.
  final String? successMessage;

  /// L'utilisateur actuellement connecté. null si non authentifié.
  final UserModel? user;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.user,
  });

  /// Crée une copie de l'état avec certains champs modifiés.
  /// Les champs errorMessage et successMessage peuvent être explicitement mis à null.
  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    UserModel? user,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      // Permet de vider le message d'erreur avec clearError: true
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      user: user ?? this.user,
    );
  }

  /// Retourne true si l'utilisateur est authentifié.
  bool get isAuthenticated => user != null;
}
