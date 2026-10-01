import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/repositories/health_repository.dart';
import 'package:health_tracker/providers/health_providers.dart';
import 'package:health_tracker/ui/screens/doctor_report_screen.dart';

class FakeHealthRepository extends Fake implements HealthRepository {
  final FamilyMember member;
  FakeHealthRepository(this.member);

  @override
  Future<List<FamilyMember>> getFamilyMembers() async => [member];

  @override
  Future<List<BpReading>> getBpReadings(String memberId) async => [];

  @override
  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testMember = FamilyMember(
    id: 'test_member_1',
    name: 'Alice Smith',
    relation: 'Self',
    age: 35,
    colorValue: 0xFF1E88E5,
    avatarEmoji: '👩',
  );

  late SharedPreferences prefs;

  setUpAll(() {
    // Returning null for asset loading causes rootBundle.load to throw a FlutterError
    // cleanly through the binary messenger channel during test PDF generation.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async => null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        healthRepositoryProvider.overrideWithValue(FakeHealthRepository(testMember)),
        activeMemberProvider.overrideWithValue(testMember),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: child,
      ),
    );
  }

  group('DoctorReportScreen CRIT-10 Lifecycle and Error Handling', () {
    testWidgets('Direct Print Report catches PDF errors and displays localized SnackBar without crashing', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(child: const DoctorReportScreen()),
      );
      await tester.pumpAndSettle();

      final printButton = find.widgetWithText(OutlinedButton, 'Direct Print Report');
      expect(printButton, findsOneWidget);
      expect(tester.widget<OutlinedButton>(printButton).onPressed, isNotNull);

      // Tap direct print
      await tester.tap(printButton);
      // Advance frames for error handling and SnackBar entrance
      await tester.pump(const Duration(milliseconds: 300));

      // Localized error message SnackBar must be displayed rather than crashing
      expect(find.text('Failed to print report. Please check printer settings.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Settle SnackBar dismiss timer to leave clean test state
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Share PDF button catches PDF errors and displays localized SnackBar without crashing', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(child: const DoctorReportScreen()),
      );
      await tester.pumpAndSettle();

      final shareButton = find.widgetWithText(ElevatedButton, 'Print / Share PDF Report');
      expect(shareButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(shareButton).onPressed, isNotNull);

      await tester.tap(shareButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Failed to generate PDF report. Please try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Unmounting screen while generating PDF does not throw unmounted setState error', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final showScreenNotifier = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            healthRepositoryProvider.overrideWithValue(FakeHealthRepository(testMember)),
            activeMemberProvider.overrideWithValue(testMember),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: ValueListenableBuilder<bool>(
              valueListenable: showScreenNotifier,
              builder: (context, show, _) {
                return show
                    ? const DoctorReportScreen()
                    : const Scaffold(body: Text('Navigated Away'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final printButton = find.widgetWithText(OutlinedButton, 'Direct Print Report');
      expect(tester.widget<OutlinedButton>(printButton).onPressed, isNotNull);

      // Start async operation
      await tester.tap(printButton);
      await tester.pump();

      // Immediately unmount DoctorReportScreen by changing state
      showScreenNotifier.value = false;
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      // Screen is unmounted, Navigated Away is displayed
      expect(find.text('Navigated Away'), findsOneWidget);
      // No unmounted setState exception was thrown
      expect(tester.takeException(), isNull);
    });
  });
}
