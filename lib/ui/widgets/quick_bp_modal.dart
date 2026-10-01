import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/bp_reading.dart';
import '../../core/constants/clinical_standards.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_providers.dart';

class QuickBpModal extends ConsumerStatefulWidget {
  const QuickBpModal({super.key});

  @override
  ConsumerState<QuickBpModal> createState() => _QuickBpModalState();
}

class _QuickBpModalState extends ConsumerState<QuickBpModal> {
  final _sysController = TextEditingController(text: '120');
  final _diaController = TextEditingController(text: '80');
  final _pulseController = TextEditingController(text: '72');
  final _notesController = TextEditingController();

  String _selectedArm = 'Left';
  String _selectedPosture = 'Sitting';
  bool _hasArrhythmia = false;

  BpCategory _currentCategory = BpCategory.normal;

  @override
  void initState() {
    super.initState();
    _sysController.addListener(_updateCategory);
    _diaController.addListener(_updateCategory);
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

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(activeMemberProvider);
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
                      'Log Blood Pressure',
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
                  Icon(Icons.health_and_safety, color: _currentCategory.color, size: 24),
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

            // Big Number Fields (Systolic, Diastolic, Pulse)
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    controller: _sysController,
                    label: 'SYS',
                    sublabel: 'mmHg (Top)',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberInput(
                    controller: _diaController,
                    label: 'DIA',
                    sublabel: 'mmHg (Bottom)',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberInput(
                    controller: _pulseController,
                    label: 'PULSE',
                    sublabel: 'BPM',
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
                    segments: const [
                      ButtonSegment(value: 'Left', label: Text('Left Arm')),
                      ButtonSegment(value: 'Right', label: Text('Right Arm')),
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
                    segments: const [
                      ButtonSegment(value: 'Sitting', label: Text('Sitting')),
                      ButtonSegment(value: 'Lying', label: Text('Lying')),
                      ButtonSegment(value: 'Standing', label: Text('Standing')),
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
              title: const Text('Irregular heartbeat icon shown on machine?'),
              subtitle: const Text('Check if your monitor displayed an arrhythmia warning symbol'),
              value: _hasArrhythmia,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _hasArrhythmia = val),
            ),
            const SizedBox(height: 8),

            // Notes input
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional, e.g. after morning walk, rested 5 mins)',
                prefixIcon: Icon(Icons.edit_note),
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
                  timestamp: DateTime.now(),
                );

                ref.read(bpReadingsProvider.notifier).addReading(reading);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Blood pressure recorded for ${member.name}!'),
                    backgroundColor: AppColors.secondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Blood Pressure Reading'),
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
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
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
            style: TextStyle(
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
