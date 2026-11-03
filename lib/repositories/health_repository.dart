import 'dart:async';
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
    final localMembers = await _dbHelper.getMembers(familyId: familyId);

    // If local cache has members, return immediately to eliminate launch spinner
    if (localMembers.isNotEmpty) {
      if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
        unawaited(_refreshMembersFromRemote(familyId));
      }
      return localMembers;
    }

    // If local cache is empty, query remote with timeout
    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        final remoteMembers = await _supabaseService.getPatientProfiles(familyId);
        for (final m in remoteMembers) {
          await _dbHelper.insertMember(m);
        }
        return remoteMembers;
      } catch (_) {
        // Offline fallback
      }
    }
    return localMembers;
  }

  Future<void> _refreshMembersFromRemote(String familyId) async {
    try {
      final remoteMembers = await _supabaseService.getPatientProfiles(familyId);
      for (final m in remoteMembers) {
        await _dbHelper.insertMember(m);
      }
    } catch (_) {}
  }

  Future<void> saveMember(FamilyMember member) async {
    final familyId = activeFamilyId;
    final enrichedMember = member.copyWith(familyId: familyId);

    await _dbHelper.insertMember(enrichedMember);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.savePatientProfile(enrichedMember, familyId);
      } catch (_) {}
    }
  }

  Future<void> updateMember(FamilyMember member) async {
    final familyId = activeFamilyId;
    final enrichedMember = member.copyWith(familyId: familyId);

    await _dbHelper.updateMember(enrichedMember);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.savePatientProfile(enrichedMember, familyId);
      } catch (_) {}
    }
  }

  Future<void> deleteMember(String id) async {
    await _dbHelper.deleteMember(id);

    if (_supabaseService.isAvailable && activeFamilyId != null) {
      try {
        await _supabaseService.deletePatientProfile(id);
      } catch (_) {}
    }
  }

  // --- Blood Pressure Readings ---

  Future<List<BpReading>> getBpReadings(String memberId) async {
    final familyId = activeFamilyId;
    final localReadings = await _dbHelper.getBpReadings(memberId);

    // If local cache has data, return immediately for instant render
    if (localReadings.isNotEmpty) {
      if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
        unawaited(_refreshBpFromRemote(familyId, memberId));
      }
      return localReadings;
    }

    // Otherwise, fetch remote with quick timeout
    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        final remoteReadings = await _supabaseService.getBpReadings(familyId, memberId: memberId);
        for (final r in remoteReadings) {
          await _dbHelper.insertBp(r);
        }
        return remoteReadings;
      } catch (_) {
        // Offline fallback
      }
    }
    return localReadings;
  }

  Future<void> _refreshBpFromRemote(String familyId, String memberId) async {
    try {
      final remoteReadings = await _supabaseService.getBpReadings(familyId, memberId: memberId);
      for (final r in remoteReadings) {
        // Don't overwrite local rows that have unsynced changes
        await _dbHelper.insertBp(r);
      }
    } catch (_) {}
  }

  Future<void> addBpReading(BpReading reading, {String? loggedBy}) async {
    final familyId = activeFamilyId;
    final displayName = loggedBy ?? activeUserDisplayName ?? 'Family Member';
    final enriched = reading.copyWith(
      familyId: familyId,
      loggedByName: reading.loggedByName ?? displayName,
      isPendingSync: true, // Mark pending until remote confirms
    );

    // 1. Save locally in SQLite immediately
    await _dbHelper.insertBp(enriched);

    // 2. Push to Supabase if connected
    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveBpReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? displayName,
        );
        // Confirmed synced
        await _dbHelper.markBpSynced(enriched.id);
      } catch (_) {
        // Stays pending in outbox
      }
    }
  }

  Future<void> updateBpReading(BpReading reading) async {
    final familyId = activeFamilyId;
    final enriched = reading.copyWith(
      familyId: familyId,
      isPendingSync: true,
    );

    await _dbHelper.updateBp(enriched);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveBpReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? activeUserDisplayName ?? 'Family Member',
        );
        await _dbHelper.markBpSynced(enriched.id);
      } catch (_) {}
    }
  }

  Future<void> deleteBpReading(String id) async {
    await _dbHelper.deleteBp(id);

    if (_supabaseService.isAvailable && activeFamilyId != null) {
      try {
        await _supabaseService.deleteBpReading(id);
      } catch (_) {}
    }
  }

  // --- Blood Glucose Readings ---

  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) async {
    final familyId = activeFamilyId;
    final localReadings = await _dbHelper.getGlucoseReadings(memberId);

    if (localReadings.isNotEmpty) {
      if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
        unawaited(_refreshGlucoseFromRemote(familyId, memberId));
      }
      return localReadings;
    }

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        final remoteReadings = await _supabaseService.getGlucoseReadings(familyId, memberId: memberId);
        for (final r in remoteReadings) {
          await _dbHelper.insertGlucose(r);
        }
        return remoteReadings;
      } catch (_) {
        // Offline fallback
      }
    }
    return localReadings;
  }

  Future<void> _refreshGlucoseFromRemote(String familyId, String memberId) async {
    try {
      final remoteReadings = await _supabaseService.getGlucoseReadings(familyId, memberId: memberId);
      for (final r in remoteReadings) {
        await _dbHelper.insertGlucose(r);
      }
    } catch (_) {}
  }

  Future<void> addGlucoseReading(GlucoseReading reading, {String? loggedBy}) async {
    final familyId = activeFamilyId;
    final displayName = loggedBy ?? activeUserDisplayName ?? 'Family Member';
    final enriched = reading.copyWith(
      familyId: familyId,
      loggedByName: reading.loggedByName ?? displayName,
      isPendingSync: true,
    );

    // 1. Save locally in SQLite immediately
    await _dbHelper.insertGlucose(enriched);

    // 2. Push to Supabase if connected
    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveGlucoseReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? displayName,
        );
        await _dbHelper.markGlucoseSynced(enriched.id);
      } catch (_) {
        // Stays pending in outbox
      }
    }
  }

  Future<void> updateGlucoseReading(GlucoseReading reading) async {
    final familyId = activeFamilyId;
    final enriched = reading.copyWith(
      familyId: familyId,
      isPendingSync: true,
    );

    await _dbHelper.updateGlucose(enriched);

    if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
      try {
        await _supabaseService.saveGlucoseReading(
          enriched,
          familyId,
          loggedByName: enriched.loggedByName ?? activeUserDisplayName ?? 'Family Member',
        );
        await _dbHelper.markGlucoseSynced(enriched.id);
      } catch (_) {}
    }
  }

  Future<void> deleteGlucoseReading(String id) async {
    await _dbHelper.deleteGlucose(id);

    if (_supabaseService.isAvailable && activeFamilyId != null) {
      try {
        await _supabaseService.deleteGlucoseReading(id);
      } catch (_) {}
    }
  }

  // --- Background Outbox Sync ---

  Future<int> syncPendingOutbox() async {
    if (!_supabaseService.isAvailable || activeFamilyId == null) {
      return await _dbHelper.getPendingSyncCount();
    }
    final familyId = activeFamilyId!;

    // 1. Sync pending BP readings
    final pendingBp = await _dbHelper.getPendingBpReadings();
    for (final bp in pendingBp) {
      try {
        await _supabaseService.saveBpReading(
          bp,
          familyId,
          loggedByName: bp.loggedByName ?? activeUserDisplayName ?? 'Family Member',
        );
        await _dbHelper.markBpSynced(bp.id);
      } catch (_) {
        break; // Stop if offline
      }
    }

    // 2. Sync pending Glucose readings
    final pendingGlucose = await _dbHelper.getPendingGlucoseReadings();
    for (final g in pendingGlucose) {
      try {
        await _supabaseService.saveGlucoseReading(
          g,
          familyId,
          loggedByName: g.loggedByName ?? activeUserDisplayName ?? 'Family Member',
        );
        await _dbHelper.markGlucoseSynced(g.id);
      } catch (_) {
        break;
      }
    }

    return await _dbHelper.getPendingSyncCount();
  }

  Future<int> getPendingSyncCount() => _dbHelper.getPendingSyncCount();

  // --- Backup & Restore ---
  Future<String> exportBackupJson() => _dbHelper.exportToJson();

  Future<bool> importBackupJson(String jsonString) =>
      _dbHelper.importFromJson(jsonString);
}
