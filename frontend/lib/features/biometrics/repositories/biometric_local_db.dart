import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/biometric_reading_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POURQUOI SQLite ici et pas flutter_secure_storage (comme les tokens) ?
//
// TokenStorage stocke 2-3 valeurs simples (clé/valeur chiffrées).
// Ici on doit stocker un nombre variable de mesures en attente (potentiellement
// des centaines après une coupure réseau prolongée — semaine 7), les lister,
// les filtrer par statut, les purger. C'est un vrai besoin de base de données
// relationnelle locale, donc SQLite est l'outil adapté.
// ─────────────────────────────────────────────────────────────────────────────

/// Accès bas niveau à la table SQLite des mesures biométriques en attente.
/// N'est jamais utilisé directement par l'UI — passe toujours par
/// [BiometricRepository] qui orchestre API + local.
class BiometricLocalDb {
  static Database? _db;
  static const String _table = 'pending_biometric_readings';

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'wallan_offline.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id TEXT NOT NULL,
            device_id TEXT NOT NULL,
            heart_rate INTEGER NOT NULL,
            temperature REAL NOT NULL,
            spo2 INTEGER NOT NULL,
            movement_data TEXT,
            recorded_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  /// Insère une mesure en attente (mode hors-ligne).
  Future<int> insert(BiometricReadingModel reading) async {
    final db = await _database;
    return db.insert(_table, {
      'patient_id': reading.patientId,
      'device_id': reading.deviceId,
      'heart_rate': reading.heartRate,
      'temperature': reading.temperature,
      'spo2': reading.spo2,
      'movement_data':
          reading.movementData != null ? _encodeMap(reading.movementData!) : null,
      'recorded_at': reading.recordedAt.toUtc().toIso8601String(),
      'is_synced': 0,
    });
  }

  /// Récupère les mesures pas encore synchronisées, les plus anciennes d'abord.
  /// [limit] borne la taille d'un lot (utile pour l'envoi par paquets — semaine 7).
  Future<List<BiometricReadingModel>> fetchPending({int? limit}) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'is_synced = 0',
      orderBy: 'recorded_at ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  /// Nombre de mesures en attente — utilisé pour le badge dans l'UI.
  Future<int> countPending() async {
    final db = await _database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM $_table WHERE is_synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Marque une liste de mesures comme envoyées avec succès.
  Future<void> markSynced(List<int> localIds) async {
    if (localIds.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final id in localIds) {
      batch.update(_table, {'is_synced': 1},
          where: 'local_id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  /// Purge les mesures déjà synchronisées et anciennes de plus de [days] jours,
  /// pour que la base locale ne grossisse pas indéfiniment.
  Future<int> purgeSynced({int days = 7}) async {
    final db = await _database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toUtc();
    return db.delete(
      _table,
      where: 'is_synced = 1 AND recorded_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  BiometricReadingModel _fromRow(Map<String, dynamic> row) {
    return BiometricReadingModel(
      localId: row['local_id'] as int,
      patientId: row['patient_id'] as String,
      deviceId: row['device_id'] as String,
      heartRate: row['heart_rate'] as int,
      temperature: (row['temperature'] as num).toDouble(),
      spo2: row['spo2'] as int,
      movementData: row['movement_data'] != null
          ? _decodeMap(row['movement_data'] as String)
          : null,
      recordedAt: DateTime.parse(row['recorded_at'] as String),
      isSynced: (row['is_synced'] as int) == 1,
    );
  }

  // Évite d'ajouter dart:convert juste pour un encodage minimal des 3 clés x/y/z.
  String _encodeMap(Map<String, dynamic> map) =>
      map.entries.map((e) => '${e.key}:${e.value}').join(',');

  Map<String, dynamic> _decodeMap(String raw) {
    final map = <String, dynamic>{};
    for (final pair in raw.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) map[parts[0]] = double.tryParse(parts[1]) ?? parts[1];
    }
    return map;
  }
}

/// Provider Riverpod du DB local — un seul accès partagé dans toute l'app.
final biometricLocalDbProvider = Provider<BiometricLocalDb>((ref) {
  return BiometricLocalDb();
});
