import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bp_reading.dart';
import '../../models/glucose_reading.dart';
import '../../providers/health_providers.dart';
import '../widgets/family_member_header.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'BP', 'Glucose'

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(activeMemberProvider);
    final bpReadings = ref.watch(bpReadingsProvider).asData?.value ?? [];
    final glucoseReadings = ref.watch(glucoseReadingsProvider).asData?.value ?? [];
    final unit = ref.watch(glucoseUnitProvider);

    // Combine both logs into unified chronologically sorted timeline
    final combinedLogs = <Map<String, dynamic>>[];

    if (_selectedFilter == 'All' || _selectedFilter == 'BP') {
      for (final bp in bpReadings) {
        combinedLogs.add({'type': 'BP', 'data': bp, 'timestamp': bp.timestamp});
      }
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Glucose') {
      for (final g in glucoseReadings) {
        combinedLogs.add({'type': 'Glucose', 'data': g, 'timestamp': g.timestamp});
      }
    }

    combinedLogs.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Readings History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              const FamilyMemberHeader(),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('BP'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Glucose'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      body: combinedLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No $_selectedFilter records for ${member?.name ?? "this member"} yet.',
                    style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: combinedLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = combinedLogs[index];
                if (item['type'] == 'BP') {
                  final bp = item['data'] as BpReading;
                  return _buildBpTile(context, bp);
                } else {
                  final g = item['data'] as GlucoseReading;
                  return _buildGlucoseTile(context, g, unit);
                }
              },
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textDark,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = label);
      },
    );
  }

  Widget _buildBpTile(BuildContext context, BpReading bp) {
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(bp.timestamp);

    return Dismissible(
      key: Key(bp.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(bpReadingsProvider.notifier).deleteReading(bp.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading deleted')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.favorite, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${bp.systolic}/${bp.diastolic} mmHg',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bp.category.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bp.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bp.category.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Pulse: ${bp.pulse} bpm • ${bp.arm} arm, ${bp.posture}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      if (bp.hasArrhythmia) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                      ],
                    ],
                  ),
                  if (bp.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: "${bp.notes}"',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textDark),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _confirmDelete(bp.id, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlucoseTile(BuildContext context, GlucoseReading g, String unit) {
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(g.timestamp);
    final valueStr = unit == 'mmol/L'
        ? '${g.valueMmol.toStringAsFixed(1)} mmol/L'
        : '${g.valueMgDl.toStringAsFixed(0)} mg/dL';

    return Dismissible(
      key: Key(g.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(glucoseReadingsProvider.notifier).deleteReading(g.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading deleted')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.water_drop, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        valueStr,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: g.category.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: g.category.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Context: ${g.mealContext.label}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (g.medicationNotes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Medication: "${g.medicationNotes}"',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textDark),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _confirmDelete(g.id, false),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, bool isBp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reading?'),
        content: const Text('Are you sure you want to permanently delete this reading?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (isBp) {
                ref.read(bpReadingsProvider.notifier).deleteReading(id);
              } else {
                ref.read(glucoseReadingsProvider.notifier).deleteReading(id);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
