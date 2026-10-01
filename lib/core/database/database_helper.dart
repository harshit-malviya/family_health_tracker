import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/family_member.dart';
import '../../models/bp_reading.dart';
import '../../models/glucose_reading.dart';

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
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE family_members ADD COLUMN dateOfBirth TEXT;');
    }
    if (oldVersion < 3) {
      // Clean mock seed data from earlier testing versions
      await db.delete('family_members', where: "id IN ('member_dad', 'member_mom', 'member_self')");
      await db.delete('bp_readings', where: "memberId IN ('member_dad', 'member_mom', 'member_self')");
      await db.delete('glucose_readings', where: "memberId IN ('member_dad', 'member_mom', 'member_self')");
    }
    if (oldVersion < 4) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_bp_member_time ON bp_readings(memberId, timestamp DESC);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_glucose_member_time ON glucose_readings(memberId, timestamp DESC);',
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
        avatarEmoji TEXT NOT NULL
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
        FOREIGN KEY (memberId) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

    // Composite indexes for fast filtered lookups and sorted history
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bp_member_time ON bp_readings(memberId, timestamp DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_glucose_member_time ON glucose_readings(memberId, timestamp DESC);',
    );
    // First-time users create their own family members via the Onboarding flow.
  }

  // --- Family Member Operations ---

  Future<List<FamilyMember>> getMembers() async {
    final db = await instance.database;
    final maps = await db.query('family_members');
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
    await db.transaction((txn) async {
      await txn.delete('family_members', where: 'id = ?', whereArgs: [id]);
    });
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

  Future<void> updateBp(BpReading reading) async {
    final db = await instance.database;
    await db.update(
      'bp_readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
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

  // --- Backup & Restore (JSON String) ---

  Future<String> exportToJson() async {
    final db = await instance.database;
    final members = await db.query('family_members');
    final bp = await db.query('bp_readings');
    final glucose = await db.query('glucose_readings');

    final exportData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'family_members': members,
      'bp_readings': bp,
      'glucose_readings': glucose,
    };

    return jsonEncode(exportData);
  }

  Future<bool> importFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      final db = await instance.database;

      await db.transaction((txn) async {
        // Collect existing member IDs to enforce foreign key integrity
        final existingMembers = await txn.query('family_members', columns: ['id']);
        final knownMemberIds = existingMembers
            .map((m) => m['id']?.toString())
            .whereType<String>()
            .toSet();

        // 1. Sanitize and insert family_members first
        if (decoded['family_members'] is List) {
          for (final raw in decoded['family_members'] as List) {
            if (raw is! Map) continue;
            final id = raw['id']?.toString();
            final name = raw['name']?.toString();
            final relation = raw['relation']?.toString();
            final avatarEmoji = raw['avatarEmoji']?.toString() ?? '👤';
            final colorValue = raw['colorValue'] is int
                ? raw['colorValue'] as int
                : int.tryParse(raw['colorValue']?.toString() ?? '') ?? 0xFF2196F3;

            if (id == null || id.trim().isEmpty || name == null || name.trim().isEmpty || relation == null) {
              continue; // Skip invalid records
            }

            final sanitized = <String, dynamic>{
              'id': id.trim(),
              'name': name.trim(),
              'relation': relation.trim(),
              'age': raw['age'] is int ? raw['age'] : int.tryParse(raw['age']?.toString() ?? ''),
              'dateOfBirth': raw['dateOfBirth']?.toString(),
              'colorValue': colorValue,
              'avatarEmoji': avatarEmoji,
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

            final mealContext = raw['mealContext']?.toString() ?? 'Random';

            final sanitized = <String, dynamic>{
              'id': id.trim(),
              'memberId': memberId.trim(),
              'valueMgDl': valueMgDl,
              'mealContext': mealContext,
              'medicationNotes': raw['medicationNotes']?.toString(),
              'timestamp': timestampStr,
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
