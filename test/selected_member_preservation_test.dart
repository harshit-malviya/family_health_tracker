import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/providers/health_providers.dart';

class TestFamilyMembersNotifier extends FamilyMembersNotifier {
  List<FamilyMember> _members;
  TestFamilyMembersNotifier(this._members);

  @override
  Future<List<FamilyMember>> build() async => _members;

  void setMembers(List<FamilyMember> updated) {
    _members = updated;
    ref.invalidateSelf();
  }
}

void main() {
  test('SelectedMemberIdNotifier preserves selected member across familyMembersProvider updates (CRIT-13)', () async {
    const member1 = FamilyMember(
      id: 'mem_1',
      name: 'Dad',
      relation: 'Father',
      colorValue: 0xFF2E7D32,
      avatarEmoji: '👨',
    );
    const member2 = FamilyMember(
      id: 'mem_2',
      name: 'Mom',
      relation: 'Mother',
      colorValue: 0xFFC2185B,
      avatarEmoji: '👩',
    );

    late TestFamilyMembersNotifier testNotifier;

    final container = ProviderContainer(
      overrides: [
        familyMembersProvider.overrideWith(() {
          testNotifier = TestFamilyMembersNotifier([member1, member2]);
          return testNotifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    // Keep active subscription
    container.listen(selectedMemberIdProvider, (_, _) {});

    // Await initial build
    await container.read(familyMembersProvider.future);

    // Initial state defaults to first member ('mem_1')
    expect(container.read(selectedMemberIdProvider), 'mem_1');

    // User selects Mom ('mem_2')
    container.read(selectedMemberIdProvider.notifier).select('mem_2');
    expect(container.read(selectedMemberIdProvider), 'mem_2');

    // Simulate updating Mom (editing profile triggers invalidateSelf)
    final updatedMom = member2.copyWith(name: 'Mother');
    testNotifier.setMembers([member1, updatedMom]);
    await container.read(familyMembersProvider.future);

    // Active selection MUST still be Mom ('mem_2'), NOT reset to Dad ('mem_1')
    expect(container.read(selectedMemberIdProvider), 'mem_2');

    // If Mom is deleted from family members, active selection falls back to first member ('mem_1')
    testNotifier.setMembers([member1]);
    await container.read(familyMembersProvider.future);
    expect(container.read(selectedMemberIdProvider), 'mem_1');
  });
}
