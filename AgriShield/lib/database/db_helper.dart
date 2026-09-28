import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "AgriShieldOffline.db";
  static const _databaseVersion = 9;

  // ─── Table names ────────────────────────────────────────────────────────────
  static const tableTickets       = 'referral_tickets';
  static const tablePestLogs      = 'pest_logs';
  static const tableRiskAssess    = 'risk_assessments';
  static const tableSyncQueue     = 'sync_queue';
  static const tableActiveLearning= 'active_learning_queue';
  static const tableSoilHealth    = 'soil_health_cache';


  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // ── referral_tickets ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableTickets (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_code     TEXT UNIQUE,
        farmer_name     TEXT NOT NULL,
        phone_number    TEXT,
        field_id        TEXT,
        crop_name       TEXT NOT NULL,
        reported_symptoms TEXT,
        image_url       TEXT,
        ai_prediction   TEXT,
        ai_confidence   REAL,
        assigned_lab    TEXT,
        status          TEXT NOT NULL DEFAULT 'PENDING_REVIEW',
        expert_diagnosis TEXT,
        expert_advisory  TEXT,
        created_at      TEXT NOT NULL,
        synced          INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── pest_logs ───────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tablePestLogs (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        field_id        TEXT NOT NULL,
        crop_name       TEXT NOT NULL,
        pest_name       TEXT NOT NULL,
        metric_type     TEXT NOT NULL,
        observed_value  REAL NOT NULL,
        status          TEXT,
        advisory        TEXT,
        timestamp       TEXT NOT NULL,
        synced          INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── risk_assessments ────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableRiskAssess (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        field_id        INTEGER,
        crop_type       TEXT,
        crop_variety    TEXT,
        growth_stage    TEXT,
        diseases_json   TEXT,
        summary         TEXT,
        recommendation  TEXT,
        forecast_json   TEXT,
        ipm_json        TEXT,
        avg_temp        REAL,
        avg_humidity    REAL,
        timestamp       TEXT NOT NULL
      )
    ''');

    // ── sync_queue ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint    TEXT NOT NULL,
        method      TEXT NOT NULL DEFAULT 'POST',
        payload     TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        retries     INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── active_learning_queue ───────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableActiveLearning (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_id       TEXT NOT NULL,
        crop            TEXT NOT NULL,
        disease         TEXT NOT NULL,
        image_path      TEXT,
        weather_vector  TEXT NOT NULL,
        farmer_feedback TEXT NOT NULL,
        created_at      TEXT NOT NULL
      )
    ''');
    // ── soil_health_cache ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tableSoilHealth (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        lat             REAL NOT NULL,
        lng             REAL NOT NULL,
        soil_type       TEXT NOT NULL,
        ph_level        REAL NOT NULL,
        nitrogen_N      REAL NOT NULL,
        phosphorus_P    REAL NOT NULL,
        potassium_K     REAL NOT NULL,
        recommended_crops TEXT NOT NULL,
        cached_at       TEXT NOT NULL
      )
    ''');

    await _seedMockTickets(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop and recreate on upgrade for simplicity during development
    await db.execute('DROP TABLE IF EXISTS $tableTickets');
    await db.execute('DROP TABLE IF EXISTS $tablePestLogs');
    await db.execute('DROP TABLE IF EXISTS $tableRiskAssess');
    await db.execute('DROP TABLE IF EXISTS $tableSyncQueue');
    await db.execute('DROP TABLE IF EXISTS $tableActiveLearning');
    await db.execute('DROP TABLE IF EXISTS $tableSoilHealth');

    await _onCreate(db, newVersion);
  }

  Future<void> _seedMockTickets(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert(tableTickets, {
      'ticket_code': 'TKT-MAH-2026-A97EA826',
      'farmer_name': 'Rajesh Patil',
      'phone_number': '9876543210',
      'field_id': 'FIELD-001',
      'crop_name': 'Cotton',
      'reported_symptoms': 'Leaf Curl Virus symptoms on lower leaves, stunted growth.',
      'ai_prediction': 'Cotton Leaf Curl Virus',
      'ai_confidence': 0.94,
      'assigned_lab': 'Nashik KVK Diagnostic Centre',
      'status': 'EXPERT_DIAGNOSED',
      'expert_diagnosis': 'Cotton Leaf Curl Virus confirmed. Apply Imidacloprid.',
      'created_at': now,
      'synced': 1,
    });
    await db.insert(tableTickets, {
      'ticket_code': 'TKT-MAH-2026-2BCE002B',
      'farmer_name': 'Rajesh Patil',
      'phone_number': '9876543210',
      'field_id': 'FIELD-002',
      'crop_name': 'Soybean',
      'reported_symptoms': 'Pod discoloration, water-soaked lesions on pods.',
      'ai_prediction': 'Soybean Pod Blight',
      'ai_confidence': 0.87,
      'assigned_lab': 'Jalgaon Sub-Center',
      'status': 'PENDING_REVIEW',
      'created_at': now,
      'synced': 1,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  REFERRAL TICKETS
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> insertTicket(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(tableTickets, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllTickets() async {
    final db = await database;
    return await db.query(tableTickets, orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getTicketByCode(String code) async {
    final db = await database;
    final rows = await db.query(tableTickets, where: 'ticket_code = ?', whereArgs: [code]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> updateTicketStatus(String code, String status, {String? diagnosis, String? advisory}) async {
    final db = await database;
    final data = <String, dynamic>{'status': status};
    if (diagnosis != null) data['expert_diagnosis'] = diagnosis;
    if (advisory != null) data['expert_advisory'] = advisory;
    return await db.update(tableTickets, data, where: 'ticket_code = ?', whereArgs: [code]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PEST LOGS
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> insertPestLog(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(tablePestLogs, row);
  }

  Future<List<Map<String, dynamic>>> getPestLogs({String? fieldId, int limit = 20}) async {
    final db = await database;
    if (fieldId != null) {
      return await db.query(tablePestLogs,
          where: 'field_id = ?', whereArgs: [fieldId],
          orderBy: 'id DESC', limit: limit);
    }
    return await db.query(tablePestLogs, orderBy: 'id DESC', limit: limit);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RISK ASSESSMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> insertRiskAssessment(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(tableRiskAssess, row);
  }

  Future<Map<String, dynamic>?> getLatestAssessment() async {
    final db = await database;
    final rows = await db.query(tableRiskAssess, orderBy: 'id DESC', limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ACTIVE LEARNING QUEUE
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> enqueueActiveLearning(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(tableActiveLearning, data);
  }

  Future<List<Map<String, dynamic>>> getPendingActiveLearningItems() async {
    final db = await database;
    return await db.query(tableActiveLearning, orderBy: 'id ASC', limit: 10);
  }

  Future<int> deleteActiveLearningItem(int id) async {
    final db = await database;
    return await db.delete(tableActiveLearning, where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SYNC QUEUE
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> enqueueSync(String endpoint, String method, String payload) async {
    final db = await database;
    return await db.insert(tableSyncQueue, {
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'retries': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(tableSyncQueue, orderBy: 'id ASC', limit: 10);
  }

  Future<int> deleteSyncItem(int id) async {
    final db = await database;
    return await db.delete(tableSyncQueue, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> incrementSyncRetry(int id) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE $tableSyncQueue SET retries = retries + 1 WHERE id = ?', [id]);
  }

  Future<int> getSyncQueueCount() async {
    final db = await database;
    final res1 = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableSyncQueue');
    final res2 = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableActiveLearning');
    final cnt1 = (res1.first['cnt'] as int?) ?? 0;
    final cnt2 = (res2.first['cnt'] as int?) ?? 0;
    return cnt1 + cnt2;
  }
  // ── Soil Health Cache ───────────────────────────────────────────────────────

  Future<void> cacheSoilHealth(double lat, double lng, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(tableSoilHealth, {
      'lat': lat,
      'lng': lng,
      'soil_type': data['soil_type'],
      'ph_level': data['ph_level'],
      'nitrogen_N': data['nitrogen_N'],
      'phosphorus_P': data['phosphorus_P'],
      'potassium_K': data['potassium_K'],
      'recommended_crops': (data['recommended_crops'] as List).join(','),
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getCachedSoilHealth() async {
    final db = await database;
    // Just get the most recent one
    final res = await db.query(tableSoilHealth, orderBy: 'id DESC', limit: 1);
    if (res.isNotEmpty) {
      final row = res.first;
      return {
        'soil_type': row['soil_type'],
        'ph_level': row['ph_level'],
        'nitrogen_N': row['nitrogen_N'],
        'phosphorus_P': row['phosphorus_P'],
        'potassium_K': row['potassium_K'],
        'recommended_crops': (row['recommended_crops'] as String).split(','),
      };
    }
    return null;
  }
}
