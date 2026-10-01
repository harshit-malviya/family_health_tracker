import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/clinical_standards.dart';
import '../../providers/health_providers.dart';
import '../widgets/family_member_header.dart';
import '../widgets/metric_summary_card.dart';
import '../widgets/quick_bp_modal.dart';
import '../widgets/quick_glucose_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(activeMemberProvider);
    final bpReadings = ref.watch(bpReadingsProvider).asData?.value ?? [];
    final glucoseReadings = ref.watch(glucoseReadingsProvider).asData?.value ?? [];
    final bpStats = ref.watch(bpStatsProvider);
    final glucoseStats = ref.watch(glucoseStatsProvider);
    final unit = ref.watch(glucoseUnitProvider);

    final latestBp = bpReadings.isNotEmpty ? bpReadings.first : null;
    final latestGlucose = glucoseReadings.isNotEmpty ? glucoseReadings.first : null;

    final bpValueStr = latestBp != null ? '${latestBp.systolic}/${latestBp.diastolic}' : '--/--';
    final pulseStr = latestBp != null ? '${latestBp.pulse} bpm' : null;

    String glucoseValueStr = '--';
    if (latestGlucose != null) {
      if (unit == 'mmol/L') {
        glucoseValueStr = latestGlucose.valueMmol.toStringAsFixed(1);
      } else {
        glucoseValueStr = latestGlucose.valueMgDl.toStringAsFixed(0);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member != null ? '${member.avatarEmoji} ${member.name}' : 'Family Health',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (member != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: member.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${member.age} yrs',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: member.color,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Daily BP & Blood Sugar records',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.refresh, size: 20, color: AppColors.textDark),
                      ),
                      onPressed: () {
                        ref.read(bpReadingsProvider.notifier).loadReadings();
                        ref.read(glucoseReadingsProvider.notifier).loadReadings();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Family Member Selector Carousel
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: FamilyMemberHeader(),
              ),
            ),

            // Main Content Cards
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Blood Pressure Card
                  MetricSummaryCard(
                    title: 'Blood Pressure',
                    primaryValue: bpValueStr,
                    unit: 'mmHg',
                    secondaryValue: pulseStr,
                    statusLabel: latestBp?.category.label,
                    statusColor: latestBp?.category.color ?? AppColors.bpNormal,
                    subtitle: latestBp != null ? '${latestBp.arm} arm, ${latestBp.posture}' : null,
                    timestamp: latestBp?.timestamp,
                    icon: Icons.favorite_rounded,
                    accentColor: AppColors.primary,
                    onTapLog: () => _openBpModal(context),
                  ),
                  const SizedBox(height: 16),

                  // Blood Sugar Card
                  MetricSummaryCard(
                    title: 'Blood Sugar / Glucose',
                    primaryValue: glucoseValueStr,
                    unit: unit,
                    statusLabel: latestGlucose?.category.label,
                    statusColor: latestGlucose?.category.color ?? AppColors.glucoseNormal,
                    subtitle: latestGlucose?.mealContext.label,
                    timestamp: latestGlucose?.timestamp,
                    icon: Icons.water_drop_rounded,
                    accentColor: AppColors.secondary,
                    onTapLog: () => _openGlucoseModal(context),
                  ),
                  const SizedBox(height: 24),

                  // 7-Day Health Snapshot Card
                  if (bpStats != null || glucoseStats != null) ...[
                    const Text(
                      'Overview & Averages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withOpacity(0.12)),
                      ),
                      child: Column(
                        children: [
                          if (bpStats != null) ...[
                            _buildStatRow(
                              icon: Icons.favorite,
                              color: AppColors.primary,
                              label: 'Avg Blood Pressure',
                              value:
                                  '${bpStats.avgSystolic.toStringAsFixed(0)}/${bpStats.avgDiastolic.toStringAsFixed(0)} mmHg',
                              badgeText: '${bpStats.normalPercentage.toStringAsFixed(0)}% normal',
                              badgeColor: bpStats.normalPercentage > 70
                                  ? AppColors.bpNormal
                                  : AppColors.bpElevated,
                            ),
                            if (glucoseStats != null)
                              const Divider(height: 24, thickness: 0.8),
                          ],
                          if (glucoseStats != null) ...[
                            _buildStatRow(
                              icon: Icons.water_drop,
                              color: AppColors.secondary,
                              label: 'Avg Blood Glucose',
                              value: unit == 'mmol/L'
                                  ? '${ClinicalStandards.mgDlToMmol(glucoseStats.avgMgDl).toStringAsFixed(1)} mmol/L'
                                  : '${glucoseStats.avgMgDl.toStringAsFixed(0)} mg/dL',
                              badgeText: '${glucoseStats.inRangeCount}/${glucoseStats.count} in target',
                              badgeColor: AppColors.glucoseNormal,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 80), // Padding for bottom navbar
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Reading'),
        onPressed: () => _showQuickPicker(context),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'What are you measuring?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.favorite, color: AppColors.primary),
                ),
                title: const Text('Blood Pressure & Pulse', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Systolic, Diastolic, Heart rate'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBpModal(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.water_drop, color: AppColors.secondary),
                ),
                title: const Text('Blood Glucose / Sugar', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Fasting, Post-meal, Bedtime'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _openGlucoseModal(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickBpModal(),
    );
  }

  void _openGlucoseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickGlucoseModal(),
    );
  }
}
