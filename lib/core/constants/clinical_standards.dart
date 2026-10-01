import 'package:flutter/material.dart';
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
}
