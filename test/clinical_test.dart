import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/core/constants/clinical_standards.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';

void main() {
  group('Clinical Standards - Blood Pressure Evaluation', () {
    test('Identifies Normal Blood Pressure', () {
      final category = ClinicalStandards.evaluateBp(115, 75);
      expect(category, BpCategory.normal);
    });

    test('Identifies Elevated Blood Pressure', () {
      final category = ClinicalStandards.evaluateBp(125, 78);
      expect(category, BpCategory.elevated);
    });

    test('Identifies Hypertension Stage 1', () {
      final category = ClinicalStandards.evaluateBp(132, 85);
      expect(category, BpCategory.stage1);
    });

    test('Identifies Hypertension Stage 2', () {
      final category = ClinicalStandards.evaluateBp(145, 95);
      expect(category, BpCategory.stage2);
    });

    test('Identifies Hypertensive Crisis', () {
      final category = ClinicalStandards.evaluateBp(185, 125);
      expect(category, BpCategory.crisis);
    });
  });

  group('Clinical Standards - Blood Glucose & Unit Conversion', () {
    test('Evaluates Fasting Blood Glucose correctly', () {
      expect(
        ClinicalStandards.evaluateGlucose(65, MealContext.fasting),
        GlucoseCategory.low,
      );
      expect(
        ClinicalStandards.evaluateGlucose(95, MealContext.fasting),
        GlucoseCategory.normal,
      );
      expect(
        ClinicalStandards.evaluateGlucose(145, MealContext.fasting),
        GlucoseCategory.elevated,
      );
      expect(
        ClinicalStandards.evaluateGlucose(210, MealContext.fasting),
        GlucoseCategory.high,
      );
    });

    test('Converts between mg/dL and mmol/L accurately', () {
      final mmol = ClinicalStandards.mgDlToMmol(180.182);
      expect(mmol, closeTo(10.0, 0.05));

      final mgDl = ClinicalStandards.mmolToMgDl(10.0);
      expect(mgDl, closeTo(180.18, 0.05));
    });
  });

  group('Data Models Serialization & Deserialization', () {
    test('FamilyMember serialization and date of birth age calculation', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 78, now.month, now.day);
      final member = FamilyMember(
        id: 'test_1',
        name: 'Grandpa',
        relation: 'Grandfather',
        dateOfBirth: dob,
        colorValue: 0xFF10B981,
        avatarEmoji: '👴',
      );

      expect(member.age, 78);

      final map = member.toMap();
      final restored = FamilyMember.fromMap(map);

      expect(restored.id, member.id);
      expect(restored.name, member.name);
      expect(restored.age, 78);
      expect(restored.dateOfBirth, dob);
      expect(restored.avatarEmoji, member.avatarEmoji);
    });

    test('BpReading serialization and computed category', () {
      final bp = BpReading(
        id: 'bp_1',
        memberId: 'test_1',
        systolic: 128,
        diastolic: 78,
        pulse: 68,
        timestamp: DateTime(2026, 10, 1, 8, 30),
      );

      expect(bp.category, BpCategory.elevated);

      final map = bp.toMap();
      final restored = BpReading.fromMap(map);

      expect(restored.systolic, 128);
      expect(restored.diastolic, 78);
      expect(restored.category, BpCategory.elevated);
    });

    test('GlucoseReading serialization and computed category', () {
      final glucose = GlucoseReading(
        id: 'glu_1',
        memberId: 'test_1',
        valueMgDl: 110,
        mealContext: MealContext.fasting,
        medicationNotes: 'Metformin',
        timestamp: DateTime(2026, 10, 1, 7, 0),
      );

      expect(glucose.category, GlucoseCategory.normal);
      expect(glucose.valueMmol, closeTo(6.1, 0.1));

      final map = glucose.toMap();
      final restored = GlucoseReading.fromMap(map);

      expect(restored.valueMgDl, 110);
      expect(restored.mealContext, MealContext.fasting);
      expect(restored.medicationNotes, 'Metformin');
    });

    test('BpReading past-date assignment and update', () {
      final pastDate = DateTime(2025, 4, 15, 9, 30);
      final bp = BpReading(
        id: 'bp_past',
        memberId: 'test_1',
        systolic: 142,
        diastolic: 92,
        pulse: 75,
        timestamp: pastDate,
      );

      expect(bp.timestamp, pastDate);
      expect(bp.category, BpCategory.stage2);

      // Simulate editing values and date
      final newPastDate = DateTime(2025, 4, 15, 18, 0);
      final updatedBp = BpReading(
        id: bp.id,
        memberId: bp.memberId,
        systolic: 124,
        diastolic: 76,
        pulse: 70,
        timestamp: newPastDate,
      );

      expect(updatedBp.id, bp.id);
      expect(updatedBp.systolic, 124);
      expect(updatedBp.category, BpCategory.elevated);
      expect(updatedBp.timestamp, newPastDate);
    });

    test('GlucoseReading past-date assignment and update', () {
      final pastDate = DateTime(2025, 1, 10, 8, 0);
      final glucose = GlucoseReading(
        id: 'glu_past',
        memberId: 'test_1',
        valueMgDl: 165,
        mealContext: MealContext.postMeal,
        timestamp: pastDate,
      );

      expect(glucose.timestamp, pastDate);
      expect(glucose.category, GlucoseCategory.normal); // post-meal <180 is normal

      // Simulate editing to fasting reading
      final updatedGlucose = GlucoseReading(
        id: glucose.id,
        memberId: glucose.memberId,
        valueMgDl: 165,
        mealContext: MealContext.fasting,
        timestamp: pastDate,
      );

      expect(updatedGlucose.category, GlucoseCategory.elevated); // fasting >130 is elevated
    });
  });

  group('Backup & Restore Payload Structure', () {
    test('Validates Health Tracker Backup JSON schema', () {
      final validJson = '''
      {
        "version": 1,
        "exportedAt": "2026-10-01T12:00:00.000Z",
        "family_members": [
          {
            "id": "mem_1",
            "name": "Papa",
            "relation": "Father",
            "dateOfBirth": "1965-05-15",
            "colorValue": 4282145782,
            "avatarEmoji": "👨"
          }
        ],
        "bp_readings": [
          {
            "id": "bp_1",
            "memberId": "mem_1",
            "systolic": 120,
            "diastolic": 80,
            "pulse": 72,
            "notes": "Morning check",
            "timestamp": "2026-10-01T08:00:00.000Z"
          }
        ],
        "glucose_readings": [
          {
            "id": "glu_1",
            "memberId": "mem_1",
            "valueMgDl": 105.0,
            "mealContext": "fasting",
            "notes": "Before breakfast",
            "timestamp": "2026-10-01T08:30:00.000Z"
          }
        ]
      }
      ''';

      final Map<String, dynamic> data = jsonDecode(validJson);
      expect(data['version'], 1);
      expect(data['family_members'], hasLength(1));
      expect(data['bp_readings'], hasLength(1));
      expect(data['glucose_readings'], hasLength(1));
      expect(DateTime.parse(data['exportedAt']), isA<DateTime>());

      final member = FamilyMember.fromMap(data['family_members'][0]);
      expect(member.name, 'Papa');
      expect(member.relation, 'Father');

      final bp = BpReading.fromMap(data['bp_readings'][0]);
      expect(bp.systolic, 120);
      expect(bp.diastolic, 80);

      final glu = GlucoseReading.fromMap(data['glucose_readings'][0]);
      expect(glu.valueMgDl, 105.0);
      expect(glu.mealContext, MealContext.fasting);
    });
  });
}
