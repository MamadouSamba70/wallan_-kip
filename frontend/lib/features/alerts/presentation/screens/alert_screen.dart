import 'package:flutter/material.dart';                                // Widgets Material de base
import 'package:go_router/go_router.dart';                              // Navigation entre écrans (context.go/push)
import 'alert_repository.dart';                                         // Dépôt partagé (AlertItem + AlertRepository)

/// Écran Alertes — Semaine 2 (version fonctionnelle, remplace la maquette
/// AlertsOverviewScreen de la Semaine 1 sur la même route "/alerts").
/// Utilise ValueListenableBuilder pour se reconstruire automatiquement
/// quand AlertRepository.alerts change (ex: nouvelle alerte SOS ajoutée
/// depuis SosScreen), sans avoir besoin de recharger l'écran manuellement.
class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});                                       // Constructeur const, optimise les rebuilds

  @override
  Widget build(BuildContext context) {                                  // Construction de l'interface
    final theme = Theme.of(context);                                     // Thème global Wallan (couleurs, polices)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),                                    // Titre affiché en haut de l'écran
        actions: [
          IconButton(
            icon: const Icon(Icons.sos_rounded),                          // Accès rapide à l'écran SOS depuis les alertes
            tooltip: 'Déclencher une urgence',
            onPressed: () => context.push('/sos'),                         // Navigue vers /sos sans remplacer l'historique
          ),
          IconButton(
            icon: const Icon(Icons.logout),                               // Déconnexion, cohérent avec les autres écrans
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<AlertItem>>(                   // Écoute le dépôt partagé et se reconstruit si besoin
          valueListenable: AlertRepository.alerts,                        // La source de données observée
          builder: (context, alertList, _) {                              // Appelé automatiquement à chaque changement
            if (alertList.isEmpty) {                                       // Gère le cas d'une liste vide (bonne pratique)
              return const Center(child: Text('Aucune alerte pour le moment'));
            }
            return ListView.builder(                                      // Liste optimisée : ne construit que ce qui est visible
              padding: const EdgeInsets.all(16.0),                        // Marge autour de la liste
              itemCount: alertList.length,                                // Nombre total d'éléments à afficher
              itemBuilder: (context, index) {                             // Appelé pour chaque alerte de la liste
                final alert = alertList[index];                           // L'alerte correspondant à cette position
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),              // Espace entre deux cartes d'alerte
                  child: _buildAlertCard(context, alert),                   // Délègue l'affichage au widget réutilisable
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Construit une carte d'alerte à partir d'un [AlertItem].
  Widget _buildAlertCard(BuildContext context, AlertItem alert) {       // Widget réutilisable pour une ligne d'alerte
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.error_outline_rounded,                                   // Icône générique d'alerte
          color: alert.isCritical ? Colors.red : Colors.orange,           // Rouge si critique, orange sinon
          size: 28,
        ),
        title: Text(
          alert.title,                                                    // Type d'alerte
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(                                                 // Sous-titre multi-lignes
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Patient : ${alert.patient}'),                           // Nom du patient concerné
            Text(alert.value),                                            // Valeur mesurée + seuil
            const SizedBox(height: 4),
            Text(alert.date, style: const TextStyle(fontSize: 11, color: Colors.grey)), // Date/heure
          ],
        ),
        trailing: Container(                                              // Badge de sévérité à droite
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: alert.isCritical                                       // Fond rouge clair si critique...
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),                   // ...ou orange clair si avertissement
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            alert.isCritical ? 'Critique' : 'Avertissement',               // Texte du badge selon la sévérité
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: alert.isCritical ? Colors.red : Colors.orange,
            ),
          ),
        ),
      ),
    );
  }
}