import 'package:flutter/material.dart';                        // Fournit les widgets Material (Scaffold, Card, Text, etc.)
import 'package:go_router/go_router.dart';                     // Fournit context.go() pour la navigation entre écrans

/// MAQUETTE — Écran Alertes (Semaine 1 du projet Wallan).
/// Vue d'ensemble statique des alertes, à valider en réunion avant le
/// développement fonctionnel (AlertScreen / SosScreen) prévu en Semaine 2.
class AlertsOverviewScreen extends StatelessWidget {            // StatelessWidget : pas de données qui changent (maquette statique)
  const AlertsOverviewScreen({super.key});                      // Constructeur const : optimise les performances Flutter

  @override
  Widget build(BuildContext context) {                          // Méthode appelée par Flutter pour construire l'interface
    final theme = Theme.of(context);                             // Récupère le thème global Wallan (couleurs, polices)

    return Scaffold(                                             // Structure de base d'un écran (barre du haut + corps)
      appBar: AppBar(                                             // Barre supérieure de l'écran
        title: const Text('Alertes'),                             // Titre affiché en haut de l'écran
        actions: [
          IconButton(                                             // Bouton de déconnexion, en haut à droite
            icon: const Icon(Icons.logout),                       // Icône représentant la déconnexion
            onPressed: () => context.go('/'),                     // Renvoie vers l'écran d'accueil (portail de rôles)
          ),
        ],
      ),
      body: SafeArea(                                             // Évite que le contenu passe sous l'encoche du téléphone
        child: SingleChildScrollView(                              // Rend l'écran défilant si le contenu est trop long
          padding: const EdgeInsets.all(16.0),                     // Marge intérieure uniforme autour du contenu
          child: Column(                                           // Empile les éléments verticalement
            crossAxisAlignment: CrossAxisAlignment.start,          // Aligne le texte à gauche plutôt qu'au centre
            children: [
              // --- Titre de la page ---
              Text(
                'Vue d\'ensemble des alertes',                      // Titre principal de l'écran
                style: theme.textTheme.titleLarge?.copyWith(        // Reprend le style "titleLarge" du thème global
                  fontSize: 24,                                     // Taille de police agrandie pour le titre
                  fontWeight: FontWeight.bold,                      // Texte en gras pour la hiérarchie visuelle
                ),
              ),
              Text(
                'Maquette — données statiques à titre d\'exemple',  // Précise que les données ne sont pas réelles
                style: theme.textTheme.bodyMedium,                   // Style de texte discret pour une note secondaire
              ),
              const SizedBox(height: 20),                            // Espace vertical avant le bloc suivant

              // --- Compteurs par sévérité (Critiques / Avertissements / Résolues) ---
              Row(                                                   // Aligne les trois cartes côte à côte
                children: [
                  Expanded(                                          // Force chaque carte à occuper 1/3 de la largeur
                    child: _buildSummaryCard(
                      context,
                      count: '2',                                     // Nombre d'alertes critiques (donnée simulée)
                      label: 'Critiques',                              // Libellé affiché sous le chiffre
                      color: Colors.red,                               // Rouge = sévérité critique
                      icon: Icons.error_rounded,                       // Icône associée à la criticité
                    ),
                  ),
                  const SizedBox(width: 12),                           // Espace horizontal entre les cartes
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      count: '3',                                      // Nombre d'avertissements (donnée simulée)
                      label: 'Avertissements',
                      color: Colors.orange,                            // Orange = sévérité avertissement
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      count: '12',                                     // Nombre d'alertes déjà résolues (donnée simulée)
                      label: 'Résolues',
                      color: Colors.green,                             // Vert = alerte traitée / résolue
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),                              // Espace avant la liste des alertes

              Text(
                'Alertes récentes',                                    // Titre de la section liste
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // --- Liste statique des alertes (à remplacer par un ListView.builder en Semaine 2) ---
              _buildAlertRow(
                context,
                title: 'Température élevée',                            // Type d'alerte : dépassement de threshold_temperature
                patient: 'Mamadou Diallo',                                // Patient concerné par la mesure
                value: '38.4 °C (Seuil : 38.0 °C)',                       // Valeur mesurée vs seuil défini côté Patient
                date: '05 Juil 2026, 14:23',                              // Date/heure simulée de déclenchement
                isCritical: true,                                         // severity = critical côté modèle Alert
              ),
              const SizedBox(height: 10),                                 // Espace entre deux lignes d'alerte
              _buildAlertRow(
                context,
                title: 'Fréquence cardiaque basse',                       // Type d'alerte : threshold_heart_rate non atteint
                patient: 'Aïssatou Bah',
                value: '58 bpm (Seuil : 60 bpm)',
                date: '05 Juil 2026, 10:05',
                isCritical: false,                                        // severity = warning côté modèle Alert
              ),
              const SizedBox(height: 10),
              _buildAlertRow(
                context,
                title: 'Saturation SpO2 basse',                           // Type d'alerte : threshold_spo2 non atteint
                patient: 'Mamadou Diallo',
                value: '90% (Seuil : 92%)',
                date: '04 Juil 2026, 22:41',
                isCritical: true,
              ),
              const SizedBox(height: 10),
              _buildAlertRow(
                context,
                title: 'Mouvement anormal détecté',                       // Type d'alerte : anomalie dans movement_data
                patient: 'Fatoumata Camara',
                value: 'Chute possible',                                  // Valeur qualitative plutôt que numérique
                date: '04 Juil 2026, 18:12',
                isCritical: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte de synthèse réutilisable (un compteur par catégorie de sévérité).
  Widget _buildSummaryCard(
    BuildContext context, {
    required String count,                                              // Chiffre à afficher en gros (ex: "2")
    required String label,                                               // Texte descriptif sous le chiffre
    required Color color,                                                // Couleur selon la sévérité représentée
    required IconData icon,                                              // Icône illustrant la catégorie
  }) {
    return Card(                                                          // Conteneur avec ombre légère (style Material)
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Espace intérieur de la carte
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),                           // Icône colorée en haut de la carte
            const SizedBox(height: 8),                                    // Espace entre l'icône et le chiffre
            Text(
              count,                                                      // Le chiffre principal (compteur)
              style: TextStyle(
                fontSize: 20,                                              // Grande taille pour mettre en valeur le chiffre
                fontWeight: FontWeight.bold,                               // Gras pour l'importance visuelle
                color: color,                                              // Même couleur que l'icône (cohérence sévérité)
              ),
            ),
            const SizedBox(height: 2),                                     // Petit espace avant le libellé
            Text(
              label,                                                       // Libellé de la catégorie (ex: "Critiques")
              textAlign: TextAlign.center,                                  // Centre le texte sous le chiffre
              style: const TextStyle(fontSize: 11, color: Colors.grey),     // Style discret pour le libellé
            ),
          ],
        ),
      ),
    );
  }

  /// Ligne d'alerte réutilisable, affichée dans la liste "Alertes récentes".
  Widget _buildAlertRow(
    BuildContext context, {
    required String title,                                                // Type d'alerte (ex: "Température élevée")
    required String patient,                                               // Nom complet du patient concerné
    required String value,                                                 // Valeur mesurée + seuil, déjà formatés en texte
    required String date,                                                  // Date/heure de déclenchement, déjà formatée
    required bool isCritical,                                              // true = severity critical, false = warning
  }) {
    return Card(                                                           // Une carte par ligne d'alerte
      child: ListTile(                                                     // Widget prêt à l'emploi pour lignes de liste
        leading: Icon(
          Icons.error_outline_rounded,                                     // Icône générique d'alerte
          color: isCritical ? Colors.red : Colors.orange,                  // Rouge si critique, orange sinon
          size: 28,
        ),
        title: Text(
          title,                                                           // Titre de l'alerte
          style: const TextStyle(fontWeight: FontWeight.bold),             // Mis en gras pour la lisibilité
        ),
        subtitle: Column(                                                  // Sous-titre multi-lignes (patient, valeur, date)
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),                                     // Petit espace après le titre
            Text('Patient : $patient'),                                    // Nom du patient concerné par l'alerte
            Text(value),                                                   // Valeur mesurée et seuil dépassé
            const SizedBox(height: 4),                                     // Espace avant la date
            Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)), // Date/heure en petit texte gris
          ],
        ),
        trailing: Container(                                               // Badge de sévérité à droite de la carte
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  // Espace intérieur du badge
          decoration: BoxDecoration(
            color: isCritical                                              // Fond rouge clair si critique...
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),                    // ...ou orange clair si avertissement
            borderRadius: BorderRadius.circular(6),                        // Coins arrondis du badge
          ),
          child: Text(
            isCritical ? 'Critique' : 'Avertissement',                     // Texte du badge selon la sévérité
            style: TextStyle(
              fontSize: 11,                                                 // Petite taille de police pour le badge
              fontWeight: FontWeight.bold,                                  // Gras pour la visibilité
              color: isCritical ? Colors.red : Colors.orange,               // Couleur du texte assortie au badge
            ),
          ),
        ),
      ),
    );
  }
}