import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/providers/health_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingCompletedNotifier (CRIT-02 Persistence & Bug Fix)', () {
    test('fresh install with no saved prefs starts with false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final isCompleted = container.read(onboardingCompletedProvider);
      expect(isCompleted, isFalse);
    });

    test('complete() sets state to true and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      container.read(onboardingCompletedProvider.notifier).complete();

      expect(container.read(onboardingCompletedProvider), isTrue);
      expect(prefs.getBool(kOnboardingCompletedPrefKey), isTrue);
    });

    test('CRIT-02 regression test: profile invalidation does NOT reset onboarding state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // User finishes onboarding
      container.read(onboardingCompletedProvider.notifier).complete();
      expect(container.read(onboardingCompletedProvider), isTrue);

      // Simulate profile addition / database update triggering familyMembersProvider reload
      container.invalidate(familyMembersProvider);

      // Verify onboardingCompletedProvider remains true and does NOT eject user
      expect(container.read(onboardingCompletedProvider), isTrue);
      expect(prefs.getBool(kOnboardingCompletedPrefKey), isTrue);
    });

    test('subsequent app launch restores completed state synchronously from SharedPreferences', () async {
      // Simulate app restart where preference was previously saved
      SharedPreferences.setMockInitialValues({
        kOnboardingCompletedPrefKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Immediate synchronous value check
      expect(container.read(onboardingCompletedProvider), isTrue);
    });

    test('reset() sets state to false and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        kOnboardingCompletedPrefKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingCompletedProvider), isTrue);

      container.read(onboardingCompletedProvider.notifier).reset();

      expect(container.read(onboardingCompletedProvider), isFalse);
      expect(prefs.getBool(kOnboardingCompletedPrefKey), isFalse);
    });
  });
}
