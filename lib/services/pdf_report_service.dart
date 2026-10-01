import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/family_member.dart';
import '../models/bp_reading.dart';
import '../models/glucose_reading.dart';
import '../core/constants/clinical_standards.dart';

class PdfReportService {
  static Future<Uint8List> generateReport({
    required FamilyMember member,
    required List<BpReading> bpReadings,
    required List<GlucoseReading> glucoseReadings,
    required String unit,
    required String dateRangeTitle,
  }) async {
    final pdf = pw.Document();

    // Summary calculations
    double avgSys = 0, avgDia = 0, avgPulse = 0;
    if (bpReadings.isNotEmpty) {
      for (final bp in bpReadings) {
        avgSys += bp.systolic;
        avgDia += bp.diastolic;
        avgPulse += bp.pulse;
      }
      avgSys /= bpReadings.length;
      avgDia /= bpReadings.length;
      avgPulse /= bpReadings.length;
    }

    double avgGlucose = 0;
    if (glucoseReadings.isNotEmpty) {
      for (final g in glucoseReadings) {
        avgGlucose += g.valueMgDl;
      }
      avgGlucose /= glucoseReadings.length;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Clinical Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Family Health Clinical Report',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Automated Patient Blood Pressure & Glucose Log',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(dateRangeTitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blueGrey200),
            pw.SizedBox(height: 12),

            // Patient Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPatientAttribute('Patient Name', member.name),
                  _buildPatientAttribute('Relationship', member.relation),
                  _buildPatientAttribute('Age', '${member.age} yrs'),
                  _buildPatientAttribute('BP Readings', '${bpReadings.length} logs'),
                  _buildPatientAttribute('Glucose Readings', '${glucoseReadings.length} logs'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Clinical Summary Metrics Grid
            pw.Text(
              'Summary Statistics',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMetricBox(
                    'Average Blood Pressure',
                    bpReadings.isNotEmpty
                        ? '${avgSys.toStringAsFixed(0)} / ${avgDia.toStringAsFixed(0)} mmHg'
                        : 'N/A',
                    'Pulse: ${avgPulse.toStringAsFixed(0)} bpm',
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _buildMetricBox(
                    'Average Blood Glucose',
                    glucoseReadings.isNotEmpty
                        ? (unit == 'mmol/L'
                            ? '${ClinicalStandards.mgDlToMmol(avgGlucose).toStringAsFixed(1)} mmol/L'
                            : '${avgGlucose.toStringAsFixed(0)} mg/dL')
                        : 'N/A',
                    unit == 'mmol/L' ? 'Target: 3.9 - 7.2 mmol/L' : 'Target: 70 - 130 mg/dL',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Blood Pressure Table
            if (bpReadings.isNotEmpty) ...[
              pw.Text(
                'Blood Pressure Records (AHA / ACC 2017)',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Date & Time', 'SYS/DIA (mmHg)', 'Pulse (bpm)', 'AHA Category', 'Arm/Posture', 'Notes'],
                data: bpReadings.map((r) {
                  return [
                    DateFormat('d MMM, h:mm a').format(r.timestamp),
                    '${r.systolic} / ${r.diastolic}',
                    '${r.pulse}',
                    r.category.label,
                    '${r.arm}, ${r.posture}',
                    r.notes.isNotEmpty ? r.notes : '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              ),
              pw.SizedBox(height: 18),
            ],

            // Blood Glucose Table
            if (glucoseReadings.isNotEmpty) ...[
              pw.Text(
                'Blood Glucose Records (ADA 2024)',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Date & Time', 'Reading ($unit)', 'Context / Timing', 'ADA Status', 'Medication Notes'],
                data: glucoseReadings.map((g) {
                  final valStr = unit == 'mmol/L'
                      ? g.valueMmol.toStringAsFixed(1)
                      : g.valueMgDl.toStringAsFixed(0);
                  return [
                    DateFormat('d MMM, h:mm a').format(g.timestamp),
                    valStr,
                    g.mealContext.label,
                    g.category.label,
                    g.medicationNotes.isNotEmpty ? g.medicationNotes : '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              ),
            ],

            pw.SizedBox(height: 24),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by Family Health Tracker app', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text('Confidential Medical Log', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPatientAttribute(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildMetricBox(String title, String mainValue, String subValue) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(mainValue, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(subValue, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static Future<void> shareOrPrintPdf(Uint8List pdfBytes, String patientName) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Health_Report_${patientName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
