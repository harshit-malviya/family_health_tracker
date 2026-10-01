import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/family_member.dart';
import '../../models/bp_reading.dart';
import '../../models/glucose_reading.dart';
import '../constants/app_colors.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      version: 3,
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
    await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
    await db.delete('bp_readings', where: 'memberId = ?', whereArgs: [id]);
    await db.delete('glucose_readings', where: 'memberId = ?', whereArgs: [id]);
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
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await instance.database;

      await db.transaction((txn) async {
        if (data.containsKey('family_members')) {
          for (final m in data['family_members'] as List) {
            await txn.insert('family_members', m as Map<String, dynamic>,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        if (data.containsKey('bp_readings')) {
          for (final b in data['bp_readings'] as List) {
            await txn.insert('bp_readings', b as Map<String, dynamic>,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        if (data.containsKey('glucose_readings')) {
          for (final g in data['glucose_readings'] as List) {
            await txn.insert('glucose_readings', g as Map<String, dynamic>,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
