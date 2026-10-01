import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/providers/health_providers.dart';
import 'package:health_tracker/repositories/health_repository.dart';
import 'package:health_tracker/ui/screens/history_screen.dart';

class MockHealthRepository extends HealthRepository {
  final List<FamilyMember> members = [
    const FamilyMember(
      id: 'member_1',
      name: 'Dad',
      relation: 'Father',
      age: 60,
      colorValue: 0xFF1E88E5,
      avatarEmoji: '👨',
    ),
  ];

  final List<BpReading> bpList = [
    BpReading(
      id: 'bp_1',
      memberId: 'member_1',
      systolic: 120,
      diastolic: 80,
      pulse: 70,
      timestamp: DateTime(2026, 10, 1, 10, 0),
    ),
  ];

  final List<GlucoseReading> glucoseList = [];

  @override
  Future<List<FamilyMember>> getFamilyMembers() async => members;

  @override
  Future<List<BpReading>> getBpReadings(String memberId) async => List.from(bpList);

  @override
  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) async => List.from(glucoseList);

  @override
  Future<void> deleteBpReading(String id) async {
    bpList.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> addBpReading(BpReading reading) async {
    bpList.add(reading);
  }
}

void main() {
  testWidgets('HistoryScreen deletion guard: no swipe, tap hint, dialog confirm, and undo restoration', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_completed_onboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final mockRepo = MockHealthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          healthRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify NO Dismissible widgets exist in the widget tree (swipe-to-delete eliminated)
    expect(find.byType(Dismissible), findsNothing);

    // 2. Verify reading card is displayed
    expect(find.text('120/80 mmHg'), findsOneWidget);

    // 3. Tap card: verify hint SnackBar appears ("Long press card to edit or delete.")
    await tester.tap(find.text('120/80 mmHg'));
    await tester.pump();
    expect(find.text('Long press card to edit or delete.'), findsOneWidget);

    // Wait for SnackBar to dismiss
    await tester.pump(const Duration(seconds: 3));

    // 4. Long-press card: verify action sheet modal opens
    await tester.longPress(find.text('120/80 mmHg'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Reading'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // 5. Tap Delete in action sheet: verify confirmation AlertDialog appears
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Reading?'), findsOneWidget);
    expect(find.text('Are you sure you want to permanently delete this reading?'), findsOneWidget);

    // 6. Tap Delete in AlertDialog: confirm deletion and verify Undo SnackBar appears
    final deleteButtons = find.widgetWithText(TextButton, 'Delete');
    await tester.tap(deleteButtons);
    await tester.pumpAndSettle();

    // Card should be deleted from list
    expect(find.text('120/80 mmHg'), findsNothing);
    expect(find.text('Reading deleted.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // 7. Tap Undo: verify reading is restored back into the list
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('120/80 mmHg'), findsOneWidget);
  });
}
