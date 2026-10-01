import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/health_repository.dart';
import '../models/family_member.dart';
import '../models/bp_reading.dart';
import '../models/glucose_reading.dart';
import '../core/constants/clinical_standards.dart';

// Health Repository Provider
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

// Glucose Unit Notifier ('mg/dL' or 'mmol/L')
class GlucoseUnitNotifier extends Notifier<String> {
  @override
  String build() => 'mg/dL';

  void setUnit(String unit) => state = unit;
}

final glucoseUnitProvider =
    NotifierProvider<GlucoseUnitNotifier, String>(GlucoseUnitNotifier.new);

// Family Members List Notifier
class FamilyMembersNotifier extends AsyncNotifier<List<FamilyMember>> {
  @override
  Future<List<FamilyMember>> build() async {
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

// Tracks whether the user has finished first-time family member onboarding
class OnboardingCompletedNotifier extends Notifier<bool> {
  bool _initialized = false;
  bool _initialHadMembers = false;

  @override
  bool build() {
    final members = ref.watch(familyMembersProvider).asData?.value;
    if (!_initialized && members != null) {
      _initialized = true;
      _initialHadMembers = members.isNotEmpty;
    }
    return _initialHadMembers;
  }

  void complete() => state = true;
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(
        OnboardingCompletedNotifier.new);

// Selected Family Member ID Notifier
class SelectedMemberIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final members = ref.watch(familyMembersProvider).asData?.value;
    if (members != null && members.isNotEmpty) {
      return members.first.id;
    }
    return null;
  }

  void select(String? id) => state = id;
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
    final member = ref.watch(activeMemberProvider);
    if (member == null) return [];
    final repo = ref.watch(healthRepositoryProvider);
    return repo.getBpReadings(member.id);
  }

  Future<void> addReading(BpReading reading) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.addBpReading(reading);
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
    final member = ref.watch(activeMemberProvider);
    if (member == null) return [];
    final repo = ref.watch(healthRepositoryProvider);
    return repo.getGlucoseReadings(member.id);
  }

  Future<void> addReading(GlucoseReading reading) async {
    final repo = ref.read(healthRepositoryProvider);
    await repo.addGlucoseReading(reading);
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
  final readings = ref.watch(bpReadingsProvider).asData?.value;
  if (readings == null || readings.isEmpty) return null;

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
  final readings = ref.watch(glucoseReadingsProvider).asData?.value;
  if (readings == null || readings.isEmpty) return null;

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
