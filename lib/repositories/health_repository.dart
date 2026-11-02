import '../core/database/database_helper.dart';
import '../models/family_member.dart';
import '../models/bp_reading.dart';
import '../models/glucose_reading.dart';
import '../services/supabase_service.dart';

class HealthRepository {
  final DatabaseHelper _dbHelper;
  final SupabaseService _supabaseService;
  String? activeFamilyId;
  String? activeUserDisplayName;

  HealthRepository({
    DatabaseHelper? dbHelper,
    SupabaseService? supabaseService,
    this.activeFamilyId,
    this.activeUserDisplayName,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _supabaseService = supabaseService ?? SupabaseService.instance;

  void setActiveContext({String? familyId, String? userDisplayName}) {
    activeFamilyId = familyId;
    activeUserDisplayName = userDisplayName;
  }

  // --- Family Members / Patient Profiles ---

  Future<List<FamilyMember>> getFamilyMembers() async {
    final familyId = activeFamilyId;
    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        final remoteMembers = await _supabaseService.getPatientProfiles(familyId);
        // Cache in SQLite
        for (final m in remoteMembers) {
          await _dbHelper.insertMember(m);
        }
        return remoteMembers;
      } catch (_) {
        // Fallback to local SQLite cache
      }
    }
    return _dbHelper.getMembers(familyId: familyId);
  }

  Future<void> saveMember(FamilyMember member) async {
    final familyId = activeFamilyId;
    final enrichedMember = member.copyWith(familyId: familyId);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.savePatientProfile(enrichedMember, familyId);
      } catch (_) {}
    }
    await _dbHelper.insertMember(enrichedMember);
  }

  Future<void> updateMember(FamilyMember member) async {
    final familyId = activeFamilyId;
    final enrichedMember = member.copyWith(familyId: familyId);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.savePatientProfile(enrichedMember, familyId);
      } catch (_) {}
    }
    await _dbHelper.updateMember(enrichedMember);
  }

  Future<void> deleteMember(String id) async {
    if (_supabaseService.isAvailable && activeFamilyId != null) {
      try {
        await _supabaseService.deletePatientProfile(id);
      } catch (_) {}
    }
    await _dbHelper.deleteMember(id);
  }

  // --- Blood Pressure Readings ---

  Future<List<BpReading>> getBpReadings(String memberId) async {
    final familyId = activeFamilyId;
    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        final remoteReadings = await _supabaseService.getBpReadings(familyId, memberId: memberId);
        // Cache in SQLite
        for (final r in remoteReadings) {
          await _dbHelper.insertBp(r);
        }
        return remoteReadings;
      } catch (_) {
        // Fallback to local SQLite cache
      }
    }
    return _dbHelper.getBpReadings(memberId);
  }

  Future<void> addBpReading(BpReading reading, {String? loggedBy}) async {
    final familyId = activeFamilyId;
    final displayName = loggedBy ?? activeUserDisplayName ?? 'Family Member';
    final enriched = reading.copyWith(
      familyId: familyId,
      loggedByName: reading.loggedByName ?? displayName,
    );

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveBpReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? displayName,
        );
      } catch (_) {}
    }
    await _dbHelper.insertBp(enriched);
  }

  Future<void> updateBpReading(BpReading reading) async {
    final familyId = activeFamilyId;
    final enriched = reading.copyWith(familyId: familyId);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveBpReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? activeUserDisplayName ?? 'Family Member',
        );
      } catch (_) {}
    }
    await _dbHelper.updateBp(enriched);
  }

  Future<void> deleteBpReading(String id) async {
    if (_supabaseService.isAvailable && activeFamilyId != null) {
      try {
        await _supabaseService.deleteBpReading(id);
      } catch (_) {}
    }
    await _dbHelper.deleteBp(id);
  }

  // --- Blood Glucose Readings ---

  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) async {
    final familyId = activeFamilyId;
    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        final remoteReadings = await _supabaseService.getGlucoseReadings(familyId, memberId: memberId);
        // Cache in SQLite
        for (final r in remoteReadings) {
          await _dbHelper.insertGlucose(r);
        }
        return remoteReadings;
      } catch (_) {
        // Fallback to local SQLite cache
      }
    }
    return _dbHelper.getGlucoseReadings(memberId);
  }

  Future<void> addGlucoseReading(GlucoseReading reading, {String? loggedBy}) async {
    final familyId = activeFamilyId;
    final displayName = loggedBy ?? activeUserDisplayName ?? 'Family Member';
    final enriched = reading.copyWith(
      familyId: familyId,
      loggedByName: reading.loggedByName ?? displayName,
    );

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveGlucoseReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? displayName,
        );
      } catch (_) {}
    }
    await _dbHelper.insertGlucose(enriched);
  }

  Future<void> updateGlucoseReading(GlucoseReading reading) async {
    final familyId = activeFamilyId;
    final enriched = reading.copyWith(familyId: familyId);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveGlucoseReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? activeUserDisplayName ?? 'Family Member',
        );
      } catch (_) {}
    }
    await _dbHelper.updateGlucose(enriched);
  }

  Future<void> deleteGlucoseReading(String id) async {
    if (_supabaseService.isAvailable && activeFamilyId != null) {
      try {
        await _supabaseService.deleteGlucoseReading(id);
      } catch (_) {}
    }
    await _dbHelper.deleteGlucose(id);
  }

  // --- Backup & Restore ---
  Future<String> exportBackupJson() => _dbHelper.exportToJson();

  Future<bool> importBackupJson(String jsonString) =>
      _dbHelper.importFromJson(jsonString);
}
