import 'user_model.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final UserModel? user;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Note: We allow setting this to null to clear errors
      user: user ?? this.user,
    );
  }

  bool get isAuthenticated => user != null;
}
