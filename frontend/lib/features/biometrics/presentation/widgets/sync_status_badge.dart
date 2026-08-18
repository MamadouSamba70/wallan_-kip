import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../viewmodels/biometric_sync_viewmodel.dart';

/// Petit badge affichant l'état de la synchronisation hors-ligne.
/// Pensé pour la démo du mardi (semaine 6) : coupure réseau -> le compteur
/// monte -> reconnexion -> le compteur retombe à zéro tout seul.
///
/// Utilisation typique : à placer dans l'AppBar du dashboard patient/device,
/// à côté de l'indicateur de connexion Bluetooth existant.
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(biometricSyncViewModelProvider);

    // Tout est synchronisé et rien n'est en cours -> pas besoin d'occuper l'écran.
    if (state.pendingCount == 0 && !state.isSyncing) {
      return const SizedBox.shrink();
    }

    final color = state.lastError != null
        ? AppTheme.warningOrange
        : AppTheme.primaryBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: state.isSyncing
          ? null
          : () => ref.read(biometricSyncViewModelProvider.notifier).syncNow(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isSyncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(Icons.cloud_off_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              state.isSyncing
                  ? 'Synchronisation…'
                  : '${state.pendingCount} en attente',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
