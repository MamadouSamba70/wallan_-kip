import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bandeau réutilisable indiquant si les données affichées viennent de la
/// vraie API Django (vert) ou d'un repli hors-ligne/démo (orange), avec le
/// message d'erreur éventuel.
///
/// Même principe que le bandeau déjà utilisé dans l'onglet Analytiques du
/// Dashboard Admin (Semaine 4) — repris ici pour AlertScreen,
/// NotificationsScreen, StatisticsScreen et RelativeDashboard, afin que la
/// preuve "toutes les données proviennent du vrai backend" (Plan de
/// Travail, Semaine 5) soit visible directement à l'écran.
class ApiStatusBanner extends StatelessWidget {
  final bool isFromApi;
  final String? errorMessage;

  const ApiStatusBanner({
    super.key,
    required this.isFromApi,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFromApi ? AppTheme.successGreen : AppTheme.warningOrange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isFromApi ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFromApi
                  ? 'Connecté à l\'API Django — données en direct'
                  : (errorMessage ?? 'Backend injoignable — données démo affichées'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
