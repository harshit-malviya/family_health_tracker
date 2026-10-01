import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/glucose_reading.dart';
import '../../core/constants/clinical_standards.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_providers.dart';

class QuickGlucoseModal extends ConsumerStatefulWidget {
  const QuickGlucoseModal({super.key});

  @override
  ConsumerState<QuickGlucoseModal> createState() => _QuickGlucoseModalState();
}

class _QuickGlucoseModalState extends ConsumerState<QuickGlucoseModal> {
  final _valueController = TextEditingController(text: '95');
  final _medsController = TextEditingController();

  MealContext _selectedMealContext = MealContext.fasting;
  GlucoseCategory _currentCategory = GlucoseCategory.normal;

  @override
  void initState() {
    super.initState();
    _valueController.addListener(_updateCategory);
  }

  void _updateCategory() {
    final unit = ref.read(glucoseUnitProvider);
    final val = double.tryParse(_valueController.text) ?? 95.0;
    final mgDl = unit == 'mmol/L' ? ClinicalStandards.mmolToMgDl(val) : val;

    setState(() {
      _currentCategory = ClinicalStandards.evaluateGlucose(mgDl, _selectedMealContext);
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _medsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(activeMemberProvider);
    final unit = ref.watch(glucoseUnitProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.water_drop, color: AppColors.secondary, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Blood Sugar',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    Text(
                      member != null ? 'For ${member.name} (${member.relation})' : 'Record reading',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Category Status Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _currentCategory.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _currentCategory.color.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.monitor_heart, color: _currentCategory.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentCategory.label,
                          style: TextStyle(
                            color: _currentCategory.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _currentCategory.rangeHint,
                          style: TextStyle(
                            color: _currentCategory.color.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Glucose input + Unit selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Unit chip toggle
                  ActionChip(
                    label: Text(
                      unit,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    backgroundColor: AppColors.secondaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    onPressed: () {
                      final newUnit = unit == 'mg/dL' ? 'mmol/L' : 'mg/dL';
                      ref.read(glucoseUnitProvider.notifier).setUnit(newUnit);

                      final currentVal = double.tryParse(_valueController.text) ?? 95.0;
                      if (newUnit == 'mmol/L') {
                        _valueController.text =
                            ClinicalStandards.mgDlToMmol(currentVal).toStringAsFixed(1);
                      } else {
                        _valueController.text =
                            ClinicalStandards.mmolToMgDl(currentVal).toStringAsFixed(0);
                      }
                      _updateCategory();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Meal Context Chips
            const Text(
              'When was this measured?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealContext.values.map((ctx) {
                final isSelected = ctx == _selectedMealContext;
                return ChoiceChip(
                  label: Text(ctx.label),
                  selected: isSelected,
                  selectedColor: AppColors.secondaryLight,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.secondary : AppColors.textDark,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedMealContext = ctx);
                      _updateCategory();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Medication & Food notes
            TextField(
              controller: _medsController,
              decoration: const InputDecoration(
                labelText: 'Medication / Meal notes (optional, e.g. Metformin 500mg)',
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () {
                if (member == null) return;
                final inputVal = double.tryParse(_valueController.text) ?? 95.0;
                final mgDl = unit == 'mmol/L'
                    ? ClinicalStandards.mmolToMgDl(inputVal)
                    : inputVal;

                final reading = GlucoseReading(
                  id: const Uuid().v4(),
                  memberId: member.id,
                  valueMgDl: mgDl,
                  mealContext: _selectedMealContext,
                  medicationNotes: _medsController.text.trim(),
                  timestamp: DateTime.now(),
                );

                ref.read(glucoseReadingsProvider.notifier).addReading(reading);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Blood glucose recorded for ${member.name}!'),
                    backgroundColor: AppColors.secondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Blood Sugar Reading'),
            ),
          ],
        ),
      ),
    );
  }
}
