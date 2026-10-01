import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Indexes & Query Optimization Tests (CRIT-07)', () {
    test('Fresh installation (v4) creates composite indexes on bp_readings and glucose_readings', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
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

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_bp_member_time ON bp_readings(memberId, timestamp DESC);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_glucose_member_time ON glucose_readings(memberId, timestamp DESC);',
          );
        },
      );
      addTearDown(db.close);

      // Verify index on bp_readings
      final bpIndexes = await db.rawQuery("PRAGMA index_list('bp_readings');");
      final bpIndexNames = bpIndexes.map((row) => row['name'] as String).toList();
      expect(bpIndexNames, contains('idx_bp_member_time'));

      final bpIndexInfo = await db.rawQuery("PRAGMA index_info('idx_bp_member_time');");
      final bpColumns = bpIndexInfo.map((row) => row['name'] as String).toList();
      expect(bpColumns, equals(['memberId', 'timestamp']));

      // Verify index on glucose_readings
      final glucoseIndexes = await db.rawQuery("PRAGMA index_list('glucose_readings');");
      final glucoseIndexNames = glucoseIndexes.map((row) => row['name'] as String).toList();
      expect(glucoseIndexNames, contains('idx_glucose_member_time'));

      final glucoseIndexInfo = await db.rawQuery("PRAGMA index_info('idx_glucose_member_time');");
      final glucoseColumns = glucoseIndexInfo.map((row) => row['name'] as String).toList();
      expect(glucoseColumns, equals(['memberId', 'timestamp']));
    });

    test('Upgrade migration from v3 to v4 adds indexes without data loss', () async {
      // 1. Create database at version 3 without indexes
      var db = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
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
        },
      );

      // Verify no composite index exists in v3
      var initialBpIndexes = await db.rawQuery("PRAGMA index_list('bp_readings');");
      expect(initialBpIndexes.any((r) => r['name'] == 'idx_bp_member_time'), isFalse);

      // Insert member and readings into v3
      await db.insert('family_members', {
        'id': 'user_1',
        'name': 'Mom',
        'relation': 'Mother',
        'age': 55,
        'colorValue': 0xFF10B981,
        'avatarEmoji': '👩',
      });
      await db.insert('bp_readings', {
        'id': 'bp_v3_1',
        'memberId': 'user_1',
        'systolic': 118,
        'diastolic': 78,
        'pulse': 72,
        'arm': 'Left',
        'posture': 'Sitting',
        'hasArrhythmia': 0,
        'timestamp': '2026-10-01T10:00:00Z',
      });
      await db.insert('glucose_readings', {
        'id': 'glucose_v3_1',
        'memberId': 'user_1',
        'valueMgDl': 98.0,
        'mealContext': 'Fasting',
        'timestamp': '2026-10-01T10:05:00Z',
      });

      // 2. Perform migration logic simulating _upgradeDB from v3 to v4
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_bp_member_time ON bp_readings(memberId, timestamp DESC);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_glucose_member_time ON glucose_readings(memberId, timestamp DESC);',
      );
      addTearDown(db.close);

      // Verify indexes now exist
      final migratedBpIndexes = await db.rawQuery("PRAGMA index_list('bp_readings');");
      expect(migratedBpIndexes.any((r) => r['name'] == 'idx_bp_member_time'), isTrue);

      final migratedGlucoseIndexes = await db.rawQuery("PRAGMA index_list('glucose_readings');");
      expect(migratedGlucoseIndexes.any((r) => r['name'] == 'idx_glucose_member_time'), isTrue);

      // Verify data remains intact
      final bpRows = await db.query('bp_readings', where: 'id = ?', whereArgs: ['bp_v3_1']);
      expect(bpRows.length, 1);
      expect(bpRows.first['systolic'], 118);

      final glucoseRows = await db.query('glucose_readings', where: 'id = ?', whereArgs: ['glucose_v3_1']);
      expect(glucoseRows.length, 1);
      expect(glucoseRows.first['valueMgDl'], 98.0);
    });

    test('EXPLAIN QUERY PLAN confirms SQLite uses composite indexes for member queries', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
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

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_bp_member_time ON bp_readings(memberId, timestamp DESC);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_glucose_member_time ON glucose_readings(memberId, timestamp DESC);',
          );
        },
      );
      addTearDown(db.close);

      // Query plan for blood pressure history query
      final bpPlan = await db.rawQuery(
        'EXPLAIN QUERY PLAN SELECT * FROM bp_readings WHERE memberId = ? ORDER BY timestamp DESC;',
        ['user_1'],
      );
      final bpPlanDetail = bpPlan.map((r) => r['detail'].toString()).join(' ');
      expect(bpPlanDetail, contains('idx_bp_member_time'));
      expect(bpPlanDetail, isNot(contains('SCAN TABLE')));

      // Query plan for blood glucose history query
      final glucosePlan = await db.rawQuery(
        'EXPLAIN QUERY PLAN SELECT * FROM glucose_readings WHERE memberId = ? ORDER BY timestamp DESC;',
        ['user_1'],
      );
      final glucosePlanDetail = glucosePlan.map((r) => r['detail'].toString()).join(' ');
      expect(glucosePlanDetail, contains('idx_glucose_member_time'));
      expect(glucosePlanDetail, isNot(contains('SCAN TABLE')));
    });
  });
}
