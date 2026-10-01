import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/core/constants/clinical_standards.dart';
import 'package:health_tracker/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final key = utf8.decode(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
      final file = File(key);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
      }
      return null;
    });
  });

  group('PdfReportService CRIT-01 Tests', () {
    test('successfully generates PDF with Hindi Unicode characters without crashing', () async {
      const member = FamilyMember(
        id: 'member_hindi_1',
        name: 'राहुल शर्मा', // Hindi Patient Name
        relation: 'पिता', // Hindi Relationship
        age: 58,
        colorValue: 0xFF1E88E5,
        avatarEmoji: '👨',
      );

      final bpReadings = [
        BpReading(
          id: 'bp_1',
          memberId: member.id,
          systolic: 125,
          diastolic: 82,
          pulse: 72,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          notes: 'सुबह की दवा के बाद हल्का चक्कर', // Hindi clinical notes
        ),
      ];

      final glucoseReadings = [
        GlucoseReading(
          id: 'glu_1',
          memberId: member.id,
          valueMgDl: 110,
          mealContext: MealContext.fasting,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          medicationNotes: 'भोजन से 30 मिनट पहले इंसुलिन', // Hindi medication notes
        ),
      ];

      final pdfBytes = await PdfReportService.generateReport(
        member: member,
        bpReadings: bpReadings,
        glucoseReadings: glucoseReadings,
        unit: 'mg/dL',
        dateRangeTitle: 'Past 30 Days',
      );

      // Verify PDF is generated and valid
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));

      // Standard PDF magic header: %PDF-
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}
