import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/core/constants/clinical_standards.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> createTestDatabase() async {
    return await openDatabase(
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
  }

  group('Database Foreign Keys & Cascading Deletions (CRIT-04)', () {
    test('PRAGMA foreign_keys is actively enabled on connection', () async {
      final db = await createTestDatabase();
      addTearDown(db.close);

      final result = await db.rawQuery('PRAGMA foreign_keys;');
      expect(result.first.values.first, equals(1));
    });

    test('rejection of orphan child records when member does not exist', () async {
      final db = await createTestDatabase();
      addTearDown(db.close);

      final bp = BpReading(
        id: 'orphan_bp_1',
        memberId: 'non_existent_member',
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        timestamp: DateTime.now(),
      );

      expect(
        () async => await db.insert('bp_readings', bp.toMap()),
        throwsA(isA<DatabaseException>()),
      );

      final glucose = GlucoseReading(
        id: 'orphan_glu_1',
        memberId: 'non_existent_member',
        valueMgDl: 100,
        mealContext: MealContext.fasting,
        timestamp: DateTime.now(),
      );

      expect(
        () async => await db.insert('glucose_readings', glucose.toMap()),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('deleting a family member cascades and atomically deletes all associated readings', () async {
      final db = await createTestDatabase();
      addTearDown(db.close);

      const member = FamilyMember(
        id: 'member_cascade_test',
        name: 'John Doe',
        relation: 'Self',
        age: 40,
        colorValue: 0xFF1E88E5,
        avatarEmoji: '🧑',
      );

      await db.insert('family_members', member.toMap());

      // Insert 2 BP readings
      for (int i = 1; i <= 2; i++) {
        final bp = BpReading(
          id: 'bp_cascade_$i',
          memberId: member.id,
          systolic: 120 + i,
          diastolic: 80 + i,
          pulse: 70,
          timestamp: DateTime.now(),
        );
        await db.insert('bp_readings', bp.toMap());
      }

      // Insert 2 Glucose readings
      for (int i = 1; i <= 2; i++) {
        final glucose = GlucoseReading(
          id: 'glu_cascade_$i',
          memberId: member.id,
          valueMgDl: 95.0 + i,
          mealContext: MealContext.fasting,
          timestamp: DateTime.now(),
        );
        await db.insert('glucose_readings', glucose.toMap());
      }

      // Verify records exist before delete
      final bpBefore = await db.query('bp_readings', where: 'memberId = ?', whereArgs: [member.id]);
      final gluBefore = await db.query('glucose_readings', where: 'memberId = ?', whereArgs: [member.id]);
      expect(bpBefore.length, equals(2));
      expect(gluBefore.length, equals(2));

      // Execute atomic transaction delete of family member
      await db.transaction((txn) async {
        await txn.delete('family_members', where: 'id = ?', whereArgs: [member.id]);
      });

      // Verify member is deleted
      final membersAfter = await db.query('family_members', where: 'id = ?', whereArgs: [member.id]);
      expect(membersAfter, isEmpty);

      // Verify cascading delete removed all associated BP readings
      final bpAfter = await db.query('bp_readings', where: 'memberId = ?', whereArgs: [member.id]);
      expect(bpAfter, isEmpty);

      // Verify cascading delete removed all associated Glucose readings
      final gluAfter = await db.query('glucose_readings', where: 'memberId = ?', whereArgs: [member.id]);
      expect(gluAfter, isEmpty);
    });

    test('transaction atomicity: rolled back transaction does not mutate data', () async {
      final db = await createTestDatabase();
      addTearDown(db.close);

      const member = FamilyMember(
        id: 'member_rollback_test',
        name: 'Jane Doe',
        relation: 'Mom',
        age: 65,
        colorValue: 0xFFE91E63,
        avatarEmoji: '👩',
      );
      await db.insert('family_members', member.toMap());

      try {
        await db.transaction((txn) async {
          await txn.delete('family_members', where: 'id = ?', whereArgs: [member.id]);
          // Simulate sudden failure inside transaction
          throw Exception('Simulated crash during transaction');
        });
      } catch (_) {}

      // Verify member still exists due to rollback
      final members = await db.query('family_members', where: 'id = ?', whereArgs: [member.id]);
      expect(members.length, equals(1));
    });
  });
}
