import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/ui/widgets/metric_summary_card.dart';
import 'package:health_tracker/ui/screens/onboarding_screen.dart';
import 'package:health_tracker/core/constants/app_colors.dart';

void main() {
  testWidgets('MetricSummaryCard renders blood pressure details accurately', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MetricSummaryCard(
            title: 'Blood Pressure',
            primaryValue: '120/80',
            unit: 'mmHg',
            secondaryValue: '72 bpm',
            statusLabel: 'Normal',
            statusColor: AppColors.bpNormal,
            icon: Icons.favorite,
            accentColor: AppColors.primary,
            onTapLog: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Blood Pressure'), findsOneWidget);
    expect(find.text('120/80'), findsOneWidget);
    expect(find.text('mmHg'), findsOneWidget);
    expect(find.text('72 bpm'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);

    await tester.tap(find.byType(MetricSummaryCard));
    expect(tapped, isTrue);
  });

  testWidgets('OnboardingScreen renders initial first profile form with disabled continue button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: OnboardingScreen(),
        ),
      ),
    );

    // Initial branding and form fields
    expect(find.text('Family Health Tracker'), findsOneWidget);
    expect(find.text('Create Your First Profile'), findsOneWidget);
    expect(find.text('Self'), findsOneWidget); // Pre-selected relation
    expect(find.text('Continue to Dashboard'), findsOneWidget);

    // Continue button is disabled because no profile has been saved yet
    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue to Dashboard'),
    );
    expect(continueButton.onPressed, isNull);
  });
}
