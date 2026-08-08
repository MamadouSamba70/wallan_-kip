import 'package:flutter/material.dart';                                // Widgets Material de base
import 'package:go_router/go_router.dart';                              // Navigation entre écrans
import 'package:fl_chart/fl_chart.dart';                                 // Package de graphiques (courbes, axes, tooltips)
import '../../../../core/theme/app_theme.dart';                          // Palette de couleurs officielle Wallan

/// Un point de mesure biométrique quotidien (moyenne du jour).
/// Représente une agrégation simplifiée de la table BiometricReading
/// (section 3.4 du Plan de Travail), en attendant l'endpoint réel
/// GET /api/statistics/reports/ (module statistics/, prévu plus tard).
class BiometricPoint {
  final String day;                                                      // Jour affiché en abscisse (ex: "Lun")
  final double heartRate;                                                 // Rythme cardiaque moyen du jour (bpm)
  final double temperature;                                                // Température moyenne du jour (°C)
  final double spo2;                                                       // Saturation en oxygène moyenne du jour (%)

  const BiometricPoint({
    required this.day,
    required this.heartRate,
    required this.temperature,
    required this.spo2,
  });
}

/// Jeu de données simulé sur 7 jours, en attendant le vrai historique
/// renvoyé par l'API (Semaine 5, intégration Flutter / Django).
const List<BiometricPoint> _weeklyData = [                                // Une entrée par jour de la semaine
  BiometricPoint(day: 'Lun', heartRate: 76, temperature: 36.6, spo2: 98),
  BiometricPoint(day: 'Mar', heartRate: 79, temperature: 36.7, spo2: 97),
  BiometricPoint(day: 'Mer', heartRate: 82, temperature: 37.1, spo2: 96),
  BiometricPoint(day: 'Jeu', heartRate: 88, temperature: 38.2, spo2: 94),  // Journée à seuil dépassé (cf. AlertRepository)
  BiometricPoint(day: 'Ven', heartRate: 80, temperature: 36.9, spo2: 97),
  BiometricPoint(day: 'Sam', heartRate: 77, temperature: 36.7, spo2: 98),
  BiometricPoint(day: 'Dim', heartRate: 78, temperature: 36.8, spo2: 98),
];

/// Décrit une métrique affichable (nom, unité, couleur, valeurs extraites).
class _MetricConfig {
  final String label;                                                     // Nom affiché (ex: "Cardiaque")
  final String unit;                                                      // Unité affichée (ex: "bpm")
  final Color color;                                                      // Couleur de la courbe et des accents
  final IconData icon;                                                    // Icône du sélecteur
  final double Function(BiometricPoint) selector;                         // Extrait la valeur voulue d'un point

  const _MetricConfig({
    required this.label,
    required this.unit,
    required this.color,
    required this.icon,
    required this.selector,
  });
}

/// Écran Statistiques — Semaine 4.
/// Affiche les tendances hebdomadaires des constantes vitales du patient
/// sous forme de graphiques fl_chart, à partir de données simulées.
/// Accessible depuis PatientDashboard (le patient consulte ses propres
/// tendances) et RelativeDashboard (le proche suit les tendances à distance).
class StatisticsScreen extends StatefulWidget {                          // StatefulWidget : le métrique sélectionné change
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedIndex = 0;                                                  // Index de la métrique actuellement affichée

  /// Les 3 métriques disponibles, dans l'ordre d'affichage des onglets.
  late final List<_MetricConfig> _metrics = [                              // late : construit une fois, réutilisé au rebuild
    _MetricConfig(
      label: 'Cardiaque',
      unit: 'bpm',
      color: AppTheme.errorRed,                                            // Rouge, cohérent avec l'icône coeur ailleurs dans l'app
      icon: Icons.favorite_rounded,
      selector: (p) => p.heartRate,
    ),
    _MetricConfig(
      label: 'Température',
      unit: '°C',
      color: AppTheme.warningOrange,                                       // Orange, cohérent avec les alertes de température
      icon: Icons.thermostat_rounded,
      selector: (p) => p.temperature,
    ),
    _MetricConfig(
      label: 'SpO2',
      unit: '%',
      color: AppTheme.infoBlue,                                            // Bleu info, distinct du bleu principal de la marque
      icon: Icons.opacity_rounded,
      selector: (p) => p.spo2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);                                       // Thème global Wallan
    final metric = _metrics[_selectedIndex];                                // Métrique actuellement sélectionnée
    final values = _weeklyData.map(metric.selector).toList();               // Valeurs brutes de la semaine pour cette métrique
    final minValue = values.reduce((a, b) => a < b ? a : b);                 // Plus petite valeur de la semaine
    final maxValue = values.reduce((a, b) => a > b ? a : b);                 // Plus grande valeur de la semaine
    final avgValue = values.reduce((a, b) => a + b) / values.length;         // Moyenne hebdomadaire

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),                                  // Titre de l'écran
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),                                 // Déconnexion, cohérent avec les autres écrans
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tendances de la semaine',                                   // Titre principal de la page
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Mamadou Diallo — Données simulées',                         // Précise le patient concerné + nature des données
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // --- Sélecteur de métrique (Cardiaque / Température / SpO2) ---
              Row(
                children: List.generate(_metrics.length, (index) {           // Un chip par métrique disponible
                  final isSelected = index == _selectedIndex;                 // Vrai si ce chip est actuellement actif
                  final m = _metrics[index];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < _metrics.length - 1 ? 8 : 0), // Espace entre chips, sauf le dernier
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),   // Change la métrique affichée au tap
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? m.color.withValues(alpha: 0.12) : Colors.transparent, // Fond teinté si actif
                            border: Border.all(color: isSelected ? m.color : Colors.grey.shade300),     // Contour coloré si actif
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(m.icon, color: isSelected ? m.color : Colors.grey, size: 20),         // Icône de la métrique
                              const SizedBox(height: 4),
                              Text(
                                m.label,                                                                 // Nom de la métrique
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? m.color : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // --- Graphique principal (courbe fl_chart) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),          // Marge asymétrique : espace pour les labels d'axe Y
                  child: SizedBox(
                    height: 220,                                             // Hauteur fixe du graphique
                    child: LineChart(                                        // Widget principal fl_chart
                      LineChartData(
                        gridData: FlGridData(                                 // Quadrillage horizontal discret en arrière-plan
                          show: true,
                          drawVerticalLine: false,                            // Pas de lignes verticales, pour rester épuré
                          horizontalInterval: (maxValue - minValue) / 4 == 0 ? 1 : (maxValue - minValue) / 4,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(                             // Configuration des axes
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Pas de titres en haut
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Pas de titres à droite
                          bottomTitles: AxisTitles(                            // Axe du bas : les jours de la semaine
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {                 // Convertit l'index en label "Lun", "Mar", etc.
                                final i = value.toInt();
                                if (i < 0 || i >= _weeklyData.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(_weeklyData[i].day, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: AxisTitles(                              // Axe de gauche : les valeurs mesurées
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (value, meta) => Text(
                                value.toStringAsFixed(0),                       // Valeurs arrondies pour rester lisible
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),                 // Pas de cadre autour du graphique
                        lineBarsData: [
                          LineChartBarData(                                    // La courbe elle-même
                            spots: List.generate(
                              _weeklyData.length,
                              (i) => FlSpot(i.toDouble(), metric.selector(_weeklyData[i])), // Un point par jour
                            ),
                            isCurved: true,                                     // Courbe lissée plutôt que segments droits
                            color: metric.color,                                // Couleur selon la métrique sélectionnée
                            barWidth: 3,
                            dotData: const FlDotData(show: true),               // Affiche un point à chaque valeur
                            belowBarData: BarAreaData(                          // Dégradé sous la courbe
                              show: true,
                              color: metric.color.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(                          // Tooltip interactif au toucher
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((s) {
                              return LineTooltipItem(
                                '${s.y.toStringAsFixed(1)} ${metric.unit}',      // Valeur + unité dans l'infobulle
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Résumé statistique (Min / Moyenne / Max) ---
              Row(
                children: [
                  Expanded(child: _buildStatCard('Min', minValue, metric.unit, metric.color)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Moyenne', avgValue, metric.unit, metric.color)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Max', maxValue, metric.unit, metric.color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Petite carte affichant une statistique agrégée (Min, Moyenne ou Max).
  Widget _buildStatCard(String label, double value, String unit, Color color) { // Widget réutilisable pour les 3 cartes
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value.toStringAsFixed(1),                                       // Valeur arrondie à 1 décimale
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)), // Unité sous la valeur
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), // Libellé (Min/Moyenne/Max)
          ],
        ),
      ),
    );
  }
}