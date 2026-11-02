import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_member.dart';
import '../models/bp_reading.dart';
import '../models/glucose_reading.dart';
import '../core/config/supabase_config.dart';

class FamilyGroupInfo {
  final String id;
  final String name;
  final String inviteCode;
  final String role;
  final String displayName;

  const FamilyGroupInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.role,
    required this.displayName,
  });

  factory FamilyGroupInfo.fromMap(Map<String, dynamic> map) {
    return FamilyGroupInfo(
      id: (map['family_id'] ?? map['id']) as String,
      name: (map['family_name'] ?? map['name']) as String,
      inviteCode: (map['invite_code'] ?? map['inviteCode'] ?? '') as String,
      role: (map['role'] ?? 'member') as String,
      displayName: (map['display_name'] ?? map['displayName'] ?? 'Member') as String,
    );
  }
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => SupabaseConfig.isConfigured && _client != null;

  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  // --- Auth Operations ---

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase client not initialized');

    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase client not initialized');

    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  // --- Family Operations ---

  String _generateInviteCode(String familyName) {
    final prefix = familyName.trim().replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final cleanPrefix = prefix.length >= 3 ? prefix.substring(0, 3) : 'FAM';
    final randomNum = Random().nextInt(9000) + 1000;
    return '$cleanPrefix-$randomNum';
  }

  Future<FamilyGroupInfo> createFamily({
    required String familyName,
    required String displayName,
  }) async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) throw Exception('Authentication required');

    final code = _generateInviteCode(familyName);

    // 1. Try RPC first for atomic creation without RLS timing race
    try {
      final rpcRes = await client.rpc('create_family', params: {
        'p_family_name': familyName.trim(),
        'p_invite_code': code,
        'p_display_name': displayName.trim(),
      });
      if (rpcRes is Map<String, dynamic>) {
        return FamilyGroupInfo.fromMap(rpcRes);
      }
    } catch (_) {
      // Fallback to direct table queries
    }

    // 2. Fallback to direct table inserts
    final familyRow = await client.from('families').insert({
      'name': familyName.trim(),
      'invite_code': code,
      'created_by': user.id,
    }).select().single();

    final familyId = familyRow['id'] as String;

    // 2. Insert creator as Admin membership
    await client.from('family_memberships').insert({
      'family_id': familyId,
      'user_id': user.id,
      'display_name': displayName.trim(),
      'role': 'admin',
    });

    return FamilyGroupInfo(
      id: familyId,
      name: familyName.trim(),
      inviteCode: code,
      role: 'admin',
      displayName: displayName.trim(),
    );
  }

  Future<FamilyGroupInfo> joinFamilyByCode({
    required String inviteCode,
    required String displayName,
  }) async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) throw Exception('Authentication required');

    final cleanCode = inviteCode.trim().toUpperCase();

    try {
      // Attempt RPC first if migration function exists
      final rpcResult = await client.rpc('join_family_by_code', params: {
        'p_invite_code': cleanCode,
        'p_display_name': displayName.trim(),
      });
      if (rpcResult is Map<String, dynamic>) {
        return FamilyGroupInfo.fromMap(rpcResult);
      }
    } catch (_) {
      // Fallback to direct tables query
    }

    // Direct fallback
    final families = await client
        .from('families')
        .select()
        .eq('invite_code', cleanCode)
        .limit(1);

    if (families.isEmpty) {
      throw Exception('Family with invite code "$cleanCode" was not found.');
    }

    final family = families.first;
    final familyId = family['id'] as String;

    await client.from('family_memberships').upsert({
      'family_id': familyId,
      'user_id': user.id,
      'display_name': displayName.trim(),
      'role': 'member',
    }, onConflict: 'family_id, user_id');

    return FamilyGroupInfo(
      id: familyId,
      name: family['name'] as String,
      inviteCode: cleanCode,
      role: 'member',
      displayName: displayName.trim(),
    );
  }

  Future<FamilyGroupInfo?> getCurrentFamily() async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return null;

    final memberships = await client
        .from('family_memberships')
        .select('family_id, display_name, role, families(id, name, invite_code)')
        .eq('user_id', user.id)
        .limit(1);

    if (memberships.isEmpty) return null;

    final m = memberships.first;
    final fam = m['families'] as Map<String, dynamic>?;
    if (fam == null) return null;

    return FamilyGroupInfo(
      id: fam['id'] as String,
      name: fam['name'] as String,
      inviteCode: (fam['invite_code'] ?? '') as String,
      role: (m['role'] ?? 'member') as String,
      displayName: (m['display_name'] ?? user.userMetadata?['display_name'] ?? 'Member') as String,
    );
  }

  // --- Patient Profiles CRUD ---

  Future<List<FamilyMember>> getPatientProfiles(String familyId) async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('patient_profiles')
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: true);

    return (rows as List).map((r) => FamilyMember.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> savePatientProfile(FamilyMember member, String familyId) async {
    final client = _client;
    if (client == null) return;

    final data = member.toSupabaseMap()..['family_id'] = familyId;
    await client.from('patient_profiles').upsert(data);
  }

  Future<void> deletePatientProfile(String profileId) async {
    final client = _client;
    if (client == null) return;

    await client.from('patient_profiles').delete().eq('id', profileId);
  }

  // --- BP Readings CRUD ---

  Future<List<BpReading>> getBpReadings(String familyId, {String? memberId}) async {
    final client = _client;
    if (client == null) return [];

    var query = client.from('bp_readings').select().eq('family_id', familyId);
    if (memberId != null) {
      query = query.eq('member_id', memberId);
    }

    final rows = await query.order('timestamp', ascending: false);
    return (rows as List).map((r) => BpReading.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> saveBpReading(
    BpReading reading,
    String familyId, {
    required String loggedByName,
  }) async {
    final client = _client;
    final user = currentUser;
    if (client == null) return;

    final data = reading.toSupabaseMap()
      ..['family_id'] = familyId
      ..['logged_by_name'] = loggedByName
      ..['created_by'] = user?.id;

    await client.from('bp_readings').upsert(data);
  }

  Future<void> deleteBpReading(String id) async {
    final client = _client;
    if (client == null) return;

    await client.from('bp_readings').delete().eq('id', id);
  }

  // --- Glucose Readings CRUD ---

  Future<List<GlucoseReading>> getGlucoseReadings(String familyId, {String? memberId}) async {
    final client = _client;
    if (client == null) return [];

    var query = client.from('glucose_readings').select().eq('family_id', familyId);
    if (memberId != null) {
      query = query.eq('member_id', memberId);
    }

    final rows = await query.order('timestamp', ascending: false);
    return (rows as List).map((r) => GlucoseReading.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> saveGlucoseReading(
    GlucoseReading reading,
    String familyId, {
    required String loggedByName,
  }) async {
    final client = _client;
    final user = currentUser;
    if (client == null) return;

    final data = reading.toSupabaseMap()
      ..['family_id'] = familyId
      ..['logged_by_name'] = loggedByName
      ..['created_by'] = user?.id;

    await client.from('glucose_readings').upsert(data);
  }

  Future<void> deleteGlucoseReading(String id) async {
    final client = _client;
    if (client == null) return;

    await client.from('glucose_readings').delete().eq('id', id);
  }

  // --- Realtime Subscriptions ---

  RealtimeChannel? subscribeToFamily({
    required String familyId,
    required VoidCallback onUpdate,
  }) {
    final client = _client;
    if (client == null) return null;

    final channelName = 'family_realtime_$familyId';
    final channel = client.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bp_readings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_id',
            value: familyId,
          ),
          callback: (payload) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'glucose_readings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_id',
            value: familyId,
          ),
          callback: (payload) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'patient_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_id',
            value: familyId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();

    return channel;
  }
}

