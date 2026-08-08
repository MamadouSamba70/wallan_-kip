import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/api_status_banner.dart';
import '../../models/alert_model.dart';
import '../../repositories/alerts_repository.dart';
import '../../viewmodels/alerts_viewmodel.dart';

/// Écran Alertes — branché sur GET /api/alerts/by_patient/ via
/// AlertsViewModel. Toujours réactif : un SOS déclenché depuis SosScreen,
/// ou une alerte détectée automatiquement côté backend (dépassement de
/// seuil sur une mesure biométrique), apparaît ici sans action manuelle.
class AlertScreen extends ConsumerWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alertsViewModelProvider);
    final viewModel = ref.read(alertsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rafraîchir',
            onPressed: () => viewModel.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.sos_rounded),
            tooltip: 'Déclencher une urgence',
            onPressed: () => context.push('/sos'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
            : RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ApiStatusBanner(isFromApi: state.isFromApi, errorMessage: state.errorMessage),
                    if (state.alerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: Text('Aucune alerte pour le moment')),
                      )
                    else
                      for (final alert in state.alerts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildAlertCard(context, ref, alert),
                        ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, AlertModel alert) {
    final isCritical = alert.severity == AlertSeverity.critical;
    final isActive = alert.status == AlertStatus.active;

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.error_outline_rounded,
          color: isCritical ? Colors.red : Colors.orange,
          size: 28,
        ),
        title: Text(
          alert.alertTypeDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Patient : ${alert.patientName}'),
            Text(alert.valueDescription(unitSuffix: alert.unit)),
            const SizedBox(height: 4),
            Text(formatFrenchDateTime(alert.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (isActive && alert.patientId != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Marquer résolu', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                  onPressed: () => _resolve(context, ref, alert),
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCritical
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isCritical ? 'Critique' : 'Avertissement',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCritical ? Colors.red : Colors.orange,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, AlertModel alert) async {
    final repository = ref.read(alertsRepositoryProvider);
    await repository.resolveAlert(alert.id);
    if (context.mounted) {
      ref.read(alertsViewModelProvider.notifier).refresh();
    }
  }
}
