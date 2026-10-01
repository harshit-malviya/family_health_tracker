import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/clinical_standards.dart';
import '../../l10n/app_localizations.dart';
import '../../models/glucose_reading.dart';
import '../../providers/health_providers.dart';

class QuickGlucoseModal extends ConsumerStatefulWidget {
  final GlucoseReading? initialReading;

  const QuickGlucoseModal({super.key, this.initialReading});

  @override
  ConsumerState<QuickGlucoseModal> createState() => _QuickGlucoseModalState();
}

class _QuickGlucoseModalState extends ConsumerState<QuickGlucoseModal> {
  late final TextEditingController _valueController;
  late final TextEditingController _medsController;

  late MealContext _selectedMealContext;
  late DateTime _selectedDateTime;
  GlucoseCategory _currentCategory = GlucoseCategory.normal;
  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false;
  String? _validationErrorMessage;
  bool _valueHasError = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReading;
    final unit = ref.read(glucoseUnitProvider);

    if (initial != null) {
      final formattedVal = unit == 'mmol/L'
          ? initial.valueMmol.toStringAsFixed(1)
          : initial.valueMgDl.toStringAsFixed(0);
      _valueController = TextEditingController(text: formattedVal);
      _medsController = TextEditingController(text: initial.medicationNotes);
      _selectedMealContext = initial.mealContext;
      _selectedDateTime = initial.timestamp;
    } else {
      _valueController = TextEditingController(text: unit == 'mmol/L' ? '5.3' : '95');
      _medsController = TextEditingController();
      _selectedMealContext = MealContext.fasting;
      _selectedDateTime = DateTime.now();
    }

    _valueController.addListener(_onInputsChanged);
    _onInputsChanged();
  }

  void _onInputsChanged() {
    final unit = ref.read(glucoseUnitProvider);
    final val = double.tryParse(_valueController.text.trim()) ?? 95.0;
    final mgDl = unit == 'mmol/L' ? ClinicalStandards.mmolToMgDl(val) : val;

    setState(() {
      _currentCategory = ClinicalStandards.evaluateGlucose(mgDl, _selectedMealContext);
      if (_hasAttemptedSubmit) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          final v = double.tryParse(_valueController.text.trim());
          final err = ClinicalStandards.validateGlucose(value: v, unit: unit);
          if (err != null) {
            _validationErrorMessage = err.localizedMessage(l10n);
            _valueHasError = true;
          } else {
            _validationErrorMessage = null;
            _valueHasError = false;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _medsController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isYesterday(DateTime dt) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  }

  Future<void> _pickCustomDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(now) ? now : _selectedDateTime,
      firstDate: now.subtract(const Duration(days: 365 * 5)), // Up to 5 years ago
      lastDate: now,
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final member = ref.watch(activeMemberProvider);
    final unit = ref.watch(glucoseUnitProvider);
    final theme = Theme.of(context);
    final isEditing = widget.initialReading != null;

    final formattedDateStr = DateFormat('EEE, MMM d, yyyy • h:mm a').format(_selectedDateTime);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
                      isEditing ? l10n.editGlucoseTitle : l10n.logGlucoseTitle,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    Text(
                      member != null
                          ? l10n.forMember(member.name, member.relation)
                          : l10n.recordReading,
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
            const SizedBox(height: 18),

            // Date & Time Selection Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dateTimeOfReading,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _pickCustomDateTime,
                        child: Text(
                          formattedDateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.today),
                        selected: _isToday(_selectedDateTime),
                        selectedColor: AppColors.secondaryLight,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedDateTime = DateTime.now());
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.yesterday),
                        selected: _isYesterday(_selectedDateTime),
                        selectedColor: AppColors.secondaryLight,
                        onSelected: (val) {
                          if (val) {
                            final now = DateTime.now();
                            setState(() {
                              _selectedDateTime = DateTime(
                                now.year,
                                now.month,
                                now.day - 1,
                                _selectedDateTime.hour,
                                _selectedDateTime.minute,
                              );
                            });
                          }
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.edit_calendar, size: 16, color: AppColors.secondary),
                        label: Text(l10n.dateTimeOfReading),
                        onPressed: _pickCustomDateTime,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Category Status Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _currentCategory.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _currentCategory.color.withValues(alpha: 0.4)),
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
                          _currentCategory.localizedLabel(l10n),
                          style: TextStyle(
                            color: _currentCategory.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _currentCategory.localizedRangeHint(l10n),
                          style: TextStyle(
                            color: _currentCategory.color.withValues(alpha: 0.85),
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
                color: _valueHasError ? Colors.red.shade50.withValues(alpha: 0.5) : AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _valueHasError ? Colors.red.shade400 : Colors.grey.withValues(alpha: 0.2),
                  width: _valueHasError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: _valueHasError ? Colors.red.shade700 : AppColors.textDark,
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
                      side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
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
                      _onInputsChanged();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Meal Context Chips
            Text(
              l10n.timingMealContext,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealContext.values.map((ctx) {
                final isSelected = ctx == _selectedMealContext;
                return ChoiceChip(
                  label: Text(ctx.localizedLabel(l10n)),
                  selected: isSelected,
                  selectedColor: AppColors.secondaryLight,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.secondary : AppColors.textDark,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedMealContext = ctx);
                      _onInputsChanged();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Medication & Food notes
            TextField(
              controller: _medsController,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                hintText: l10n.notesHintGlucose,
                prefixIcon: const Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 20),

            // Inline error message banner
            if (_validationErrorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationErrorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: _isSubmitting ? null : _handleSave,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEditing ? l10n.updateGlucoseReading : l10n.saveGlucoseReading),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return;

    final member = ref.read(activeMemberProvider);
    if (member == null) return;

    final l10n = AppLocalizations.of(context)!;
    final unit = ref.read(glucoseUnitProvider);
    final inputVal = double.tryParse(_valueController.text.trim());

    final err = ClinicalStandards.validateGlucose(
      value: inputVal,
      unit: unit,
    );

    _hasAttemptedSubmit = true;

    if (err != null) {
      setState(() {
        _validationErrorMessage = err.localizedMessage(l10n);
        _valueHasError = true;
      });
      return;
    }

    setState(() {
      _validationErrorMessage = null;
      _valueHasError = false;
      _isSubmitting = true;
    });

    final mgDl = unit == 'mmol/L'
        ? ClinicalStandards.mmolToMgDl(inputVal!)
        : inputVal!;

    final isEditing = widget.initialReading != null;

    try {
      if (isEditing) {
        final updated = GlucoseReading(
          id: widget.initialReading!.id,
          memberId: widget.initialReading!.memberId,
          valueMgDl: mgDl,
          mealContext: _selectedMealContext,
          medicationNotes: _medsController.text.trim(),
          timestamp: _selectedDateTime,
        );
        await ref.read(glucoseReadingsProvider.notifier).updateReading(updated);
      } else {
        final reading = GlucoseReading(
          id: const Uuid().v4(),
          memberId: member.id,
          valueMgDl: mgDl,
          mealContext: _selectedMealContext,
          medicationNotes: _medsController.text.trim(),
          timestamp: _selectedDateTime,
        );

        await ref.read(glucoseReadingsProvider.notifier).addReading(reading);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _validationErrorMessage = l10n.errorSaveFailed;
      });
    }
  }
}
