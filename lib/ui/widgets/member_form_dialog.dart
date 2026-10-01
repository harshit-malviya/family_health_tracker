import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_member.dart';
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
      _selectedDob = DateTime(2000, 1, 1);
      _selectedColorValue = AppColors.memberPalette.first.toARGB32();
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
    final initialDate = _selectedDob ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(now.year - 125, 1, 1),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.initialMember != null;
    final ageStr = _selectedDob != null ? l10n.yearsOld(_calculateAge(_selectedDob!)) : '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEditing ? l10n.editProfile : l10n.addNewMember,
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
              decoration: InputDecoration(
                labelText: l10n.memberName,
                hintText: l10n.memberNameHint,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),

            // Relationship Field
            TextField(
              controller: _relationController,
              decoration: InputDecoration(
                labelText: l10n.relationship,
                hintText: 'e.g. Father, Mother, Self',
                prefixIcon: const Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Date of Birth Field
            Text(
              '${l10n.dateOfBirth}:',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
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
                                : l10n.dateOfBirth,
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
            Text(
              l10n.chooseColorAvatar,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
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
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: AppColors.memberPalette.map((color) {
                final isSel = color.toARGB32() == _selectedColorValue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorValue = color.toARGB32()),
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
          child: Text(l10n.cancel),
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
            }
          },
          child: Text(isEditing ? l10n.save : l10n.addNewMember),
        ),
      ],
    );
  }
}
