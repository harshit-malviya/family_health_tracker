import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/health_providers.dart';
import '../../services/pdf_report_service.dart';
import '../widgets/family_member_header.dart';

class DoctorReportScreen extends ConsumerStatefulWidget {
  const DoctorReportScreen({super.key});

  @override
  ConsumerState<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends ConsumerState<DoctorReportScreen> {
  int _selectedDays = 30; // 7, 30, 90, 365
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final member = ref.watch(activeMemberProvider);
    final allBp = ref.watch(bpReadingsProvider).asData?.value ?? [];
    final allGlucose = ref.watch(glucoseReadingsProvider).asData?.value ?? [];
    final unit = ref.watch(glucoseUnitProvider);

    // Filter by selected days
    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedDays));
    final filteredBp = allBp.where((r) => r.timestamp.isAfter(cutoffDate)).toList();
    final filteredGlucose = allGlucose.where((r) => r.timestamp.isAfter(cutoffDate)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorReportTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: FamilyMemberHeader(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinical Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.secondary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.physicianSummaryPdf,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              member != null
                                  ? l10n.readyToPrintFor(member.name)
                                  : l10n.selectFamilyMember,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.selectTimePeriod,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildRangeChip(7, l10n.days7),
                      _buildRangeChip(30, l10n.days30),
                      _buildRangeChip(90, l10n.days90),
                      _buildRangeChip(365, l10n.days365),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Report Preview Summary Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.includeInReport,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildInclusionItem(
                    Icons.favorite,
                    AppColors.primary,
                    '${filteredBp.length} ${l10n.includeBpLogs}',
                  ),
                  const SizedBox(height: 8),
                  _buildInclusionItem(
                    Icons.water_drop,
                    AppColors.secondary,
                    '${filteredGlucose.length} ${l10n.includeGlucoseLogs} ($unit)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Share PDF Button
            ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded),
              label: Text(_isGenerating ? l10n.generatingPdf : l10n.printOrSharePdf),
              onPressed: (member == null || _isGenerating)
                  ? null
                  : () async {
                      setState(() => _isGenerating = true);
                      try {
                        final bytes = await PdfReportService.generateReport(
                          member: member,
                          bpReadings: filteredBp,
                          glucoseReadings: filteredGlucose,
                          unit: unit,
                          dateRangeTitle: 'Past $_selectedDays Days',
                        );
                        await PdfReportService.shareOrPrintPdf(bytes, member.name);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to generate PDF: $e')),
                          );
                        }
                      } finally {
                        setState(() => _isGenerating = false);
                      }
                    },
            ),
            const SizedBox(height: 12),

            // Print PDF Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.print_rounded),
              label: const Text('Direct Print Report'),
              onPressed: (member == null || _isGenerating)
                  ? null
                  : () async {
                      setState(() => _isGenerating = true);
                      try {
                        final bytes = await PdfReportService.generateReport(
                          member: member,
                          bpReadings: filteredBp,
                          glucoseReadings: filteredGlucose,
                          unit: unit,
                          dateRangeTitle: 'Past $_selectedDays Days',
                        );
                        await Printing.layoutPdf(
                          onLayout: (format) async => bytes,
                          name: 'Health_Report_${member.name}.pdf',
                        );
                      } finally {
                        setState(() => _isGenerating = false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.secondaryLight,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.secondary : AppColors.textDark,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedDays = days);
      },
    );
  }

  Widget _buildInclusionItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        ),
      ],
    );
  }
}
