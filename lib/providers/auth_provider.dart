import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../core/database/database_helper.dart';
import 'health_providers.dart';

const String kCachedFamilyPrefKey = 'cached_family_group_info';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

/// Stream of auth state changes from Supabase
final authStateProvider = StreamProvider<AuthState?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  if (!service.isAvailable) {
    return Stream.value(null);
  }
  return service.authStateChanges ?? Stream.value(null);
});

/// Current authenticated user
final currentUserProvider = Provider<User?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? service.currentUser;
});

/// Notifier tracking the currently active family group with local cache support
class CurrentFamilyNotifier extends AsyncNotifier<FamilyGroupInfo?> {
  @override
  Future<FamilyGroupInfo?> build() async {
    final service = ref.watch(supabaseServiceProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null || !service.isAvailable) {
      return null;
    }

    // 1. Read from SharedPreferences cache immediately to prevent startup loading spinner
    FamilyGroupInfo? cached;
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final raw = prefs.getString(kCachedFamilyPrefKey);
      if (raw != null && raw.isNotEmpty) {
        cached = FamilyGroupInfo.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}

    // 2. If cached, return immediately and trigger quiet background verification
    if (cached != null) {
      unawaited(_verifyRemote(service));
      return cached;
    }

    // 3. Fallback to remote if no cache exists (first-time signin)
    try {
      final remote = await service.getCurrentFamily();
      if (remote != null) {
        _saveToCache(remote);
      }
      return remote;
    } catch (_) {
      return null;
    }
  }

  Future<void> _verifyRemote(SupabaseService service) async {
    try {
      final remote = await service.getCurrentFamily();
      if (remote != null) {
        _saveToCache(remote);
        state = AsyncValue.data(remote);
      }
    } catch (_) {
      // Offline: keep current cached state quietly without throwing
    }
  }

  void _saveToCache(FamilyGroupInfo info) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString(kCachedFamilyPrefKey, jsonEncode(info.toMap()));
    } catch (_) {}
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<FamilyGroupInfo> createFamily({
    required String familyName,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      final family = await service.createFamily(
        familyName: familyName,
        displayName: displayName,
      );
      _saveToCache(family);
      state = AsyncValue.data(family);
      return family;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<FamilyGroupInfo> joinFamily({
    required String inviteCode,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      final family = await service.joinFamilyByCode(
        inviteCode: inviteCode,
        displayName: displayName,
      );
      _saveToCache(family);
      state = AsyncValue.data(family);
      return family;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(kCachedFamilyPrefKey);
    } catch (_) {}

    final service = ref.read(supabaseServiceProvider);
    await service.signOut();
    await DatabaseHelper.instance.clearAllData();
    state = const AsyncValue.data(null);
  }
}

final currentFamilyProvider =
    AsyncNotifierProvider<CurrentFamilyNotifier, FamilyGroupInfo?>(CurrentFamilyNotifier.new);
