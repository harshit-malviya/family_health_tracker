import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CRIT-12 Backup & Restore Security & Validation Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await openDatabase(
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
        },
      );
      DatabaseHelper.setTestDatabase(testDb);
    });

    tearDown(() async {
      await testDb.close();
      DatabaseHelper.setTestDatabase(null);
    });

    test('importFromJson rejects non-map or invalid root JSON safely', () async {
      expect(await DatabaseHelper.instance.importFromJson('not-json'), isFalse);
      expect(await DatabaseHelper.instance.importFromJson('[]'), isFalse);
      expect(await DatabaseHelper.instance.importFromJson('""'), isFalse);
      expect(await DatabaseHelper.instance.importFromJson('null'), isFalse);
    });

    test('importFromJson imports valid health data correctly', () async {
      final validJson = jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'family_members': [
          {
            'id': 'member_alice',
            'name': 'Alice Doe',
            'relation': 'Self',
            'age': 35,
            'dateOfBirth': '1991-05-15',
            'colorValue': 0xFF2196F3,
            'avatarEmoji': '👩',
          }
        ],
        'bp_readings': [
          {
            'id': 'bp_1',
            'memberId': 'member_alice',
            'systolic': 120,
            'diastolic': 80,
            'pulse': 72,
            'arm': 'Left',
            'posture': 'Sitting',
            'hasArrhythmia': 0,
            'notes': 'Normal check',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
        'glucose_readings': [
          {
            'id': 'glucose_1',
            'memberId': 'member_alice',
            'valueMgDl': 95.5,
            'mealContext': 'Fasting',
            'medicationNotes': 'None',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      });

      final success = await DatabaseHelper.instance.importFromJson(validJson);
      expect(success, isTrue);

      final members = await DatabaseHelper.instance.getMembers();
      expect(members.length, 1);
      expect(members.first.name, 'Alice Doe');

      final bpList = await DatabaseHelper.instance.getBpReadings('member_alice');
      expect(bpList.length, 1);
      expect(bpList.first.systolic, 120);

      final glucoseList = await DatabaseHelper.instance.getGlucoseReadings('member_alice');
      expect(glucoseList.length, 1);
      expect(glucoseList.first.valueMgDl, 95.5);
    });

    test('importFromJson discards corrupted and orphaned records without failing the valid transaction', () async {
      final mixedPayload = jsonEncode({
        'version': 1,
        'family_members': [
          // Valid
          {
            'id': 'member_bob',
            'name': 'Bob Smith',
            'relation': 'Father',
            'colorValue': 0xFF4CAF50,
            'avatarEmoji': '👨',
          },
          // Corrupt: empty id
          {
            'id': '   ',
            'name': 'Invalid ID',
            'relation': 'Unknown',
          },
          // Corrupt: missing name
          {
            'id': 'member_bad',
            'relation': 'Sibling',
          },
        ],
        'bp_readings': [
          // Valid reading for Bob
          {
            'id': 'bp_valid_bob',
            'memberId': 'member_bob',
            'systolic': 118,
            'diastolic': 76,
            'pulse': 68,
            'arm': 'Right',
            'posture': 'Sitting',
            'hasArrhythmia': 0,
            'timestamp': '2026-10-01T12:00:00.000Z',
          },
          // Corrupt: non-existent/orphaned memberId
          {
            'id': 'bp_orphan',
            'memberId': 'member_nonexistent',
            'systolic': 130,
            'diastolic': 85,
            'pulse': 75,
            'timestamp': '2026-10-01T12:00:00.000Z',
          },
          // Corrupt: invalid systolic format
          {
            'id': 'bp_corrupt_systolic',
            'memberId': 'member_bob',
            'systolic': 'not_a_number',
            'diastolic': 80,
            'pulse': 70,
            'timestamp': '2026-10-01T12:00:00.000Z',
          },
          // Corrupt: invalid timestamp
          {
            'id': 'bp_corrupt_time',
            'memberId': 'member_bob',
            'systolic': 120,
            'diastolic': 80,
            'pulse': 70,
            'timestamp': 'invalid-date-format',
          },
        ],
        'glucose_readings': [
          // Valid reading for Bob
          {
            'id': 'glucose_valid_bob',
            'memberId': 'member_bob',
            'valueMgDl': 105.0,
            'mealContext': 'BeforeMeal',
            'timestamp': '2026-10-01T12:30:00.000Z',
          },
          // Corrupt: orphaned member
          {
            'id': 'glucose_orphan',
            'memberId': 'ghost_member',
            'valueMgDl': 110.0,
            'mealContext': 'Random',
            'timestamp': '2026-10-01T12:30:00.000Z',
          },
          // Corrupt: missing value
          {
            'id': 'glucose_bad_val',
            'memberId': 'member_bob',
            'valueMgDl': 'invalid',
            'timestamp': '2026-10-01T12:30:00.000Z',
          },
        ],
      });

      final success = await DatabaseHelper.instance.importFromJson(mixedPayload);
      expect(success, isTrue);

      // Verify only valid records were saved
      final members = await DatabaseHelper.instance.getMembers();
      expect(members.length, 1);
      expect(members.first.id, 'member_bob');

      final bpList = await DatabaseHelper.instance.getBpReadings('member_bob');
      expect(bpList.length, 1);
      expect(bpList.first.id, 'bp_valid_bob');

      final glucoseList = await DatabaseHelper.instance.getGlucoseReadings('member_bob');
      expect(glucoseList.length, 1);
      expect(glucoseList.first.id, 'glucose_valid_bob');
    });
  });
}
