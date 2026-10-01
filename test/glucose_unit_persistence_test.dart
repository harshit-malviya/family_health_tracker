import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/providers/health_providers.dart';

void main() {
  group('Glucose Unit Preference Persistence Tests (CRIT-09)', () {
    test('Defaults to mg/dL when SharedPreferences contains no saved unit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final unit = container.read(glucoseUnitProvider);
      expect(unit, equals('mg/dL'));
    });

    test('Initializes synchronously with mmol/L when pre-seeded in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        kGlucoseUnitPrefKey: 'mmol/L',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final unit = container.read(glucoseUnitProvider);
      expect(unit, equals('mmol/L'));
    });

    test('setUnit updates provider state and writes to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(glucoseUnitProvider), equals('mg/dL'));

      await container.read(glucoseUnitProvider.notifier).setUnit('mmol/L');

      // State is updated
      expect(container.read(glucoseUnitProvider), equals('mmol/L'));
      // Stored in SharedPreferences
      expect(prefs.getString(kGlucoseUnitPrefKey), equals('mmol/L'));
    });

    test('Simulates app restart: fresh ProviderContainer reads persisted unit from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Launch 1: User switches to mmol/L
      final container1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      await container1.read(glucoseUnitProvider.notifier).setUnit('mmol/L');
      expect(container1.read(glucoseUnitProvider), equals('mmol/L'));
      container1.dispose(); // Simulate app termination

      // Launch 2: App restart with a new ProviderContainer
      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container2.dispose);

      // Verify preference was preserved across app restart
      expect(container2.read(glucoseUnitProvider), equals('mmol/L'));
    });

    test('Falls back safely to mg/dL when stored value is invalid or corrupted', () async {
      SharedPreferences.setMockInitialValues({
        kGlucoseUnitPrefKey: 'invalid_or_corrupted_unit',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(glucoseUnitProvider), equals('mg/dL'));
    });

    test('Rejects invalid unit values in setUnit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(glucoseUnitProvider.notifier).setUnit('g/L');
      expect(container.read(glucoseUnitProvider), equals('mg/dL'));
      expect(prefs.getString(kGlucoseUnitPrefKey), isNull);
    });
  });
}
