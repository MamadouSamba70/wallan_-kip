import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/admin_alert_model.dart';
import '../../viewmodels/admin_alert_viewmodel.dart';

/// Écran complet de Supervision & Gestion des Alertes pour la console Administrateur.
class AdminAlertListScreen extends ConsumerWidget {
  const AdminAlertListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAlertViewModelProvider);
    final viewModel = ref.read(adminAlertViewModelProvider.notifier);

    final filteredAlerts = state.filteredAlerts;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Zone Filtres et Recherche ---
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => viewModel.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une alerte, un patient ou bracelet...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => viewModel.setSearchQuery(''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtres de Sévérité
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Toutes (${state.alerts.length})',
                          isSelected: state.severityFilter == null,
                          color: AppTheme.primaryBlue,
                          onTap: () => viewModel.setSeverityFilter(null),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Critiques / SOS (${state.alerts.where((a) => a.severity == AlertSeverity.critical).length})',
                          isSelected: state.severityFilter == AlertSeverity.critical,
                          color: AppTheme.errorRed,
                          onTap: () => viewModel.setSeverityFilter(AlertSeverity.critical),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Attention (${state.alerts.where((a) => a.severity == AlertSeverity.warning).length})',
                          isSelected: state.severityFilter == AlertSeverity.warning,
                          color: AppTheme.warningOrange,
                          onTap: () => viewModel.setSeverityFilter(AlertSeverity.warning),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Info (${state.alerts.where((a) => a.severity == AlertSeverity.info).length})',
                          isSelected: state.severityFilter == AlertSeverity.info,
                          color: const Color(0xFF3498DB),
                          onTap: () => viewModel.setSeverityFilter(AlertSeverity.info),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // --- Liste des Alertes ---
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                    )
                  : filteredAlerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune alerte à afficher.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => viewModel.refresh(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = filteredAlerts[index];
                              return _buildAlertCard(context, ref, alert);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, AdminAlertModel alert) {
    final viewModel = ref.read(adminAlertViewModelProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: alert.severity == AlertSeverity.critical ? 3 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: alert.severity.color,
              width: 6,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Sévérité
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alert.severity.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          alert.severity == AlertSeverity.critical
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: alert.severity.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alert.severity.label,
                          style: TextStyle(
                            color: alert.severity.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge Statut
                  Text(
                    '${alert.status.label} • ${_formatTime(alert.timestamp)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Titre et Description
              Text(
                alert.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alert.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),

              // Infos Patient & MAC responsive
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${alert.patientName} (${alert.roomNumber})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    alert.braceletMac,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Boutons d'actions avec Wrap pour éviter tout débordement
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (alert.status == AlertStatus.active)
                      OutlinedButton.icon(
                        onPressed: () => viewModel.acknowledgeAlert(alert.id),
                        icon: const Icon(Icons.touch_app_rounded, size: 14),
                        label: const Text('Prendre en charge', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    if (alert.status != AlertStatus.resolved)
                      ElevatedButton.icon(
                        onPressed: () => viewModel.resolveAlert(alert.id),
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text('Marquer Résolue', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    if (alert.status == AlertStatus.resolved)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Alerte Traitée & Clôturée',
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return 'Il y a ${diff.inHours}h';
  }
}
