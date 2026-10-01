import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/clinical_standards.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bp_reading.dart';
import '../../models/glucose_reading.dart';
import '../../providers/health_providers.dart';
import '../widgets/family_member_header.dart';
import '../widgets/quick_bp_modal.dart';
import '../widgets/quick_glucose_modal.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'BP', 'Glucose'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    final filterDisplayMap = {
      'All': l10n.filterAll,
      'BP': l10n.filterBp,
      'Glucose': l10n.filterGlucose,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.readingsHistory),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Switcher Carousel
          const SizedBox(height: 4),
          const FamilyMemberHeader(),
          const SizedBox(height: 10),

          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', l10n.filterAll),
                  const SizedBox(width: 8),
                  _buildFilterChip('BP', l10n.filterBp),
                  const SizedBox(width: 8),
                  _buildFilterChip('Glucose', l10n.filterGlucose),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Main Timeline List
          Expanded(
            child: combinedLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            l10n.noRecordsYet(
                              filterDisplayMap[_selectedFilter] ?? _selectedFilter,
                              member?.name ?? '',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: combinedLogs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String displayLabel) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(displayLabel),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textDark,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildBpTile(BuildContext context, BpReading bp) {
    final l10n = AppLocalizations.of(context)!;
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(bp.timestamp);
    final armStr = bp.arm.toLowerCase() == 'left' ? l10n.armLeft : l10n.armRight;
    final postureStr = _getLocalizedPosture(l10n, bp.posture);

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
          SnackBar(content: Text(l10n.readingDeleted)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onLongPress: () => _showCardActionSheet(context, bp: bp),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.favorite, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Responsive Wrap for SYS/DIA and Category Badge
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${bp.systolic}/${bp.diastolic} mmHg',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: bp.category.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bp.category.localizedLabel(l10n),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: bp.category.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Subtitle line (Pulse, Arm, Posture)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.pulse}: ${bp.pulse} ${l10n.bpm} • $armStr, $postureStr',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (bp.hasArrhythmia) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                            ],
                          ],
                        ),
                        if (bp.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${bp.notes}"',
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlucoseTile(BuildContext context, GlucoseReading g, String unit) {
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.readingDeleted)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onLongPress: () => _showCardActionSheet(context, glucose: g),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.water_drop, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Responsive Wrap for Value and Status Badge
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              valueStr,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: g.category.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                g.category.localizedLabel(l10n),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: g.category.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.timingMealContext}: ${g.mealContext.localizedLabel(l10n)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        if (g.medicationNotes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${g.medicationNotes}"',
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedPosture(AppLocalizations l10n, String posture) {
    switch (posture.toLowerCase()) {
      case 'sitting':
        return l10n.postureSitting;
      case 'lying':
      case 'lying down':
        return l10n.postureLying;
      case 'standing':
        return l10n.postureStanding;
      default:
        return posture;
    }
  }

  void _showCardActionSheet(BuildContext context, {BpReading? bp, GlucoseReading? glucose}) {
    final l10n = AppLocalizations.of(context)!;
    final title = bp != null
        ? '${bp.systolic}/${bp.diastolic} mmHg (${bp.category.localizedLabel(l10n)})'
        : '${glucose?.valueMgDl.toStringAsFixed(0)} mg/dL (${glucose?.mealContext.localizedLabel(l10n)})';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                ),
                title: Text(l10n.editReading, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(l10n.dateTimeOfReading),
                onTap: () {
                  Navigator.pop(ctx);
                  if (bp != null) _editBp(context, bp);
                  if (glucose != null) _editGlucose(context, glucose);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
                title: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: Text(l10n.deleteReadingConfirm),
                onTap: () {
                  Navigator.pop(ctx);
                  if (bp != null) _confirmDelete(bp.id, true);
                  if (glucose != null) _confirmDelete(glucose.id, false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editBp(BuildContext context, BpReading bp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickBpModal(initialReading: bp),
    );
  }

  void _editGlucose(BuildContext context, GlucoseReading g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickGlucoseModal(initialReading: g),
    );
  }

  void _confirmDelete(String id, bool isBp) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteReadingTitle),
        content: Text(l10n.deleteReadingConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              if (isBp) {
                ref.read(bpReadingsProvider.notifier).deleteReading(id);
              } else {
                ref.read(glucoseReadingsProvider.notifier).deleteReading(id);
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
