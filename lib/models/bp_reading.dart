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
  final String? familyId;
  final String? createdBy;
  final String? loggedByName;
  final bool isPendingSync;

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
    this.familyId,
    this.createdBy,
    this.loggedByName,
    this.isPendingSync = false,
  });

  BpCategory get category => ClinicalStandards.evaluateBp(systolic, diastolic);

  BpReading copyWith({
    String? id,
    String? memberId,
    int? systolic,
    int? diastolic,
    int? pulse,
    String? arm,
    String? posture,
    bool? hasArrhythmia,
    String? notes,
    DateTime? timestamp,
    String? familyId,
    String? createdBy,
    String? loggedByName,
    bool? isPendingSync,
  }) {
    return BpReading(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      arm: arm ?? this.arm,
      posture: posture ?? this.posture,
      hasArrhythmia: hasArrhythmia ?? this.hasArrhythmia,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      loggedByName: loggedByName ?? this.loggedByName,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

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
      'familyId': familyId,
      'createdBy': createdBy,
      'loggedByName': loggedByName,
      'isPendingSync': isPendingSync ? 1 : 0,
    };
  }

  factory BpReading.fromMap(Map<String, dynamic> map) {
    return BpReading(
      id: map['id'] as String,
      memberId: (map['memberId'] ?? map['member_id']) as String,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      pulse: map['pulse'] as int,
      arm: (map['arm'] as String?) ?? 'Left',
      posture: (map['posture'] as String?) ?? 'Sitting',
      hasArrhythmia: map['hasArrhythmia'] is bool
          ? map['hasArrhythmia'] as bool
          : (map['hasArrhythmia'] as int? ?? (map['has_arrhythmia'] == true ? 1 : 0)) == 1,
      notes: (map['notes'] as String?) ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      familyId: (map['familyId'] ?? map['family_id']) as String?,
      createdBy: (map['createdBy'] ?? map['created_by']) as String?,
      loggedByName: (map['loggedByName'] ?? map['logged_by_name']) as String?,
      isPendingSync: (map['isPendingSync'] == 1 || map['isPendingSync'] == true),
    );
  }

  /// Converts model for Supabase table `public.bp_readings`
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'member_id': memberId,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'arm': arm,
      'posture': posture,
      'has_arrhythmia': hasArrhythmia,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      if (familyId != null) 'family_id': familyId,
      if (createdBy != null) 'created_by': createdBy,
      'logged_by_name': (loggedByName != null && loggedByName!.isNotEmpty)
          ? loggedByName
          : 'Family Member',
    };
  }
}
