import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../core/database/database_helper.dart';

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

/// Notifier tracking the currently active family group
class CurrentFamilyNotifier extends AsyncNotifier<FamilyGroupInfo?> {
  @override
  Future<FamilyGroupInfo?> build() async {
    final service = ref.watch(supabaseServiceProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null || !service.isAvailable) {
      return null;
    }

    return service.getCurrentFamily();
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
      state = AsyncValue.data(family);
      return family;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final service = ref.read(supabaseServiceProvider);
    await service.signOut();
    await DatabaseHelper.instance.clearAllData();
    state = const AsyncValue.data(null);
  }
}

final currentFamilyProvider =
    AsyncNotifierProvider<CurrentFamilyNotifier, FamilyGroupInfo?>(CurrentFamilyNotifier.new);

