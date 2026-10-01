import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bp_reading.dart';
import '../../models/glucose_reading.dart';
import '../../providers/health_providers.dart';
import '../widgets/family_member_header.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bpReadings = ref.watch(bpReadingsProvider).asData?.value ?? [];
    final glucoseReadings = ref.watch(glucoseReadingsProvider).asData?.value ?? [];
    final unit = ref.watch(glucoseUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends & Analytics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(124),
          child: Column(
            children: [
              const FamilyMemberHeader(),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.favorite, size: 20), text: 'Blood Pressure'),
                  Tab(icon: Icon(Icons.water_drop, size: 20), text: 'Blood Glucose'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // BP Tab
          _buildBpAnalytics(bpReadings),
          // Glucose Tab
          _buildGlucoseAnalytics(glucoseReadings, unit),
        ],
      ),
    );
  }

  Widget _buildBpAnalytics(List<BpReading> bpReadings) {
    if (bpReadings.isEmpty) {
      return const Center(
        child: Text('No blood pressure logs yet for this member.'),
      );
    }

    // Sort chronologically for chart
    final sorted = [...bpReadings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recent = sorted.length > 14 ? sorted.sublist(sorted.length - 14) : sorted;

    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];

    for (int i = 0; i < recent.length; i++) {
      sysSpots.add(FlSpot(i.toDouble(), recent[i].systolic.toDouble()));
      diaSpots.add(FlSpot(i.toDouble(), recent[i].diastolic.toDouble()));
    }

    // Morning vs Evening calculations
    int morningSysTotal = 0, morningCount = 0;
    int eveningSysTotal = 0, eveningCount = 0;

    for (final r in recent) {
      final hour = r.timestamp.hour;
      if (hour >= 5 && hour < 12) {
        morningSysTotal += r.systolic;
        morningCount++;
      } else if (hour >= 17 && hour < 23) {
        eveningSysTotal += r.systolic;
        eveningCount++;
      }
    }

    final morningAvg = morningCount > 0 ? (morningSysTotal / morningCount).toStringAsFixed(0) : '--';
    final eveningAvg = eveningCount > 0 ? (eveningSysTotal / eveningCount).toStringAsFixed(0) : '--';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BP Timeline (Last Readings)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _buildLegend(color: AppColors.primary, label: 'SYS'),
                        const SizedBox(width: 12),
                        _buildLegend(color: AppColors.secondary, label: 'DIA'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        getTouchedSpotIndicator: (LineChartBarData barData, List<int> indicators) {
                          return indicators.map((index) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: Colors.grey.withValues(alpha: 0.35),
                                strokeWidth: 1.5,
                                dashArray: [4, 4],
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: bar.color ?? AppColors.primary,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.white,
                          tooltipBorderRadius: BorderRadius.circular(12),
                          tooltipBorder: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          maxContentWidth: 200,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isSystolic = spot.barIndex == 0;
                              final isFirst = spot == touchedSpots.first;
                              final index = spot.x.toInt();
                              final reading = (index >= 0 && index < recent.length) ? recent[index] : null;
                              final dateStr = reading != null
                                  ? DateFormat('d MMM, h:mm a').format(reading.timestamp)
                                  : '';

                              if (isFirst && dateStr.isNotEmpty) {
                                return LineTooltipItem(
                                  '$dateStr\n',
                                  const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: isSystolic ? 'SYS: ${spot.y.toInt()} mmHg' : 'DIA: ${spot.y.toInt()} mmHg',
                                      style: TextStyle(
                                        color: isSystolic ? AppColors.primary : AppColors.secondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (reading != null && reading.pulse > 0)
                                      TextSpan(
                                        text: '  (${reading.pulse} bpm)',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                );
                              } else {
                                return LineTooltipItem(
                                  isSystolic ? 'SYS: ${spot.y.toInt()} mmHg' : 'DIA: ${spot.y.toInt()} mmHg',
                                  TextStyle(
                                    color: isSystolic ? AppColors.primary : AppColors.secondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (recent.length / 4).ceilToDouble().clamp(1.0, 5.0),
                            getTitlesWidget: (val, meta) {
                              final index = val.toInt();
                              if (index >= 0 && index < recent.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('d/M').format(recent[index].timestamp),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 50,
                      maxY: 190,
                      lineBarsData: [
                        // Systolic Line
                        LineChartBarData(
                          spots: sysSpots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                        ),
                        // Diastolic Line
                        LineChartBarData(
                          spots: diaSpots,
                          isCurved: true,
                          color: AppColors.secondary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Morning vs Evening Averages
          const Text(
            'Circadian Patterns',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPatternCard(
                  title: 'Morning SYS Avg',
                  value: morningAvg,
                  unit: 'mmHg',
                  icon: Icons.wb_sunny_rounded,
                  color: Colors.amber.shade700,
                  sub: '5 AM – 12 PM',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPatternCard(
                  title: 'Evening SYS Avg',
                  value: eveningAvg,
                  unit: 'mmHg',
                  icon: Icons.nights_stay_rounded,
                  color: Colors.indigo.shade400,
                  sub: '5 PM – 11 PM',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseAnalytics(List<GlucoseReading> glucoseReadings, String unit) {
    if (glucoseReadings.isEmpty) {
      return const Center(
        child: Text('No blood glucose logs yet for this member.'),
      );
    }

    final sorted = [...glucoseReadings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recent = sorted.length > 14 ? sorted.sublist(sorted.length - 14) : sorted;

    final spots = <FlSpot>[];
    for (int i = 0; i < recent.length; i++) {
      final val = unit == 'mmol/L' ? recent[i].valueMmol : recent[i].valueMgDl;
      spots.add(FlSpot(i.toDouble(), (val as num).toDouble()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Glucose Curve ($unit)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    _buildLegend(color: AppColors.secondary, label: 'Blood Sugar'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        getTouchedSpotIndicator: (LineChartBarData barData, List<int> indicators) {
                          return indicators.map((index) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: Colors.grey.withValues(alpha: 0.35),
                                strokeWidth: 1.5,
                                dashArray: [4, 4],
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: bar.color ?? AppColors.secondary,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.white,
                          tooltipBorderRadius: BorderRadius.circular(12),
                          tooltipBorder: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          maxContentWidth: 200,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              final reading = (index >= 0 && index < recent.length) ? recent[index] : null;
                              final dateStr = reading != null
                                  ? DateFormat('d MMM, h:mm a').format(reading.timestamp)
                                  : '';
                              final valStr = unit == 'mmol/L'
                                  ? spot.y.toStringAsFixed(1)
                                  : spot.y.toInt().toString();
                              final meal = reading?.mealContext.label ?? '';

                              return LineTooltipItem(
                                dateStr.isNotEmpty ? '$dateStr\n' : '',
                                const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$valStr $unit',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (meal.isNotEmpty)
                                    TextSpan(
                                      text: '  •  $meal',
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (val, meta) => Text(
                              unit == 'mmol/L' ? val.toStringAsFixed(1) : val.toInt().toString(),
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (recent.length / 4).ceilToDouble().clamp(1.0, 5.0),
                            getTitlesWidget: (val, meta) {
                              final index = val.toInt();
                              if (index >= 0 && index < recent.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('d/M').format(recent[index].timestamp),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.secondary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.secondary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildPatternCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
