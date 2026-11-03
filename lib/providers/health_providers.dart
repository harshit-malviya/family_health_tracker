import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/health_repository.dart';
import '../models/family_member.dart';
import '../models/bp_reading.dart';
import '../models/glucose_reading.dart';
import '../core/constants/clinical_standards.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// SharedPreferences Provider (injected at startup)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden with preloaded instance');
});

// Health Repository Provider
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final currentFamily = ref.watch(currentFamilyProvider).value;
  return HealthRepository(
    activeFamilyId: currentFamily?.id,
    activeUserDisplayName: currentFamily?.displayName,
  );
});

// Realtime Subscriptions Provider
final realtimeSubscriptionProvider = Provider.autoDispose<void>((ref) {
  final family = ref.watch(currentFamilyProvider).value;
  if (family == null) return;

  final channel = SupabaseService.instance.subscribeToFamily(
    familyId: family.id,
    onUpdate: () {
      ref.invalidate(familyMembersProvider);
      ref.invalidate(bpReadingsProvider);
      ref.invalidate(glucoseReadingsProvider);
    },
  );

  ref.onDispose(() {
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel);
      } catch (_) {}
    }
  });
});

// Preference key for glucose unit
const String kGlucoseUnitPrefKey = 'glucose_unit_preference';

// Glucose Unit Notifier ('mg/dL' or 'mmol/L') backed by SharedPreferences
class GlucoseUnitNotifier extends Notifier<String> {
  @override
  String build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(kGlucoseUnitPrefKey);
      if (saved == 'mmol/L' || saved == 'mg/dL') {
        return saved!;
      }
    } catch (_) {}
    return 'mg/dL';
  }

  Future<void> setUnit(String unit) async {
    if (unit != 'mmol/L' && unit != 'mg/dL') return;
    if (state == unit) return;
    state = unit;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(kGlucoseUnitPrefKey, unit);
    } catch (_) {}
  }
}

final glucoseUnitProvider =
    NotifierProvider<GlucoseUnitNotifier, String>(GlucoseUnitNotifier.new);

// Family Members List Notifier
class FamilyMembersNotifier extends AsyncNotifier<List<FamilyMember>> {
  @override
  Future<List<FamilyMember>> build() async {
    // Ensure realtime listener is alive
    ref.watch(realtimeSubscriptionProvider);
    final repo = ref.watch(healthRepositoryProvider);
    return repo.getFamilyMembers();
  }

  Future<void> addMember(FamilyMember member) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.saveMember(member);
    ref.invalidateSelf();
  }

  Future<void> updateMember(FamilyMember member) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.updateMember(member);
    ref.invalidateSelf();
  }

  Future<void> deleteMember(String id) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.deleteMember(id);
    ref.invalidateSelf();
  }

  Future<void> loadMembers() async {
    ref.invalidateSelf();
  }
}

final familyMembersProvider =
    AsyncNotifierProvider<FamilyMembersNotifier, List<FamilyMember>>(
        FamilyMembersNotifier.new);

const String kOnboardingCompletedPrefKey = 'has_completed_onboarding';

// Tracks whether the user has finished first-time family member onboarding
class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedValue = prefs.getBool(kOnboardingCompletedPrefKey);
    if (savedValue != null) {
      return savedValue;
    }

    final existingMembers = ref.read(familyMembersProvider).asData?.value;
    if (existingMembers != null && existingMembers.isNotEmpty) {
      prefs.setBool(kOnboardingCompletedPrefKey, true);
      return true;
    }

    return false;
  }

  void complete() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool(kOnboardingCompletedPrefKey, true);
  }

  void reset() {
    state = false;
    ref.read(sharedPreferencesProvider).setBool(kOnboardingCompletedPrefKey, false);
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(
        OnboardingCompletedNotifier.new);

// Selected Family Member ID Notifier
class SelectedMemberIdNotifier extends Notifier<String?> {
  String? _selectedId;

  @override
  String? build() {
    final membersAsync = ref.watch(familyMembersProvider);
    final members = membersAsync.asData?.value;
    if (members == null) {
      return _selectedId;
    }
    if (members.isEmpty) {
      _selectedId = null;
      return null;
    }
    if (_selectedId != null && members.any((m) => m.id == _selectedId)) {
      return _selectedId;
    }
    _selectedId = members.first.id;
    return _selectedId;
  }

  void select(String? id) {
    _selectedId = id;
    state = id;
  }
}

final selectedMemberIdProvider =
    NotifierProvider<SelectedMemberIdNotifier, String?>(
        SelectedMemberIdNotifier.new);

// Active Family Member object
final activeMemberProvider = Provider<FamilyMember?>((ref) {
  final selectedId = ref.watch(selectedMemberIdProvider);
  final members = ref.watch(familyMembersProvider).asData?.value;
  if (members == null || members.isEmpty) return null;
  return members.firstWhere((m) => m.id == selectedId, orElse: () => members.first);
});

// Blood Pressure Readings Notifier for Active Member
class BpReadingsNotifier extends AsyncNotifier<List<BpReading>> {
  @override
  Future<List<BpReading>> build() async {
    ref.watch(realtimeSubscriptionProvider);
    final member = ref.watch(activeMemberProvider);
    if (member == null) return [];
    final repo = ref.watch(healthRepositoryProvider);
    return repo.getBpReadings(member.id);
  }

  Future<void> addReading(BpReading reading, {String? loggedBy}) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.addBpReading(reading, loggedBy: loggedBy);
    ref.invalidateSelf();
  }

  Future<void> updateReading(BpReading reading) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.updateBpReading(reading);
    ref.invalidateSelf();
  }

  Future<void> deleteReading(String id) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.deleteBpReading(id);
    ref.invalidateSelf();
  }

  Future<void> loadReadings() async {
    ref.invalidateSelf();
  }
}

final bpReadingsProvider =
    AsyncNotifierProvider<BpReadingsNotifier, List<BpReading>>(
        BpReadingsNotifier.new);

// Blood Glucose Readings Notifier for Active Member
class GlucoseReadingsNotifier extends AsyncNotifier<List<GlucoseReading>> {
  @override
  Future<List<GlucoseReading>> build() async {
    ref.watch(realtimeSubscriptionProvider);
    final member = ref.watch(activeMemberProvider);
    if (member == null) return [];
    final repo = ref.watch(healthRepositoryProvider);
    return repo.getGlucoseReadings(member.id);
  }

  Future<void> addReading(GlucoseReading reading, {String? loggedBy}) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.addGlucoseReading(reading, loggedBy: loggedBy);
    ref.invalidateSelf();
  }

  Future<void> updateReading(GlucoseReading reading) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.updateGlucoseReading(reading);
    ref.invalidateSelf();
  }

  Future<void> deleteReading(String id) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.deleteGlucoseReading(id);
    ref.invalidateSelf();
  }

  Future<void> loadReadings() async {
    ref.invalidateSelf();
  }
}

final glucoseReadingsProvider =
    AsyncNotifierProvider<GlucoseReadingsNotifier, List<GlucoseReading>>(
        GlucoseReadingsNotifier.new);

// Blood Pressure Summary Stats
class BpStats {
  final int count;
  final double avgSystolic;
  final double avgDiastolic;
  final double avgPulse;
  final int normalCount;
  final double normalPercentage;

  const BpStats({
    required this.count,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.avgPulse,
    required this.normalCount,
    required this.normalPercentage,
  });
}

final bpStatsProvider = Provider<BpStats?>((ref) {
  final allReadings = ref.watch(bpReadingsProvider).asData?.value;
  if (allReadings == null || allReadings.isEmpty) return null;

  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final readings = allReadings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  if (readings.isEmpty) return null;

  int totalSys = 0;
  int totalDia = 0;
  int totalPulse = 0;
  int normalCount = 0;

  for (final r in readings) {
    totalSys += r.systolic;
    totalDia += r.diastolic;
    totalPulse += r.pulse;
    if (r.category == BpCategory.normal) {
      normalCount++;
    }
  }

  final count = readings.length;
  return BpStats(
    count: count,
    avgSystolic: totalSys / count,
    avgDiastolic: totalDia / count,
    avgPulse: totalPulse / count,
    normalCount: normalCount,
    normalPercentage: (normalCount / count) * 100,
  );
});

// Glucose Summary Stats
class GlucoseStats {
  final int count;
  final double avgMgDl;
  final double minMgDl;
  final double maxMgDl;
  final int inRangeCount;

  const GlucoseStats({
    required this.count,
    required this.avgMgDl,
    required this.minMgDl,
    required this.maxMgDl,
    required this.inRangeCount,
  });
}

final glucoseStatsProvider = Provider<GlucoseStats?>((ref) {
  final allReadings = ref.watch(glucoseReadingsProvider).asData?.value;
  if (allReadings == null || allReadings.isEmpty) return null;

  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final readings = allReadings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  if (readings.isEmpty) return null;

  double total = 0;
  double min = double.infinity;
  double max = -double.infinity;
  int inRange = 0;

  for (final r in readings) {
    total += r.valueMgDl;
    if (r.valueMgDl < min) min = r.valueMgDl;
    if (r.valueMgDl > max) max = r.valueMgDl;
    if (r.category == GlucoseCategory.normal) inRange++;
  }

  return GlucoseStats(
    count: readings.length,
    avgMgDl: total / readings.length,
    minMgDl: min,
    maxMgDl: max,
    inRangeCount: inRange,
  );
});

// Outbox Sync Notifier
class SyncNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final repo = ref.watch(healthRepositoryProvider);
    return repo.getPendingSyncCount();
  }

  Future<void> sync() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(healthRepositoryProvider);
      final remaining = await repo.syncPendingOutbox();
      state = AsyncValue.data(remaining);
      ref.invalidate(bpReadingsProvider);
      ref.invalidate(glucoseReadingsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final syncProvider = AsyncNotifierProvider<SyncNotifier, int>(SyncNotifier.new);

