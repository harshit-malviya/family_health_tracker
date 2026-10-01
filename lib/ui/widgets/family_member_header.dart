import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/family_member.dart';
import '../../providers/health_providers.dart';
import '../../core/constants/app_colors.dart';

class FamilyMemberHeader extends ConsumerWidget {
  const FamilyMemberHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);
    final selectedId = ref.watch(selectedMemberIdProvider);

    return membersAsync.when(
      loading: () => const SizedBox(height: 70),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        return SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: members.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == members.length) {
                // Add Member Button
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 20, color: AppColors.primary),
                  label: const Text('Add Member'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  backgroundColor: AppColors.primaryLight,
                  onPressed: () => _showAddMemberDialog(context, ref),
                );
              }

              final member = members[index];
              final isSelected = member.id == selectedId;

              return InkWell(
                onTap: () {
                  ref.read(selectedMemberIdProvider.notifier).select(member.id);
                },
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? member.color.withOpacity(0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? member.color : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: member.color.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member.avatarEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? member.color : AppColors.textDark,
                            ),
                          ),
                          Text(
                            member.relation,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? member.color.withOpacity(0.8)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final ageController = TextEditingController();
    int selectedColorIndex = 0;
    String selectedEmoji = '🧑';

    final emojis = ['👨', '👩', '👴', '👵', '🧑', '👧', '👦'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Add Family Member', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name (e.g. Grandma)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: relationController,
                    decoration: const InputDecoration(labelText: 'Relationship (e.g. Grandmother)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose Avatar:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: emojis.map((emoji) {
                      final isSel = emoji == selectedEmoji;
                      return ChoiceChip(
                        label: Text(emoji, style: const TextStyle(fontSize: 20)),
                        selected: isSel,
                        onSelected: (_) => setState(() => selectedEmoji = emoji),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Theme Color:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: List.generate(AppColors.memberPalette.length, (idx) {
                      final color = AppColors.memberPalette[idx];
                      final isSel = idx == selectedColorIndex;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColorIndex = idx),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: color,
                          child: isSel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final newMember = FamilyMember(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    relation: relationController.text.trim().isEmpty
                        ? 'Family'
                        : relationController.text.trim(),
                    age: int.tryParse(ageController.text.trim()) ?? 40,
                    colorValue: AppColors.memberPalette[selectedColorIndex].value,
                    avatarEmoji: selectedEmoji,
                  );
                  ref.read(familyMembersProvider.notifier).addMember(newMember);
                  ref.read(selectedMemberIdProvider.notifier).select(newMember.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Add Member'),
              ),
            ],
          );
        },
      ),
    );
  }
}
