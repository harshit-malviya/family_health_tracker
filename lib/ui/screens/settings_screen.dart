import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_providers.dart';
import '../../services/backup_restore_service.dart';
import '../widgets/member_form_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(glucoseUnitProvider);
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Backup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Units Section
          _buildSectionHeader('Clinical Preferences'),
          _buildCardSection(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.speed, color: AppColors.secondary),
                  title: const Text('Blood Glucose Unit', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(unit == 'mg/dL' ? 'US / India standard (mg/dL)' : 'International standard (mmol/L)'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'mg/dL', label: Text('mg/dL')),
                      ButtonSegment(value: 'mmol/L', label: Text('mmol/L')),
                    ],
                    selected: {unit},
                    onSelectionChanged: (set) {
                      ref.read(glucoseUnitProvider.notifier).setUnit(set.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup & Restore Section
          _buildSectionHeader('Data Backup & Portability'),
          _buildCardSection(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                  title: const Text('Export Health Records', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Save JSON backup file or share to Google Drive / WhatsApp'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => BackupRestoreService.exportBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.green),
                  title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Import backup by selecting a .json file'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => BackupRestoreService.restoreBackupFromFile(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Family Members Management Section
          _buildSectionHeader('Family Profiles'),
          _buildCardSection(
            child: membersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading profiles: $e'),
              ),
              data: (members) {
                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = members[index];
                        final dobSubtitle = m.dateOfBirth != null
                            ? '${m.relation} • Born ${DateFormat('MMM d, yyyy').format(m.dateOfBirth!)} (${m.age} yrs)'
                            : '${m.relation} • ${m.age} yrs';

                        return ListTile(
                          leading: Text(m.avatarEmoji, style: const TextStyle(fontSize: 26)),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(dobSubtitle),
                          onTap: () => MemberFormDialog.show(context, initialMember: m),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                tooltip: 'Edit Profile',
                                onPressed: () => MemberFormDialog.show(context, initialMember: m),
                              ),
                              if (members.length > 1) ...[
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                  tooltip: 'Delete Profile',
                                  onPressed: () {
                                    ref.read(familyMembersProvider.notifier).deleteMember(m.id);
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                      ),
                      title: const Text(
                        'Add Family Member',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                      onTap: () => MemberFormDialog.show(context),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Clinical Disclaimer Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified_user_outlined, size: 18, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'Medical Standard Alignment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Blood Pressure categories follow the American Heart Association (AHA / ACC 2017) Guidelines.\n'
                  '• Blood Glucose targets follow the American Diabetes Association (ADA 2024) Standards of Care.\n'
                  '• This app is an educational tracking companion and does not substitute professional medical advice.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardSection({required Widget child}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
