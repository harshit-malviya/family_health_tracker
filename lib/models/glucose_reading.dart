import '../core/constants/clinical_standards.dart';

class GlucoseReading {
  final String id;
  final String memberId;
  final double valueMgDl; // Internal standard storage in mg/dL
  final MealContext mealContext;
  final String medicationNotes; // e.g. Metformin 500mg, 10 units Insulin
  final DateTime timestamp;
  final String? familyId;
  final String? createdBy;
  final String? loggedByName;

  const GlucoseReading({
    required this.id,
    required this.memberId,
    required this.valueMgDl,
    required this.mealContext,
    this.medicationNotes = '',
    required this.timestamp,
    this.familyId,
    this.createdBy,
    this.loggedByName,
  });

  GlucoseCategory get category => ClinicalStandards.evaluateGlucose(valueMgDl, mealContext);

  /// Value formatted in mmol/L
  double get valueMmol => ClinicalStandards.mgDlToMmol(valueMgDl);

  GlucoseReading copyWith({
    String? id,
    String? memberId,
    double? valueMgDl,
    MealContext? mealContext,
    String? medicationNotes,
    DateTime? timestamp,
    String? familyId,
    String? createdBy,
    String? loggedByName,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      valueMgDl: valueMgDl ?? this.valueMgDl,
      mealContext: mealContext ?? this.mealContext,
      medicationNotes: medicationNotes ?? this.medicationNotes,
      timestamp: timestamp ?? this.timestamp,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      loggedByName: loggedByName ?? this.loggedByName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'valueMgDl': valueMgDl,
      'mealContext': mealContext.name,
      'medicationNotes': medicationNotes,
      'timestamp': timestamp.toIso8601String(),
      'familyId': familyId,
      'createdBy': createdBy,
      'loggedByName': loggedByName,
    };
  }

  factory GlucoseReading.fromMap(Map<String, dynamic> map) {
    return GlucoseReading(
      id: map['id'] as String,
      memberId: (map['memberId'] ?? map['member_id']) as String,
      valueMgDl: (map['valueMgDl'] ?? map['value_mg_dl'] as num).toDouble(),
      mealContext: MealContext.values.firstWhere(
        (e) => e.name == (map['mealContext'] ?? map['meal_context']),
        orElse: () => MealContext.fasting,
      ),
      medicationNotes: (map['medicationNotes'] ?? map['medication_notes'] as String?) ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      familyId: (map['familyId'] ?? map['family_id']) as String?,
      createdBy: (map['createdBy'] ?? map['created_by']) as String?,
      loggedByName: (map['loggedByName'] ?? map['logged_by_name']) as String?,
    );
  }

  /// Converts model for Supabase table `public.glucose_readings`
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'member_id': memberId,
      'value_mg_dl': valueMgDl,
      'meal_context': mealContext.name,
      'medication_notes': medicationNotes,
      'timestamp': timestamp.toIso8601String(),
      if (familyId != null) 'family_id': familyId,
      if (createdBy != null) 'created_by': createdBy,
      'logged_by_name': (loggedByName != null && loggedByName!.isNotEmpty)
          ? loggedByName
          : 'Family Member',
    };
  }
}
