import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/patients/presentation/screens/patient_dashboard.dart';
import '../../features/relatives/presentation/screens/relative_dashboard.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/patient/dashboard',
        builder: (context, state) => const PatientDashboard(),
      ),
      GoRoute(
        path: '/relative/dashboard',
        builder: (context, state) => const RelativeDashboard(),
      ),
    ],
  );
}
