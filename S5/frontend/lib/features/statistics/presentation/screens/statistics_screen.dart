import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/api_status_banner.dart';
import '../../../alerts/models/alert_model.dart';
import '../../../alerts/viewmodels/alerts_viewmodel.dart';
import '../../../relatives/viewmodels/patient_link_viewmodel.dart';
import '../../models/biometric_reading_model.dart';
import '../../viewmodels/statistics_viewmodel.dart';

/// Dashboard Statistiques de l'Espace Proche.
///
/// Les graphiques sont alimentés par deux sources réelles :
///
///  1. VitalsViewModel → GET /api/biometrics/{patient_id}/history/ :
///     historique 7 jours des constantes (fréquence cardiaque, SpO2),
///     agrégé en moyenne journalière. Repli simulé automatique si l'API ne
///     renvoie rien ou si aucun patient n'est lié à ce compte.
///
///  2. AlertsViewModel → GET /api/alerts/by_patient/ (déjà utilisé par
///     AlertScreen, NotificationsScreen, RelativeDashboard) : les
///     graphiques d'analyse des alertes (par type, par sévérité) sont
///     dérivés EN DIRECT de ces mêmes alertes réelles, sans double appel
///     réseau.
///
/// Toujours 4 graphiques fl_chart : 2 LineChart (constantes), 1 BarChart
/// (alertes par type), 1 PieChart (répartition par sévérité).
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsState = ref.watch(vitalsViewModelProvider);
    final alertsState = ref.watch(alertsViewModelProvider);
    final linkState = ref.watch(patientLinkViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rafraîchir',
            onPressed: () {
              ref.read(vitalsViewModelProvider.notifier).refresh();
              ref.read(alertsViewModelProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.read(vitalsViewModelProvider.notifier).refresh(),
            ref.read(alertsViewModelProvider.notifier).refresh(),
          ]),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApiStatusBanner(isFromApi: vitalsState.isFromApi, errorMessage: vitalsState.errorMessage),

                Text(
                  'Évolution des constantes (7 derniers jours)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${linkState.patientName ?? "Patient"} — GET /api/biometrics/{id}/history/',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                if (vitalsState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                  )
                else ...[
                  _buildLineCard(
                    context,
                    title: 'Fréquence cardiaque',
                    unit: 'bpm',
                    color: AppTheme.primaryBlue,
                    minY: 60,
                    maxY: 100,
                    data: vitalsState.weeklyVitals,
                    getValue: (p) => p.heartRate,
                  ),
                  const SizedBox(height: 16),
                  _buildLineCard(
                    context,
                    title: 'Saturation en oxygène (SpO2)',
                    unit: '%',
                    color: AppTheme.successGreen,
                    minY: 90,
                    maxY: 100,
                    data: vitalsState.weeklyVitals,
                    getValue: (p) => p.spo2,
                  ),
                ],
                const SizedBox(height: 28),

                Text(
                  'Analyse des alertes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Calculée en direct depuis GET /api/alerts/',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                if (alertsState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                  )
                else if (alertsState.alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Aucune alerte à analyser pour le moment', style: TextStyle(color: Colors.grey)),
                  )
                else ...[
                  _buildBarCard(context, _countByType(alertsState.alerts)),
                  const SizedBox(height: 16),
                  _buildPieCard(context, _severityBreakdown(alertsState.alerts)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Fonctions pures de dérivation des stats d'alertes ──────────────────

  Map<String, int> _severityBreakdown(List<AlertModel> alerts) {
    final critical = alerts.where((a) => a.severity == AlertSeverity.critical).length;
    final warning = alerts.length - critical;
    return {'Critique': critical, 'Avertissement': warning};
  }

  Map<String, int> _countByType(List<AlertModel> alerts) {
    final Map<String, int> counts = {};
    for (final alert in alerts) {
      counts[alert.alertTypeDisplay] = (counts[alert.alertTypeDisplay] ?? 0) + 1;
    }
    return counts;
  }

  // ── Graphiques ───────────────────────────────────────────────────────

  /// Construit une carte contenant un LineChart pour une constante donnée.
  Widget _buildLineCard(
    BuildContext context, {
    required String title,
    required String unit,
    required Color color,
    required double minY,
    required double maxY,
    required List<VitalsPoint> data,
    required double Function(VitalsPoint point) getValue,
  }) {
    final spots = <FlSpot>[
      for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), getValue(data[i])),
    ];

    return _ChartCard(
      title: title,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              horizontalInterval: (maxY - minY) / 4,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: (maxY - minY) / 4,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data[index].dayLabel,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => color,
                getTooltipItems: (touchedSpots) => touchedSpots
                    .map((s) => LineTooltipItem('${s.y.toStringAsFixed(1)} $unit', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la carte du graphique en barres : nombre d'alertes par type.
  Widget _buildBarCard(BuildContext context, Map<String, int> byType) {
    final entries = byType.entries.toList();
    final maxCount = entries.fold<int>(1, (prev, e) => e.value > prev ? e.value : prev);

    return _ChartCard(
      title: 'Alertes par type',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxCount + 1).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: 1,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        entries[index].key,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < entries.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value.toDouble(),
                      color: AppTheme.primaryBlue,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la carte du graphique circulaire : répartition par sévérité.
  Widget _buildPieCard(BuildContext context, Map<String, int> bySeverity) {
    final critical = bySeverity['Critique'] ?? 0;
    final warning = bySeverity['Avertissement'] ?? 0;
    final total = critical + warning;

    return _ChartCard(
      title: 'Répartition par sévérité',
      child: SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: [
                    PieChartSectionData(
                      value: critical.toDouble(),
                      color: AppTheme.errorRed,
                      title: total == 0 ? '' : '${(critical / total * 100).round()}%',
                      radius: 54,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: warning.toDouble(),
                      color: AppTheme.warningOrange,
                      title: total == 0 ? '' : '${(warning / total * 100).round()}%',
                      radius: 54,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendRow(AppTheme.errorRed, 'Critique', critical),
                  const SizedBox(height: 10),
                  _legendRow(AppTheme.warningOrange, 'Avertissement', warning),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$label ($count)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

/// Carte blanche réutilisable pour envelopper chaque graphique.
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
