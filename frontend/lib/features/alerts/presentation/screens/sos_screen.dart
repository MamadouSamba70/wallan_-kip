import 'package:flutter/material.dart';                                // Widgets Material de base
import 'package:go_router/go_router.dart';                              // Navigation entre écrans
import 'alert_repository.dart';                                         // Dépôt partagé (AlertItem + AlertRepository)

/// Les 3 états visuels possibles de l'écran SOS.
enum _SosState { idle, sending, sent }                                  // idle = repos, sending = en cours, sent = confirmé

/// Écran Urgence SOS — Semaine 2.
/// Le bouton est "visuellement fonctionnel" comme demandé dans le plan de
/// travail : il simule un envoi (délai + confirmation), et enregistre une
/// nouvelle alerte dans le dépôt partagé (AlertRepository). Cette alerte
/// apparaît alors automatiquement dans AlertScreen ET dans l'historique du
/// Dashboard Proche, sans action supplémentaire.
/// N'est pas encore connecté à POST /api/alerts/emergency/ — cette
/// connexion réelle est prévue plus tard, une fois l'API d'urgence
/// disponible côté backend.
class SosScreen extends StatefulWidget {                                // StatefulWidget : l'état change au fil du tap
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  _SosState _state = _SosState.idle;                                     // État courant, "idle" par défaut au démarrage
  AlertItem? _lastAlert;                                                  // Détails de l'alerte SOS déclenchée (pour affichage)

  /// Simule l'envoi de l'alerte SOS (délai artificiel de 2 secondes), puis
  /// enregistre l'alerte dans le dépôt partagé afin qu'elle soit visible
  /// automatiquement sur AlertScreen et sur le Dashboard Proche.
  Future<void> _triggerSos() async {                                     // Déclenché au tap sur le bouton rond rouge
    setState(() => _state = _SosState.sending);                           // Passe visuellement en mode "envoi en cours"
    await Future.delayed(const Duration(seconds: 2));                     // Attente simulant un appel réseau réel
    if (!mounted) return;                                                  // Sécurité : évite un setState si l'écran est fermé

    final now = DateTime.now();                                           // Heure réelle du déclenchement (pas simulée)
    final newAlert = AlertItem(                                           // Construit l'alerte correspondant à ce SOS
      title: 'Alerte SOS manuelle',                                        // Cause de l'alerte : déclenchement volontaire
      patient: 'Mamadou Diallo',                                           // Même patient que sur PatientDashboard
      value: 'Déclenchée manuellement par le patient',                     // Description de la cause, à la place d'une valeur mesurée
      date: AlertRepository.formatDate(now),                               // Heure exacte, formatée en français
      isCritical: true,                                                    // Une urgence SOS est toujours critique
    );
    AlertRepository.addAlert(newAlert);                                    // Ajoute au dépôt partagé (visible partout ensuite)

    setState(() {
      _lastAlert = newAlert;                                               // Mémorise l'alerte pour l'affichage de confirmation
      _state = _SosState.sent;                                             // Passe en mode "envoyé avec succès"
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urgence SOS'),                                  // Titre de l'écran
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),                                 // Déconnexion, cohérent avec les autres écrans
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(                                                      // Centre tout le contenu à l'écran
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_state == _SosState.idle) ..._buildIdleContent(),        // --- État 1 : avant tout déclenchement ---
                if (_state == _SosState.sending) ..._buildSendingContent(),   // --- État 2 : simulation d'envoi en cours ---
                if (_state == _SosState.sent) ..._buildSentContent(),         // --- État 3 : confirmation + détails de l'alerte ---
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Contenu affiché avant tout déclenchement (bouton SOS prêt à l'emploi).
  List<Widget> _buildIdleContent() {                                      // Retourne la liste de widgets pour l'état "idle"
    return [
      const Text(
        'En cas d\'urgence, appuyez sur le bouton ci-dessous',              // Instruction claire pour l'utilisateur
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 32),                                          // Espace avant le bouton
      GestureDetector(
        onTap: _triggerSos,                                                 // Lance la simulation d'envoi au tap
        child: Container(
          width: 160,                                                       // Grand bouton rond, facile à taper en urgence
          height: 160,
          decoration: BoxDecoration(
            color: Colors.red.shade600,                                     // Rouge vif = signal d'urgence universel
            shape: BoxShape.circle,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sos_rounded, color: Colors.white, size: 48),        // Icône SOS bien visible
              SizedBox(height: 4),
              Text(
                'SOS',                                                       // Libellé du bouton
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Contenu affiché pendant la simulation d'envoi (2 secondes).
  List<Widget> _buildSendingContent() {                                   // Retourne la liste de widgets pour l'état "sending"
    return [
      const CircularProgressIndicator(color: Colors.red),                   // Indicateur de chargement (spinner)
      const SizedBox(height: 24),
      const Text(
        'Envoi de l\'alerte en cours...',                                    // Message pendant l'attente simulée
        style: TextStyle(fontSize: 16),
      ),
    ];
  }

  /// Contenu affiché une fois l'envoi "confirmé" : reprend maintenant la
  /// cause et l'heure exacte de l'alerte SOS qui vient d'être enregistrée.
  List<Widget> _buildSentContent() {                                      // Retourne la liste de widgets pour l'état "sent"
    final alert = _lastAlert!;                                             // Toujours défini à ce stade (assigné dans _triggerSos)
    return [
      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 80), // Icône de confirmation
      const SizedBox(height: 24),
      const Text(
        'Alerte envoyée avec succès',                                       // Titre de confirmation
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'Vos proches et l\'équipe médicale ont été notifiés.',                // Sous-texte explicatif
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
      const SizedBox(height: 24),
      Card(                                                                  // --- Détails de l'alerte : cause + heure ---
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey), // Icône d'information
                  const SizedBox(width: 6),
                  const Text('Détails de l\'alerte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Text('Cause : ${alert.title}'),                                 // "Alerte SOS manuelle"
              const SizedBox(height: 4),
              Text('Patient : ${alert.patient}'),                             // Patient concerné
              const SizedBox(height: 4),
              Text('Heure : ${alert.date}'),                                  // Heure exacte du déclenchement
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => context.push('/alerts'),                           // Permet de voir l'historique complet directement
        child: const Text('Voir l\'historique des alertes'),
      ),
      TextButton(
        onPressed: () => setState(() {                                      // Réinitialise l'écran (utile pour la démo)
          _state = _SosState.idle;
          _lastAlert = null;
        }),
        child: const Text('Revenir à l\'écran initial'),
      ),
    ];
  }
}