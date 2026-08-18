import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/biometric_repository.dart';

/// État réactif de la synchronisation hors-ligne, affiché dans l'UI
/// (badge "3 mesures en attente", bouton "Synchroniser maintenant", etc).
class BiometricSyncState {
  final int pendingCount;
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final String? lastError;

  const BiometricSyncState({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastSyncAt,
    this.lastError,
  });

  BiometricSyncState copyWith({
    int? pendingCount,
    bool? isSyncing,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) {
    return BiometricSyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class BiometricSyncViewModel extends Notifier<BiometricSyncState> {
  StreamSubscription<ConnectivityResult>? _subscription;

  @override
  BiometricSyncState build() {
    _refreshPendingCount();

    // Dès que la connectivité change (Wi-Fi/4G revient), on tente une sync.
    // Note : connectivity_plus 5.x renvoie un seul ConnectivityResult par
    // évènement (les versions 6.x+ renvoient une List — pas notre cas ici).
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      if (isOnline) syncNow();
    });

    // Nettoyage de l'abonnement quand le provider est détruit.
    ref.onDispose(() => _subscription?.cancel());

    return const BiometricSyncState();
  }

  Future<void> _refreshPendingCount() async {
    final repo = ref.read(biometricRepositoryProvider);
    final count = await repo.countPending();
    state = state.copyWith(pendingCount: count);
  }

  /// Déclenche une synchronisation manuelle ou automatique.
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final repo = ref.read(biometricRepositoryProvider);
      final result = await repo.syncPending();
      final remaining = await repo.countPending();

      state = state.copyWith(
        isSyncing: false,
        pendingCount: remaining,
        lastSyncAt: DateTime.now(),
        lastError: result.failedCount > 0
            ? '${result.failedCount} mesure(s) n\'ont pas pu être synchronisées'
            : null,
        clearError: result.failedCount == 0,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: 'Erreur de synchronisation : ${e.toString()}',
      );
    }
  }

  /// À appeler après l'insertion d'une nouvelle mesure hors-ligne.
  Future<void> notifyNewPendingReading() => _refreshPendingCount();
}

/// Provider Riverpod du ViewModel de synchronisation.
final biometricSyncViewModelProvider =
    NotifierProvider<BiometricSyncViewModel, BiometricSyncState>(() {
  return BiometricSyncViewModel();
});