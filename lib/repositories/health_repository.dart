import 'dart:async';
import 'dart:convert';
import '../core/database/database_helper.dart';
import '../models/family_member.dart';
import '../models/bp_reading.dart';
import '../models/glucose_reading.dart';
import '../models/sync_queue_item.dart';
import '../services/supabase_service.dart';

class HealthRepository {
  final DatabaseHelper _dbHelper;
  final SupabaseService _supabaseService;
  String? activeFamilyId;
  String? activeUserDisplayName;
  bool _isSyncing = false;

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

  // --- Centralized Mutation Pipeline ---

  Future<void> _recordMutation({
    required Future<void> Function() localAction,
    required String entityType,
    required String entityId,
    required String action,
    String? payload,
  }) async {
    // 1. Mutate local SQLite database immediately
    await localAction();

    // 2. Enqueue into sync_queue if in a family group
    final familyId = activeFamilyId;
    if (familyId != null && familyId.isNotEmpty) {
      await _dbHelper.enqueueSyncItem(
        entityType: entityType,
        entityId: entityId,
        action: action,
        payload: payload,
        familyId: familyId,
      );

      // 3. Eagerly drain queue if connectivity is available
      unawaited(processSyncQueue());
    }
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
    final enriched = member.copyWith(familyId: familyId);

    await _recordMutation(
      localAction: () => _dbHelper.insertMember(enriched),
      entityType: 'family_member',
      entityId: enriched.id,
      action: 'INSERT',
      payload: jsonEncode(enriched.toMap()),
    );
  }

  Future<void> updateMember(FamilyMember member) async {
    final familyId = activeFamilyId;
    final enriched = member.copyWith(familyId: familyId);

    await _recordMutation(
      localAction: () => _dbHelper.updateMember(enriched),
      entityType: 'family_member',
      entityId: enriched.id,
      action: 'UPDATE',
      payload: jsonEncode(enriched.toMap()),
    );
  }

  Future<void> deleteMember(String id) async {
    await _recordMutation(
      localAction: () => _dbHelper.deleteMember(id),
      entityType: 'family_member',
      entityId: id,
      action: 'DELETE',
    );
  }

  // --- Blood Pressure Readings ---

  Future<List<BpReading>> getBpReadings(String memberId) async {
    final familyId = activeFamilyId;
    final localReadings = await _dbHelper.getBpReadings(memberId);

    if (localReadings.isNotEmpty) {
      if (_supabaseService.isAvailable && familyId != null && familyId.isNotEmpty) {
        unawaited(_refreshBpFromRemote(familyId, memberId));
      }
      return localReadings;
    }

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
    );

    await _recordMutation(
      localAction: () => _dbHelper.insertBp(enriched),
      entityType: 'bp_reading',
      entityId: enriched.id,
      action: 'INSERT',
      payload: jsonEncode(enriched.toMap()),
    );
  }

  Future<void> updateBpReading(BpReading reading) async {
    final familyId = activeFamilyId;
    final enriched = reading.copyWith(familyId: familyId);

    await _recordMutation(
      localAction: () => _dbHelper.updateBp(enriched),
      entityType: 'bp_reading',
      entityId: enriched.id,
      action: 'UPDATE',
      payload: jsonEncode(enriched.toMap()),
    );
  }

  Future<void> deleteBpReading(String id) async {
    await _recordMutation(
      localAction: () => _dbHelper.deleteBp(id),
      entityType: 'bp_reading',
      entityId: id,
      action: 'DELETE',
    );
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
    );

    await _recordMutation(
      localAction: () => _dbHelper.insertGlucose(enriched),
      entityType: 'glucose_reading',
      entityId: enriched.id,
      action: 'INSERT',
      payload: jsonEncode(enriched.toMap()),
    );
  }

  Future<void> updateGlucoseReading(GlucoseReading reading) async {
    final familyId = activeFamilyId;
    final enriched = reading.copyWith(familyId: familyId);

    await _recordMutation(
      localAction: () => _dbHelper.updateGlucose(enriched),
      entityType: 'glucose_reading',
      entityId: enriched.id,
      action: 'UPDATE',
      payload: jsonEncode(enriched.toMap()),
    );
  }

  Future<void> deleteGlucoseReading(String id) async {
    await _recordMutation(
      localAction: () => _dbHelper.deleteGlucose(id),
      entityType: 'glucose_reading',
      entityId: id,
      action: 'DELETE',
    );
  }

  // --- Unified Sync Queue Processor ---

  Future<int> processSyncQueue() async {
    if (_isSyncing || !_supabaseService.isAvailable || activeFamilyId == null) {
      return await _dbHelper.getSyncQueueCount();
    }

    _isSyncing = true;
    try {
      while (true) {
        final items = await _dbHelper.peekSyncQueue(limit: 20);
        if (items.isEmpty) break;

        bool hasError = false;
        for (final item in items) {
          try {
            await _dispatchSyncItem(item);
            await _dbHelper.removeSyncQueueItem(item.id!);
          } catch (_) {
            hasError = true;
            break; // Stop draining on network failure/timeout
          }
        }

        if (hasError) break;
      }
    } finally {
      _isSyncing = false;
    }

    return await _dbHelper.getSyncQueueCount();
  }

  Future<void> _dispatchSyncItem(SyncQueueItem item) async {
    final familyId = item.familyId;
    switch (item.entityType) {
      case 'family_member':
        if (item.action == 'DELETE') {
          await _supabaseService.deletePatientProfile(item.entityId);
        } else if (item.payload != null) {
          final member = FamilyMember.fromMap(jsonDecode(item.payload!));
          await _supabaseService.savePatientProfile(member, familyId);
        }
        break;

      case 'bp_reading':
        if (item.action == 'DELETE') {
          await _supabaseService.deleteBpReading(item.entityId);
        } else if (item.payload != null) {
          final reading = BpReading.fromMap(jsonDecode(item.payload!));
          await _supabaseService.saveBpReading(
            reading,
            familyId,
            loggedByName: reading.loggedByName ?? activeUserDisplayName ?? 'Family Member',
          );
        }
        break;

      case 'glucose_reading':
        if (item.action == 'DELETE') {
          await _supabaseService.deleteGlucoseReading(item.entityId);
        } else if (item.payload != null) {
          final reading = GlucoseReading.fromMap(jsonDecode(item.payload!));
          await _supabaseService.saveGlucoseReading(
            reading,
            familyId,
            loggedByName: reading.loggedByName ?? activeUserDisplayName ?? 'Family Member',
          );
        }
        break;
    }
  }

  Future<int> syncPendingOutbox() => processSyncQueue();

  Future<int> getPendingSyncCount() => _dbHelper.getSyncQueueCount();

  // --- Backup & Restore ---
  Future<String> exportBackupJson() => _dbHelper.exportToJson();

  Future<bool> importBackupJson(String jsonString) =>
      _dbHelper.importFromJson(jsonString);
}
