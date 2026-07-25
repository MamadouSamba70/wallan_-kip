import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/patients/presentation/screens/patient_dashboard.dart';
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/relatives/presentation/screens/relative_dashboard.dart';
import '../../features/alerts/presentation/screens/alert_screen.dart';
import '../../features/alerts/presentation/screens/admin_alert_list_screen.dart';
import '../../features/alerts/presentation/screens/sos_screen.dart';
import '../../features/alerts/presentation/screens/notifications_screen.dart'; // Semaine 3 : Notifications Proche

/// Configuration centralisée de la navigation de l'application Wallan.
/// Utilise la bibliothèque go_router pour gérer l'historique et les chemins URL.
class AppRouter {
  static final GoRouter router = GoRouter(
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
      
      // Route pour la console d'administration principale (Admin Dashboard)
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Route pour la liste des patients (Console Admin)
      GoRoute(
        path: '/admin/patients',
        builder: (context, state) => const PatientListScreen(),
      ),

      // Route pour la gestion complète des alertes admin
      GoRoute(
        path: '/admin/alerts-management',
        builder: (context, state) => const AdminAlertListScreen(),
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

      // Route pour l'écran Alertes générales
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertScreen(),
      ),

      // Route pour l'écran Urgence SOS
      GoRoute(
        path: '/sos',
        builder: (context, state) => const SosScreen(),
      ),

      // Route pour l'écran Notifications de l'espace Proche (Semaine 3)
      GoRoute(
        path: '/relative/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}