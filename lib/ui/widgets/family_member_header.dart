import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/health_providers.dart';
import '../../core/constants/app_colors.dart';
import 'member_form_dialog.dart';

class FamilyMemberHeader extends ConsumerWidget {
  const FamilyMemberHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == members.length) {
                // Add Member Button
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 20, color: AppColors.primary),
                  label: Text(l10n?.addNewMember ?? 'Add Member'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  backgroundColor: AppColors.primaryLight,
                  onPressed: () => MemberFormDialog.show(context),
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
                        ? member.color.withValues(alpha: 0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? member.color : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: member.color.withValues(alpha: 0.2),
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
                                  ? member.color.withValues(alpha: 0.8)
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
}
