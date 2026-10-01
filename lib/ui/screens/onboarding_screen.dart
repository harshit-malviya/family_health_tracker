import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../models/family_member.dart';
import '../../providers/health_providers.dart';
import '../widgets/member_form_dialog.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController(text: 'Self');

  DateTime? _selectedDob;
  int _selectedColorValue = AppColors.memberPalette.first.value;
  String _selectedEmoji = '🧑';

  final List<String> _emojis = ['👨', '👩', '👴', '👵', '🧑', '👧', '👦', '👶', '🩺'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDob = DateTime(now.year - 30, 1, 1);
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
      firstDate: DateTime(now.year - 125, 1, 1),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveFirstProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for the first family profile.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final relation = _relationController.text.trim().isEmpty
        ? 'Self'
        : _relationController.text.trim();

    final newMember = FamilyMember(
      id: const Uuid().v4(),
      name: name,
      relation: relation,
      dateOfBirth: _selectedDob,
      colorValue: _selectedColorValue,
      avatarEmoji: _selectedEmoji,
    );

    await ref.read(familyMembersProvider.notifier).addMember(newMember);
    ref.read(selectedMemberIdProvider.notifier).select(newMember.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile for "${newMember.name}" created!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);
    final members = membersAsync.asData?.value ?? [];
    final hasMembers = members.isNotEmpty;
    final ageStr = _selectedDob != null ? '${_calculateAge(_selectedDob!)} years old' : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Hero Branding
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Header Logo & Branding
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.secondary.withValues(alpha: 0.25),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Family Health Tracker',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track Blood Pressure & Blood Sugar records for your whole family in one private, offline place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Main Content: First Profile Form or Profiles List
                    if (!hasMembers) ...[
                      // First Profile Creation Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_add_alt_1,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Create Your First Profile',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You must add at least one member profile to start recording measurements.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Name Field
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name / Nickname',
                                  hintText: 'e.g. John, Dad, Grandpa',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Relationship Field (Defaults to 'Self')
                              TextField(
                                controller: _relationController,
                                decoration: const InputDecoration(
                                  labelText: 'Relationship / Role',
                                  hintText: 'e.g. Self, Father, Mother',
                                  prefixIcon: Icon(Icons.people_outline),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Date of Birth Field
                              const Text(
                                'Date of Birth:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
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

                              // Color Accent Selector
                              const Text(
                                'Profile Accent Color:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
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
                                      child: isSel
                                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),

                              // Submit First Profile Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _saveFirstProfile,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Save Profile'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Successfully created member(s) section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.secondary, size: 24),
                                const SizedBox(width: 10),
                                const Text(
                                  'Ready to Start!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Here are your configured family profiles. You can add more now or anytime later from Settings.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),

                            // List of configured members
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final m = members[index];
                                final dobSubtitle = m.dateOfBirth != null
                                    ? '${m.relation} • Born ${DateFormat('MMM d, yyyy').format(m.dateOfBirth!)} (${m.age} yrs)'
                                    : '${m.relation} • ${m.age} yrs';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: m.color.withValues(alpha: 0.15),
                                    child: Text(m.avatarEmoji, style: const TextStyle(fontSize: 22)),
                                  ),
                                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(dobSubtitle),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                    tooltip: 'Edit Profile',
                                    onPressed: () => MemberFormDialog.show(context, initialMember: m),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Add Another Family Member button
                            OutlinedButton.icon(
                              onPressed: () => MemberFormDialog.show(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Another Family Member'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Navigation Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: hasMembers
                        ? () {
                            ref.read(selectedMemberIdProvider.notifier).select(members.first.id);
                            ref.read(onboardingCompletedProvider.notifier).complete();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue to Dashboard'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      backgroundColor: hasMembers ? AppColors.primary : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
