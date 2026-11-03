import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/family_member.dart';
import '../../models/bp_reading.dart';
import '../../models/glucose_reading.dart';
import '../../models/sync_queue_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  @visibleForTesting
  static void setTestDatabase(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('family_health_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entityType TEXT NOT NULL,
          entityId TEXT NOT NULL,
          action TEXT NOT NULL,
          payload TEXT,
          familyId TEXT NOT NULL,
          createdAt TEXT NOT NULL
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(createdAt ASC);',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Family Members Table
    await db.execute('''
      CREATE TABLE family_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        age INTEGER,
        dateOfBirth TEXT,
        colorValue INTEGER NOT NULL,
        avatarEmoji TEXT NOT NULL,
        familyId TEXT
      )
    ''');

    // Blood Pressure Readings Table
    await db.execute('''
      CREATE TABLE bp_readings (
        id TEXT PRIMARY KEY,
        memberId TEXT NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER NOT NULL,
        arm TEXT NOT NULL,
        posture TEXT NOT NULL,
        hasArrhythmia INTEGER NOT NULL,
        notes TEXT,
        timestamp TEXT NOT NULL,
        familyId TEXT,
        createdBy TEXT,
        loggedByName TEXT,
        FOREIGN KEY (memberId) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

    // Blood Glucose Readings Table
    await db.execute('''
      CREATE TABLE glucose_readings (
        id TEXT PRIMARY KEY,
        memberId TEXT NOT NULL,
        valueMgDl REAL NOT NULL,
        mealContext TEXT NOT NULL,
        medicationNotes TEXT,
        timestamp TEXT NOT NULL,
        familyId TEXT,
        createdBy TEXT,
        loggedByName TEXT,
        FOREIGN KEY (memberId) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT,
        familyId TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bp_member_time ON bp_readings(memberId, timestamp DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_glucose_member_time ON glucose_readings(memberId, timestamp DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(createdAt ASC);',
    );
  }

  // --- Family Member Operations ---

  Future<List<FamilyMember>> getMembers({String? familyId}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps;
    if (familyId != null && familyId.isNotEmpty) {
      maps = await db.query(
        'family_members',
        where: 'familyId = ? OR familyId IS NULL',
        whereArgs: [familyId],
      );
    } else {
      maps = await db.query('family_members');
    }
    return maps.map((m) => FamilyMember.fromMap(m)).toList();
  }

  Future<void> insertMember(FamilyMember member) async {
    final db = await instance.database;
    await db.insert(
      'family_members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMember(FamilyMember member) async {
    final db = await instance.database;
    await db.update(
      'family_members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteMember(String id) async {
    final db = await instance.database;
    await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }

  // --- Blood Pressure Operations ---

  Future<void> insertBp(BpReading reading) async {
    final db = await instance.database;
    await db.insert(
      'bp_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBp(BpReading reading) async {
    final db = await instance.database;
    await db.update(
      'bp_readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  Future<List<BpReading>> getBpReadings(String memberId) async {
    final db = await instance.database;
    final maps = await db.query(
      'bp_readings',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => BpReading.fromMap(m)).toList();
  }

  Future<void> deleteBp(String id) async {
    final db = await instance.database;
    await db.delete('bp_readings', where: 'id = ?', whereArgs: [id]);
  }

  // --- Blood Glucose Operations ---

  Future<void> insertGlucose(GlucoseReading reading) async {
    final db = await instance.database;
    await db.insert(
      'glucose_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGlucose(GlucoseReading reading) async {
    final db = await instance.database;
    await db.update(
      'glucose_readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) async {
    final db = await instance.database;
    final maps = await db.query(
      'glucose_readings',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => GlucoseReading.fromMap(m)).toList();
  }

  Future<void> deleteGlucose(String id) async {
    final db = await instance.database;
    await db.delete('glucose_readings', where: 'id = ?', whereArgs: [id]);
  }

  // --- Sync Queue Operations ---

  Future<int> enqueueSyncItem({
    required String entityType,
    required String entityId,
    required String action,
    String? payload,
    required String familyId,
  }) async {
    final db = await instance.database;
    return await db.insert('sync_queue', {
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'payload': payload,
      'familyId': familyId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<SyncQueueItem>> peekSyncQueue({int limit = 50}) async {
    final db = await instance.database;
    final maps = await db.query(
      'sync_queue',
      orderBy: 'id ASC',
      limit: limit,
    );
    return maps.map((m) => SyncQueueItem.fromMap(m)).toList();
  }

  Future<void> removeSyncQueueItem(int id) async {
    final db = await instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getSyncQueueCount() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_queue'),
    );
    return count ?? 0;
  }

  /// Clears local cache tables and sync queue (e.g. on account logout)
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('sync_queue');
      await txn.delete('glucose_readings');
      await txn.delete('bp_readings');
      await txn.delete('family_members');
    });
  }

  // --- Backup & Restore (JSON String) ---

  Future<String> exportToJson() async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final members = await txn.query('family_members');
      final bp = await txn.query('bp_readings');
      final glucose = await txn.query('glucose_readings');

      final data = {
        'version': 7,
        'exportedAt': DateTime.now().toIso8601String(),
        'family_members': members,
        'bp_readings': bp,
        'glucose_readings': glucose,
      };

      return jsonEncode(data);
    });
  }

  Future<bool> importFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return false;

      final db = await instance.database;

      await db.transaction((txn) async {
        // Clear existing data before restore
        await txn.delete('glucose_readings');
        await txn.delete('bp_readings');
        await txn.delete('family_members');

        final knownMemberIds = <String>{};

        // 1. Sanitize and insert family_members
        if (decoded['family_members'] is List) {
          for (final raw in decoded['family_members'] as List) {
            if (raw is! Map) continue;
            final id = raw['id']?.toString();
            final name = raw['name']?.toString();
            final relation = raw['relation']?.toString();
            final colorValue = raw['colorValue'] is int
                ? raw['colorValue'] as int
                : int.tryParse(raw['colorValue']?.toString() ?? '');
            final avatarEmoji = raw['avatarEmoji']?.toString();

            if (id == null ||
                id.trim().isEmpty ||
                name == null ||
                name.trim().isEmpty ||
                relation == null ||
                relation.trim().isEmpty ||
                colorValue == null ||
                avatarEmoji == null ||
                avatarEmoji.trim().isEmpty) {
              continue;
            }

            final age = raw['age'] is int
                ? raw['age'] as int
                : int.tryParse(raw['age']?.toString() ?? '');
            final dateOfBirth = raw['dateOfBirth']?.toString();
            final familyId = raw['familyId']?.toString();

            final sanitized = <String, dynamic>{
              'id': id.trim(),
              'name': name.trim(),
              'relation': relation.trim(),
              'age': age,
              'dateOfBirth': dateOfBirth,
              'colorValue': colorValue,
              'avatarEmoji': avatarEmoji.trim(),
              'familyId': familyId,
            };

            await txn.insert(
              'family_members',
              sanitized,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            knownMemberIds.add(id.trim());
          }
        }

        // 2. Sanitize and insert bp_readings
        if (decoded['bp_readings'] is List) {
          for (final raw in decoded['bp_readings'] as List) {
            if (raw is! Map) continue;
            final id = raw['id']?.toString();
            final memberId = raw['memberId']?.toString();
            final systolic = raw['systolic'] is int
                ? raw['systolic'] as int
                : int.tryParse(raw['systolic']?.toString() ?? '');
            final diastolic = raw['diastolic'] is int
                ? raw['diastolic'] as int
                : int.tryParse(raw['diastolic']?.toString() ?? '');
            final pulse = raw['pulse'] is int
                ? raw['pulse'] as int
                : int.tryParse(raw['pulse']?.toString() ?? '');
            final timestampStr = raw['timestamp']?.toString();

            if (id == null ||
                id.trim().isEmpty ||
                memberId == null ||
                !knownMemberIds.contains(memberId.trim()) ||
                systolic == null ||
                diastolic == null ||
                pulse == null ||
                timestampStr == null ||
                DateTime.tryParse(timestampStr) == null) {
              continue; // Skip invalid readings or orphaned records
            }

            final arm = raw['arm']?.toString() ?? 'Left';
            final posture = raw['posture']?.toString() ?? 'Sitting';
            final hasArrhythmia = (raw['hasArrhythmia'] == 1 || raw['hasArrhythmia'] == true) ? 1 : 0;

            final sanitized = <String, dynamic>{
              'id': id.trim(),
              'memberId': memberId.trim(),
              'systolic': systolic,
              'diastolic': diastolic,
              'pulse': pulse,
              'arm': arm,
              'posture': posture,
              'hasArrhythmia': hasArrhythmia,
              'notes': raw['notes']?.toString(),
              'timestamp': timestampStr,
              'familyId': raw['familyId']?.toString(),
              'createdBy': raw['createdBy']?.toString(),
              'loggedByName': raw['loggedByName']?.toString(),
            };

            await txn.insert(
              'bp_readings',
              sanitized,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // 3. Sanitize and insert glucose_readings
        if (decoded['glucose_readings'] is List) {
          for (final raw in decoded['glucose_readings'] as List) {
            if (raw is! Map) continue;
            final id = raw['id']?.toString();
            final memberId = raw['memberId']?.toString();
            final valueMgDl = raw['valueMgDl'] is num
                ? (raw['valueMgDl'] as num).toDouble()
                : double.tryParse(raw['valueMgDl']?.toString() ?? '');
            final timestampStr = raw['timestamp']?.toString();

            if (id == null ||
                id.trim().isEmpty ||
                memberId == null ||
                !knownMemberIds.contains(memberId.trim()) ||
                valueMgDl == null ||
                timestampStr == null ||
                DateTime.tryParse(timestampStr) == null) {
              continue; // Skip invalid or orphaned readings
            }

            final mealContext = raw['mealContext']?.toString() ?? 'fasting';

            final sanitized = <String, dynamic>{
              'id': id.trim(),
              'memberId': memberId.trim(),
              'valueMgDl': valueMgDl,
              'mealContext': mealContext,
              'medicationNotes': raw['medicationNotes']?.toString(),
              'timestamp': timestampStr,
              'familyId': raw['familyId']?.toString(),
              'createdBy': raw['createdBy']?.toString(),
              'loggedByName': raw['loggedByName']?.toString(),
            };

            await txn.insert(
              'glucose_readings',
              sanitized,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
