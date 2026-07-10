import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/patients/presentation/screens/patient_dashboard.dart';
import '../../features/relatives/presentation/screens/relative_dashboard.dart';
import '../../features/alerts/presentation/screens/alerts_overview_screen.dart';

/// Configuration centralisée de la navigation de l'application Wallan.
/// Utilise la bibliothèque go_router pour gérer l'historique et les chemins URL.
class AppRouter {
  static final GoRouter router = GoRouter(
    // L'application s'ouvre par défaut sur l'écran de démarrage "/splash".
    initialLocation: '/splash',
    routes: [
      // Route pour l'écran de démarrage (Splash Screen)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Route pour la page d'accueil (Portail de sélection des rôles)
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Route pour l'écran de connexion (Login)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Route pour l'écran d'inscription (Register)
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Route pour la console d'administration (Admin Dashboard)
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      
      // Route pour le tableau de bord du patient
      GoRoute(
        path: '/patient/dashboard',
        builder: (context, state) => const PatientDashboard(),
      ),
      
      // Route pour le tableau de bord du proche / famille
      GoRoute(
        path: '/relative/dashboard',
        builder: (context, state) => const RelativeDashboard(),
      ),

      // Route pour l'écran de vue d'ensemble des Alertes (maquette Semaine 1)
      GoRoute(
        path: '/alerts',                                              // URL affichée dans l'app pour cet écran
        builder: (context, state) => const AlertsOverviewScreen(),      // Widget construit quand on visite "/alerts"
      ),
    ],
  );
}