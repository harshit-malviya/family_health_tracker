import '../core/constants/clinical_standards.dart';

class GlucoseReading {
  final String id;
  final String memberId;
  final double valueMgDl; // Internal standard storage in mg/dL
  final MealContext mealContext;
  final String medicationNotes; // e.g. Metformin 500mg, 10 units Insulin
  final DateTime timestamp;

  const GlucoseReading({
    required this.id,
    required this.memberId,
    required this.valueMgDl,
    required this.mealContext,
    this.medicationNotes = '',
    required this.timestamp,
  });

  GlucoseCategory get category => ClinicalStandards.evaluateGlucose(valueMgDl, mealContext);

  /// Value formatted in mmol/L
  double get valueMmol => ClinicalStandards.mgDlToMmol(valueMgDl);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'valueMgDl': valueMgDl,
      'mealContext': mealContext.name,
      'medicationNotes': medicationNotes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GlucoseReading.fromMap(Map<String, dynamic> map) {
    return GlucoseReading(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      valueMgDl: (map['valueMgDl'] as num).toDouble(),
      mealContext: MealContext.values.firstWhere(
        (e) => e.name == map['mealContext'],
        orElse: () => MealContext.fasting,
      ),
      medicationNotes: (map['medicationNotes'] as String?) ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
