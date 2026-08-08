import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/alert_model.dart';
import '../../viewmodels/alerts_viewmodel.dart';

enum _SosState { idle, sending, sent, error }

/// Écran Urgence SOS — POST /api/alerts/ réel via AlertsViewModel.triggerSos().
///
/// Le schéma Alert n'a pas de notion de "SOS manuel" (voir alert_model.dart) :
/// l'alerte créée utilise alert_type='movement' / severity='critical' avec
/// des valeurs symboliques. Côté backend, sa création déclenche automatiquement
/// l'envoi de vraies notifications SMS/Push (alerts/services.py).
///
/// Contrairement à la version précédente, il n'y a plus de repli "alerte
/// locale fictive" si le patient lié est introuvable : dans une app médicale,
/// mieux vaut un échec explicite qu'un faux succès. Voir _buildErrorContent.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  _SosState _state = _SosState.idle;
  AlertModel? _lastAlert;
  String? _errorMessage;

  Future<void> _triggerSos() async {
    setState(() => _state = _SosState.sending);
    try {
      final created = await ref.read(alertsViewModelProvider.notifier).triggerSos();
      if (!mounted) return;
      setState(() {
        _lastAlert = created;
        _state = _SosState.sent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('StateError: Bad state: ', '').replaceAll('Exception: ', '');
        _state = _SosState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urgence SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_state == _SosState.idle) ..._buildIdleContent(),
                if (_state == _SosState.sending) ..._buildSendingContent(),
                if (_state == _SosState.sent) ..._buildSentContent(),
                if (_state == _SosState.error) ..._buildErrorContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIdleContent() {
    return [
      const Text(
        'En cas d\'urgence, appuyez sur le bouton ci-dessous',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 32),
      GestureDetector(
        onTap: _triggerSos,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sos_rounded, color: Colors.white, size: 48),
              SizedBox(height: 4),
              Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSendingContent() {
    return [
      const CircularProgressIndicator(color: Colors.red),
      const SizedBox(height: 24),
      const Text('Envoi de l\'alerte en cours...', style: TextStyle(fontSize: 16)),
    ];
  }

  List<Widget> _buildSentContent() {
    final alert = _lastAlert!;
    return [
      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 80),
      const SizedBox(height: 24),
      const Text(
        'Alerte envoyée avec succès',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'Vos proches et l\'équipe médicale ont été notifiés (SMS/Push).',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('Détails de l\'alerte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Text('Patient : ${alert.patientName}'),
              const SizedBox(height: 4),
              Text('Heure : ${formatFrenchDateTime(alert.createdAt)}'),
              const SizedBox(height: 4),
              Text('Référence : #${alert.id.substring(0, alert.id.length.clamp(0, 8))}'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => context.push('/alerts'),
        child: const Text('Voir l\'historique des alertes'),
      ),
      TextButton(
        onPressed: () => setState(() {
          _state = _SosState.idle;
          _lastAlert = null;
        }),
        child: const Text('Revenir à l\'écran initial'),
      ),
    ];
  }

  List<Widget> _buildErrorContent() {
    return [
      Icon(Icons.error_rounded, color: Colors.red.shade600, size: 80),
      const SizedBox(height: 24),
      const Text(
        'Impossible d\'envoyer l\'alerte',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        _errorMessage ?? 'Une erreur est survenue.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => setState(() => _state = _SosState.idle),
        child: const Text('Réessayer'),
      ),
    ];
  }
}
