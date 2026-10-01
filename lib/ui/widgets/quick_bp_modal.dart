import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/bp_reading.dart';
import '../../core/constants/clinical_standards.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/health_providers.dart';

class QuickBpModal extends ConsumerStatefulWidget {
  final BpReading? initialReading;

  const QuickBpModal({super.key, this.initialReading});

  @override
  ConsumerState<QuickBpModal> createState() => _QuickBpModalState();
}

class _QuickBpModalState extends ConsumerState<QuickBpModal> {
  late final TextEditingController _sysController;
  late final TextEditingController _diaController;
  late final TextEditingController _pulseController;
  late final TextEditingController _notesController;

  late String _selectedArm;
  late String _selectedPosture;
  late bool _hasArrhythmia;
  late DateTime _selectedDateTime;

  BpCategory _currentCategory = BpCategory.normal;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReading;
    _sysController = TextEditingController(text: initial?.systolic.toString() ?? '120');
    _diaController = TextEditingController(text: initial?.diastolic.toString() ?? '80');
    _pulseController = TextEditingController(text: initial?.pulse.toString() ?? '72');
    _notesController = TextEditingController(text: initial?.notes ?? '');

    _selectedArm = initial?.arm ?? 'Left';
    _selectedPosture = initial?.posture ?? 'Sitting';
    _hasArrhythmia = initial?.hasArrhythmia ?? false;
    _selectedDateTime = initial?.timestamp ?? DateTime.now();

    _sysController.addListener(_updateCategory);
    _diaController.addListener(_updateCategory);
    _updateCategory();
  }

  void _updateCategory() {
    final sys = int.tryParse(_sysController.text) ?? 120;
    final dia = int.tryParse(_diaController.text) ?? 80;
    setState(() {
      _currentCategory = ClinicalStandards.evaluateBp(sys, dia);
    });
  }

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _pulseController.dispose();
    _notesController.dispose();
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
    final theme = Theme.of(context);
    final isEditing = widget.initialReading != null;

    final formattedDateStr = DateFormat('EEE, MMM d, yyyy • h:mm a').format(_selectedDateTime);

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
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.favorite, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? l10n.editBpTitle : l10n.logBpTitle,
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
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
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
                            color: AppColors.primary,
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
                        selectedColor: AppColors.primaryLight,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedDateTime = DateTime.now());
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.yesterday),
                        selected: _isYesterday(_selectedDateTime),
                        selectedColor: AppColors.primaryLight,
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
                        avatar: const Icon(Icons.edit_calendar, size: 16, color: AppColors.primary),
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
                  Icon(Icons.health_and_safety, color: _currentCategory.color, size: 24),
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

            // Big Number Fields (Systolic, Diastolic, Pulse)
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    controller: _sysController,
                    label: 'SYS',
                    sublabel: l10n.systolicUpper,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberInput(
                    controller: _diaController,
                    label: 'DIA',
                    sublabel: l10n.diastolicLower,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberInput(
                    controller: _pulseController,
                    label: 'PULSE',
                    sublabel: l10n.pulseBpm,
                    color: Colors.purple.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Arm & Posture Selector
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'Left', label: Text(l10n.armLeft)),
                      ButtonSegment(value: 'Right', label: Text(l10n.armRight)),
                    ],
                    selected: {_selectedArm},
                    onSelectionChanged: (set) => setState(() => _selectedArm = set.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'Sitting', label: Text(l10n.postureSitting)),
                      ButtonSegment(value: 'Lying', label: Text(l10n.postureLying)),
                      ButtonSegment(value: 'Standing', label: Text(l10n.postureStanding)),
                    ],
                    selected: {_selectedPosture},
                    onSelectionChanged: (set) => setState(() => _selectedPosture = set.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Arrhythmia toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.irregularHeartbeat),
              subtitle: Text(l10n.notesHintBp),
              value: _hasArrhythmia,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _hasArrhythmia = val),
            ),
            const SizedBox(height: 8),

            // Notes input
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                hintText: l10n.notesHintBp,
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                if (member == null) return;
                final sys = int.tryParse(_sysController.text) ?? 120;
                final dia = int.tryParse(_diaController.text) ?? 80;
                final pulse = int.tryParse(_pulseController.text) ?? 72;

                if (isEditing) {
                  final updated = BpReading(
                    id: widget.initialReading!.id,
                    memberId: widget.initialReading!.memberId,
                    systolic: sys,
                    diastolic: dia,
                    pulse: pulse,
                    arm: _selectedArm,
                    posture: _selectedPosture,
                    hasArrhythmia: _hasArrhythmia,
                    notes: _notesController.text.trim(),
                    timestamp: _selectedDateTime,
                  );
                  ref.read(bpReadingsProvider.notifier).updateReading(updated);
                  Navigator.pop(context);
                } else {
                  final reading = BpReading(
                    id: const Uuid().v4(),
                    memberId: member.id,
                    systolic: sys,
                    diastolic: dia,
                    pulse: pulse,
                    arm: _selectedArm,
                    posture: _selectedPosture,
                    hasArrhythmia: _hasArrhythmia,
                    notes: _notesController.text.trim(),
                    timestamp: _selectedDateTime,
                  );
                  ref.read(bpReadingsProvider.notifier).addReading(reading);
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? l10n.updateBpReading : l10n.saveBpReading),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
