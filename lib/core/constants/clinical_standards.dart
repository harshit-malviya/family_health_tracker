import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'app_colors.dart';

enum BpCategory {
  normal('Normal', 'Under 120/80 mmHg', AppColors.bpNormal),
  elevated('Elevated', '120-129 / <80 mmHg', AppColors.bpElevated),
  stage1('Hypertension Stage 1', '130-139 / 80-89 mmHg', AppColors.bpStage1),
  stage2('Hypertension Stage 2', '140+ / 90+ mmHg', AppColors.bpStage2),
  crisis('Hypertensive Crisis', 'Higher than 180 and/or 120', AppColors.bpCrisis);

  final String label;
  final String rangeHint;
  final Color color;
  const BpCategory(this.label, this.rangeHint, this.color);
}

extension BpCategoryLocalization on BpCategory {
  String localizedLabel(AppLocalizations? l10n) {
    if (l10n == null) return label;
    switch (this) {
      case BpCategory.normal: return l10n.bpNormal;
      case BpCategory.elevated: return l10n.bpElevated;
      case BpCategory.stage1: return l10n.bpStage1;
      case BpCategory.stage2: return l10n.bpStage2;
      case BpCategory.crisis: return l10n.bpCrisis;
    }
  }

  String localizedRangeHint(AppLocalizations? l10n) {
    if (l10n == null) return rangeHint;
    switch (this) {
      case BpCategory.normal: return l10n.bpNormalHint;
      case BpCategory.elevated: return l10n.bpElevatedHint;
      case BpCategory.stage1: return l10n.bpStage1Hint;
      case BpCategory.stage2: return l10n.bpStage2Hint;
      case BpCategory.crisis: return l10n.bpCrisisHint;
    }
  }
}

enum GlucoseCategory {
  low('Low (Hypo)', 'Under 70 mg/dL', AppColors.glucoseLow),
  normal('Target Range', '70-130 mg/dL fasting, <180 post-meal', AppColors.glucoseNormal),
  elevated('Elevated', '131-180 mg/dL fasting', AppColors.glucoseElevated),
  high('High (Hyper)', 'Above 180 mg/dL', AppColors.glucoseHigh);

  final String label;
  final String rangeHint;
  final Color color;
  const GlucoseCategory(this.label, this.rangeHint, this.color);
}

extension GlucoseCategoryLocalization on GlucoseCategory {
  String localizedLabel(AppLocalizations? l10n) {
    if (l10n == null) return label;
    switch (this) {
      case GlucoseCategory.low: return l10n.glucoseLow;
      case GlucoseCategory.normal: return l10n.glucoseNormal;
      case GlucoseCategory.elevated: return l10n.glucoseElevated;
      case GlucoseCategory.high: return l10n.glucoseHigh;
    }
  }

  String localizedRangeHint(AppLocalizations? l10n) {
    if (l10n == null) return rangeHint;
    switch (this) {
      case GlucoseCategory.low: return l10n.glucoseLowHint;
      case GlucoseCategory.normal: return l10n.glucoseNormalHint;
      case GlucoseCategory.elevated: return l10n.glucoseElevatedHint;
      case GlucoseCategory.high: return l10n.glucoseHighHint;
    }
  }
}

enum MealContext {
  fasting('Fasting', 'Before any morning food'),
  beforeMeal('Before Meal', 'Pre-lunch or dinner'),
  postMeal('After Meal (2h)', '2 hours after eating'),
  bedtime('Bedtime', 'Before going to sleep'),
  random('Random', 'Any other time');

  final String label;
  final String hint;
  const MealContext(this.label, this.hint);
}

extension MealContextLocalization on MealContext {
  String localizedLabel(AppLocalizations? l10n) {
    if (l10n == null) return label;
    switch (this) {
      case MealContext.fasting: return l10n.mealFasting;
      case MealContext.beforeMeal: return l10n.mealBeforeMeal;
      case MealContext.postMeal: return l10n.mealPostMeal;
      case MealContext.bedtime: return l10n.mealBedtime;
      case MealContext.random: return l10n.mealRandom;
    }
  }

  String localizedHint(AppLocalizations? l10n) {
    if (l10n == null) return hint;
    switch (this) {
      case MealContext.fasting: return l10n.mealFastingHint;
      case MealContext.beforeMeal: return l10n.mealBeforeMealHint;
      case MealContext.postMeal: return l10n.mealPostMealHint;
      case MealContext.bedtime: return l10n.mealBedtimeHint;
      case MealContext.random: return l10n.mealRandomHint;
    }
  }
}

class ClinicalStandards {
  /// Evaluates Blood Pressure category according to AHA/ACC (2017) Guidelines
  static BpCategory evaluateBp(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return BpCategory.crisis;
    }
    if (systolic >= 140 || diastolic >= 90) {
      return BpCategory.stage2;
    }
    if ((systolic >= 130 && systolic <= 139) || (diastolic >= 80 && diastolic <= 89)) {
      return BpCategory.stage1;
    }
    if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
      return BpCategory.elevated;
    }
    return BpCategory.normal;
  }

  /// Evaluates Blood Glucose according to ADA targets in mg/dL
  static GlucoseCategory evaluateGlucose(double mgDl, MealContext context) {
    if (mgDl < 70) {
      return GlucoseCategory.low;
    }

    if (context == MealContext.fasting || context == MealContext.beforeMeal) {
      if (mgDl <= 130) return GlucoseCategory.normal;
      if (mgDl <= 180) return GlucoseCategory.elevated;
      return GlucoseCategory.high;
    } else if (context == MealContext.postMeal) {
      if (mgDl < 180) return GlucoseCategory.normal;
      if (mgDl <= 230) return GlucoseCategory.elevated;
      return GlucoseCategory.high;
    } else {
      // Bedtime or random
      if (mgDl <= 140) return GlucoseCategory.normal;
      if (mgDl <= 200) return GlucoseCategory.elevated;
      return GlucoseCategory.high;
    }
  }

  /// Convert mg/dL to mmol/L (standard factor 18.0182)
  static double mgDlToMmol(double mgDl) {
    return mgDl / 18.0182;
  }

  /// Convert mmol/L to mg/dL
  static double mmolToMgDl(double mmol) {
    return mmol * 18.0182;
  }

  // Clinical physiological boundaries
  static const int minSystolic = 40;
  static const int maxSystolic = 300;
  static const int minDiastolic = 30;
  static const int maxDiastolic = 200;
  static const int minPulsePressure = 10;
  static const int minPulse = 30;
  static const int maxPulse = 250;

  static const double minGlucoseMgDl = 20.0;
  static const double maxGlucoseMgDl = 600.0;
  static const double minGlucoseMmol = 1.1;
  static const double maxGlucoseMmol = 33.3;

  /// Validates blood pressure inputs.
  /// Returns a validation error code or null if valid.
  static BpValidationError? validateBp({
    required int? systolic,
    required int? diastolic,
    required int? pulse,
  }) {
    if (systolic == null || systolic < minSystolic || systolic > maxSystolic) {
      return BpValidationError.invalidSystolic;
    }
    if (diastolic == null || diastolic < minDiastolic || diastolic > maxDiastolic) {
      return BpValidationError.invalidDiastolic;
    }
    if (systolic - diastolic < minPulsePressure) {
      return BpValidationError.systolicMustExceedDiastolic;
    }
    if (pulse == null || pulse < minPulse || pulse > maxPulse) {
      return BpValidationError.invalidPulse;
    }
    return null;
  }

  /// Validates blood glucose inputs based on unit.
  /// Returns a validation error code or null if valid.
  static GlucoseValidationError? validateGlucose({
    required double? value,
    required String unit,
  }) {
    if (value == null) {
      return unit == 'mmol/L'
          ? GlucoseValidationError.invalidMmol
          : GlucoseValidationError.invalidMgDl;
    }
    if (unit == 'mmol/L') {
      if (value < minGlucoseMmol || value > maxGlucoseMmol) {
        return GlucoseValidationError.invalidMmol;
      }
    } else {
      if (value < minGlucoseMgDl || value > maxGlucoseMgDl) {
        return GlucoseValidationError.invalidMgDl;
      }
    }
    return null;
  }
}

enum BpValidationError {
  invalidSystolic,
  invalidDiastolic,
  systolicMustExceedDiastolic,
  invalidPulse,
}

extension BpValidationErrorLocalization on BpValidationError {
  String localizedMessage(AppLocalizations l10n) {
    switch (this) {
      case BpValidationError.invalidSystolic:
        return l10n.errorInvalidSystolic;
      case BpValidationError.invalidDiastolic:
        return l10n.errorInvalidDiastolic;
      case BpValidationError.systolicMustExceedDiastolic:
        return l10n.errorSystolicMustExceedDiastolic;
      case BpValidationError.invalidPulse:
        return l10n.errorInvalidPulse;
    }
  }
}

enum GlucoseValidationError {
  invalidMgDl,
  invalidMmol,
}

extension GlucoseValidationErrorLocalization on GlucoseValidationError {
  String localizedMessage(AppLocalizations l10n) {
    switch (this) {
      case GlucoseValidationError.invalidMgDl:
        return l10n.errorInvalidGlucoseMgDl;
      case GlucoseValidationError.invalidMmol:
        return l10n.errorInvalidGlucoseMmol;
    }
  }
}

