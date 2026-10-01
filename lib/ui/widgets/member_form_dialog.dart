import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/family_member.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_providers.dart';

class MemberFormDialog extends ConsumerStatefulWidget {
  final FamilyMember? initialMember;

  const MemberFormDialog({super.key, this.initialMember});

  static Future<void> show(BuildContext context, {FamilyMember? initialMember}) {
    return showDialog(
      context: context,
      builder: (ctx) => MemberFormDialog(initialMember: initialMember),
    );
  }

  @override
  ConsumerState<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends ConsumerState<MemberFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationController;

  DateTime? _selectedDob;
  late int _selectedColorValue;
  late String _selectedEmoji;

  final List<String> _emojis = ['👨', '👩', '👴', '👵', '🧑', '👧', '👦', '👶', '🩺'];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMember;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _relationController = TextEditingController(text: initial?.relation ?? '');

    if (initial != null) {
      if (initial.dateOfBirth != null) {
        _selectedDob = initial.dateOfBirth;
      } else {
        // Fallback estimate from age
        final now = DateTime.now();
        _selectedDob = DateTime(now.year - initial.age, 1, 1);
      }
      _selectedColorValue = initial.colorValue;
      _selectedEmoji = initial.avatarEmoji;
    } else {
      final now = DateTime.now();
      _selectedDob = DateTime(now.year - 30, 6, 15);
      _selectedColorValue = AppColors.memberPalette.first.value;
      _selectedEmoji = '🧑';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 30, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(now.year - 125, 1, 1), // Up to 125 years back
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMember != null;
    final ageStr = _selectedDob != null ? '${_calculateAge(_selectedDob!)} years old' : '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEditing ? 'Edit Family Member' : 'Add Family Member',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Dad, Mom, Grandpa',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),

            // Relationship Field
            TextField(
              controller: _relationController,
              decoration: const InputDecoration(
                labelText: 'Relationship / Role',
                hintText: 'e.g. Father, Mother, Self',
                prefixIcon: Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Date of Birth Field
            const Text(
              'Date of Birth:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateOfBirth,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDob != null
                                ? DateFormat('MMMM d, yyyy').format(_selectedDob!)
                                : 'Select Date of Birth',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (ageStr.isNotEmpty)
                            Text(
                              ageStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.calendar_month, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Avatar Emoji Selector
            const Text(
              'Choose Avatar:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((emoji) {
                final isSel = emoji == _selectedEmoji;
                return ChoiceChip(
                  label: Text(emoji, style: const TextStyle(fontSize: 20)),
                  selected: isSel,
                  selectedColor: AppColors.primaryLight,
                  onSelected: (_) => setState(() => _selectedEmoji = emoji),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Color Palette Selector
            const Text(
              'Profile Accent Color:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: AppColors.memberPalette.map((color) {
                final isSel = color.value == _selectedColorValue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorValue = color.value),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: color,
                    child: isSel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final relation = _relationController.text.trim().isEmpty
                ? 'Family'
                : _relationController.text.trim();

            if (isEditing) {
              final updated = widget.initialMember!.copyWith(
                name: name,
                relation: relation,
                dateOfBirth: _selectedDob,
                colorValue: _selectedColorValue,
                avatarEmoji: _selectedEmoji,
              );
              ref.read(familyMembersProvider.notifier).updateMember(updated);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${updated.name}\'s profile updated!'),
                  backgroundColor: AppColors.secondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              final newMember = FamilyMember(
                id: const Uuid().v4(),
                name: name,
                relation: relation,
                dateOfBirth: _selectedDob,
                colorValue: _selectedColorValue,
                avatarEmoji: _selectedEmoji,
              );
              ref.read(familyMembersProvider.notifier).addMember(newMember);
              ref.read(selectedMemberIdProvider.notifier).select(newMember.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${newMember.name} added to family profiles!'),
                  backgroundColor: AppColors.secondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Text(isEditing ? 'Save Changes' : 'Add Member'),
        ),
      ],
    );
  }
}
