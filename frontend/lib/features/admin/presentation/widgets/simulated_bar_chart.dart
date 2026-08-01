import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Structure d'une barre de graphique
class BarChartDataGroup {
  final String label;
  final double value;
  final Color color;

  const BarChartDataGroup({
    required this.label,
    required this.value,
    this.color = AppTheme.primaryBlue,
  });
}

/// Widget de Graphique en Barres Simulé pour la répartition des alertes et événements hebdomadaires.
class SimulatedBarChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<BarChartDataGroup> dataGroups;

  const SimulatedBarChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dataGroups,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final maxVal = dataGroups.fold<double>(1.0, (prev, curr) => curr.value > prev ? curr.value : prev);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Zone d'affichage des barres
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dataGroups.map((group) {
                final heightFactor = (group.value / maxVal).clamp(0.05, 1.0);
                return _buildBarItem(group, heightFactor);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(BarChartDataGroup group, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${group.value.toInt()}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            width: 18,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: group.color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          group.label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
