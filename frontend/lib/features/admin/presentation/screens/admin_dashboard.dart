import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

export 'admin_dashboard_screen.dart';

/// Alias d'écran conservé pour la rétrocompatibilité du projet Wallan.
/// Redirige directement vers le composant principal `AdminDashboardScreen`.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminDashboardScreen();
  }
}
