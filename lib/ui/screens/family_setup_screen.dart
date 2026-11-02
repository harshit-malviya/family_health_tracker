import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  bool _isCreating = true; // true = Create, false = Join
  final _formKey = GlobalKey<FormState>();

  final _familyNameController = TextEditingController(text: 'My Family');
  final _inviteCodeController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final existingName = user?.userMetadata?['display_name'] as String?;
    if (existingName != null && existingName.isNotEmpty) {
      _displayNameController.text = existingName;
    }
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(currentFamilyProvider.notifier);
      final displayName = _displayNameController.text.trim();

      if (_isCreating) {
        await notifier.createFamily(
          familyName: _familyNameController.text.trim(),
          displayName: displayName,
        );
      } else {
        await notifier.joinFamily(
          inviteCode: _inviteCodeController.text.trim().toUpperCase(),
          displayName: displayName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(currentFamilyProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
            label: const Text('Sign Out', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.group_add_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Set Up Your Family Group',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a new shared family or join an existing family using an invite code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),

                    // Choice Selector
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Create Family')),
                            selected: _isCreating,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              fontWeight: _isCreating ? FontWeight.bold : FontWeight.normal,
                              color: _isCreating ? AppColors.primary : const Color(0xFF64748B),
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _isCreating = true);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Join with Code')),
                            selected: !_isCreating,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              fontWeight: !_isCreating ? FontWeight.bold : FontWeight.normal,
                              color: !_isCreating ? AppColors.primary : const Color(0xFF64748B),
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _isCreating = false);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Display Name (Your Name)
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name (e.g. Rahul, Mom, Dad)',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_isCreating) ...[
                      TextFormField(
                        controller: _familyNameController,
                        decoration: InputDecoration(
                          labelText: 'Family Name (e.g. The Sharma Family)',
                          prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter family name';
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Invite Code (e.g. SHA-8421)',
                          hintText: 'Ask your family member for the code',
                          prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter the family invite code';
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              _isCreating ? 'Create & Continue' : 'Join Family Group',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

