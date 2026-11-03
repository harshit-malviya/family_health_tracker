import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/core/config/supabase_config.dart';
import 'package:health_tracker/core/constants/clinical_standards.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/models/sync_queue_item.dart';
import 'package:health_tracker/services/supabase_service.dart';

void main() {
  group('Supabase Configuration Tests', () {
    tearDown(() {
      SupabaseConfig.reset();
    });

    test('Initializes unconfigured by default when env vars are omitted', () {
      SupabaseConfig.reset();
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('Accepts modern publishable key and custom URL programmatically', () {
      SupabaseConfig.setCredentials(
        url: 'https://testproject.supabase.co',
        publishableKey: 'sb_publishable_abcdef123456',
      );

      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.url, equals('https://testproject.supabase.co'));
      expect(SupabaseConfig.publishableKey, equals('sb_publishable_abcdef123456'));
    });
  });

  group('Family Sharing & Attribution Model Serialization', () {
    test('BpReading serializes and deserializes loggedByName and familyId cleanly', () {
      final now = DateTime.now();
      final bp = BpReading(
        id: 'bp_123',
        memberId: 'member_dad',
        systolic: 125,
        diastolic: 82,
        pulse: 70,
        arm: 'Left',
        posture: 'Sitting',
        timestamp: now,
        familyId: 'family_456',
        createdBy: 'user_789',
        loggedByName: 'Rahul',
      );

      // Local SQLite / App Map
      final localMap = bp.toMap();
      expect(localMap['loggedByName'], equals('Rahul'));
      expect(localMap['familyId'], equals('family_456'));
      expect(localMap['createdBy'], equals('user_789'));
      expect(localMap.containsKey('isPendingSync'), isFalse);

      final fromLocal = BpReading.fromMap(localMap);
      expect(fromLocal.loggedByName, equals('Rahul'));
      expect(fromLocal.familyId, equals('family_456'));
      expect(fromLocal.createdBy, equals('user_789'));

      // Supabase snake_case Map
      final sbMap = bp.toSupabaseMap();
      expect(sbMap['logged_by_name'], equals('Rahul'));
      expect(sbMap['family_id'], equals('family_456'));
      expect(sbMap['created_by'], equals('user_789'));

      final fromSupabase = BpReading.fromMap(sbMap);
      expect(fromSupabase.loggedByName, equals('Rahul'));
      expect(fromSupabase.familyId, equals('family_456'));
      expect(fromSupabase.createdBy, equals('user_789'));
    });

    test('GlucoseReading serializes and deserializes loggedByName and familyId cleanly', () {
      final now = DateTime.now();
      final glucose = GlucoseReading(
        id: 'glu_123',
        memberId: 'member_mom',
        valueMgDl: 110.0,
        mealContext: MealContext.fasting,
        medicationNotes: 'Metformin 500mg',
        timestamp: now,
        familyId: 'family_456',
        createdBy: 'user_789',
        loggedByName: 'Dr. Priya',
      );

      // Local SQLite / App Map
      final localMap = glucose.toMap();
      expect(localMap['loggedByName'], equals('Dr. Priya'));
      expect(localMap['familyId'], equals('family_456'));
      expect(localMap.containsKey('isPendingSync'), isFalse);

      final fromLocal = GlucoseReading.fromMap(localMap);
      expect(fromLocal.loggedByName, equals('Dr. Priya'));
      expect(fromLocal.familyId, equals('family_456'));

      // Supabase snake_case Map
      final sbMap = glucose.toSupabaseMap();
      expect(sbMap['logged_by_name'], equals('Dr. Priya'));
      expect(sbMap['family_id'], equals('family_456'));

      final fromSupabase = GlucoseReading.fromMap(sbMap);
      expect(fromSupabase.loggedByName, equals('Dr. Priya'));
      expect(fromSupabase.familyId, equals('family_456'));
    });

    test('FamilyMember serializes and deserializes familyId', () {
      final member = FamilyMember(
        id: 'member_dad',
        name: 'Dad',
        relation: 'Father',
        age: 62,
        colorValue: 0xFF2196F3,
        avatarEmoji: '👨',
        familyId: 'family_456',
      );

      final map = member.toMap();
      expect(map['familyId'], equals('family_456'));

      final fromMap = FamilyMember.fromMap(map);
      expect(fromMap.familyId, equals('family_456'));

      final sbMap = member.toSupabaseMap();
      expect(sbMap['family_id'], equals('family_456'));
      final fromSb = FamilyMember.fromMap(sbMap);
      expect(fromSb.familyId, equals('family_456'));
    });

    test('SyncQueueItem serializes and deserializes correctly', () {
      final now = DateTime.now();
      final item = SyncQueueItem(
        id: 1,
        entityType: 'bp_reading',
        entityId: 'bp_xyz',
        action: 'INSERT',
        payload: '{"systolic": 120, "diastolic": 80}',
        familyId: 'family_456',
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['entityType'], equals('bp_reading'));
      expect(map['entityId'], equals('bp_xyz'));
      expect(map['action'], equals('INSERT'));
      expect(map['payload'], equals('{"systolic": 120, "diastolic": 80}'));
      expect(map['familyId'], equals('family_456'));

      final fromMap = SyncQueueItem.fromMap(map);
      expect(fromMap.entityType, equals('bp_reading'));
      expect(fromMap.action, equals('INSERT'));
      expect(fromMap.entityId, equals('bp_xyz'));
      expect(fromMap.payload, equals(item.payload));
    });

    test('FamilyGroupInfo correctly parses from Supabase RPC / table maps', () {
      final map = {
        'family_id': 'fam-uuid-1',
        'family_name': 'The Sharma Family',
        'invite_code': 'SHA-8421',
        'role': 'admin',
        'display_name': 'Harsh',
      };

      final info = FamilyGroupInfo.fromMap(map);
      expect(info.id, equals('fam-uuid-1'));
      expect(info.name, equals('The Sharma Family'));
      expect(info.inviteCode, equals('SHA-8421'));
      expect(info.role, equals('admin'));
      expect(info.displayName, equals('Harsh'));
    });

    test('FamilyGroupInfo supports JSON round-trip for offline caching', () {
      const original = FamilyGroupInfo(
        id: 'fam-uuid-offline',
        name: 'The Verma Family',
        inviteCode: 'VRM-9911',
        role: 'member',
        displayName: 'Aarav',
      );

      final jsonStr = jsonEncode(original.toMap());
      final decodedMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = FamilyGroupInfo.fromMap(decodedMap);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.inviteCode, equals(original.inviteCode));
      expect(restored.role, equals(original.role));
      expect(restored.displayName, equals(original.displayName));
    });
  });
}
