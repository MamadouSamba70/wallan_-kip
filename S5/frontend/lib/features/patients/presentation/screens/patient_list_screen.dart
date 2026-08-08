import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/patient_model.dart';
import '../../viewmodels/patient_list_viewmodel.dart';
import '../widgets/patient_detail_modal.dart';

/// Écran de la Liste des Patients pour l'Administrateur.
/// Intègre la barre de recherche temps réel, les puces de filtres par statut et la liste réactive.
class PatientListScreen extends ConsumerWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientListViewModelProvider);
    final viewModel = ref.read(patientListViewModelProvider.notifier);

    final filteredList = state.filteredPatients;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Barre de recherche & Filtres ---
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  // Champ de Recherche
                  TextField(
                    onChanged: (val) => viewModel.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, MAC ou chambre...',
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

                  // Puces de filtres par statut
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tous (${state.patients.length})',
                          isSelected: state.statusFilter == null,
                          color: AppTheme.primaryBlue,
                          onTap: () => viewModel.setStatusFilter(null),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Critiques (${state.patients.where((p) => p.status == PatientStatus.critical).length})',
                          isSelected: state.statusFilter == PatientStatus.critical,
                          color: AppTheme.errorRed,
                          onTap: () => viewModel.setStatusFilter(PatientStatus.critical),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Surveillance (${state.patients.where((p) => p.status == PatientStatus.warning).length})',
                          isSelected: state.statusFilter == PatientStatus.warning,
                          color: AppTheme.warningOrange,
                          onTap: () => viewModel.setStatusFilter(PatientStatus.warning),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Stables (${state.patients.where((p) => p.status == PatientStatus.stable).length})',
                          isSelected: state.statusFilter == PatientStatus.stable,
                          color: AppTheme.successGreen,
                          onTap: () => viewModel.setStatusFilter(PatientStatus.stable),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // --- Corps de la liste ---
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                    )
                  : filteredList.isEmpty
                      ? _buildEmptyState(context, state.searchQuery)
                      : RefreshIndicator(
                          onRefresh: () => viewModel.refresh(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final patient = filteredList[index];
                              return _buildPatientCard(context, patient);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Puce de filtre personnalisée
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

  /// Carte individuelle de Patient responsive
  Widget _buildPatientCard(BuildContext context, PatientModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => PatientDetailModal.show(context, patient),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: patient.status.color.withValues(alpha: 0.15),
                    child: Icon(
                      patient.gender == 'Homme' ? Icons.face_rounded : Icons.face_3_rounded,
                      color: patient.status.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                patient.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${patient.id})',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${patient.roomNumber} • ${patient.braceletMac}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: patient.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(patient.status.icon, size: 12, color: patient.status.color),
                        const SizedBox(width: 4),
                        Text(
                          patient.status.label,
                          style: TextStyle(
                            color: patient.status.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Résumé des constantes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricBadge(
                    label: 'Pulsations',
                    value: '${patient.heartRate} BPM',
                    icon: Icons.favorite_rounded,
                    color: AppTheme.errorRed,
                  ),
                  _buildMetricBadge(
                    label: 'SpO2',
                    value: '${patient.spo2} %',
                    icon: Icons.water_drop_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  _buildMetricBadge(
                    label: 'Température',
                    value: '${patient.temperature} °C',
                    icon: Icons.thermostat_rounded,
                    color: AppTheme.warningOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'Aucun patient ne correspond à "$query"'
                  : 'Aucun patient trouvé.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
