import '../core/constants/clinical_standards.dart';

class BpReading {
  final String id;
  final String memberId;
  final int systolic; // mmHg
  final int diastolic; // mmHg
  final int pulse; // bpm
  final String arm; // 'Left', 'Right'
  final String posture; // 'Sitting', 'Lying', 'Standing'
  final bool hasArrhythmia; // Irregular heartbeat detected by machine
  final String notes;
  final DateTime timestamp;

  const BpReading({
    required this.id,
    required this.memberId,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    this.arm = 'Left',
    this.posture = 'Sitting',
    this.hasArrhythmia = false,
    this.notes = '',
    required this.timestamp,
  });

  BpCategory get category => ClinicalStandards.evaluateBp(systolic, diastolic);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'arm': arm,
      'posture': posture,
      'hasArrhythmia': hasArrhythmia ? 1 : 0,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BpReading.fromMap(Map<String, dynamic> map) {
    return BpReading(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      pulse: map['pulse'] as int,
      arm: (map['arm'] as String?) ?? 'Left',
      posture: (map['posture'] as String?) ?? 'Sitting',
      hasArrhythmia: (map['hasArrhythmia'] as int?) == 1,
      notes: (map['notes'] as String?) ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
