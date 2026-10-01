import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/ui/widgets/metric_summary_card.dart';
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
}
