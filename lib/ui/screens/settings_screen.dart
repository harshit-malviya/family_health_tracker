import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/health_providers.dart';
import '../../providers/locale_provider.dart';
import '../../services/backup_restore_service.dart';
import '../widgets/member_form_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unit = ref.watch(glucoseUnitProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Language Selection Section
          _buildSectionHeader(l10n.languageSectionTitle),
          _buildCardSection(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                        child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.languageSectionTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.languageSubtitle,
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 'en',
                          label: Text(l10n.languageEnglish, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment(
                          value: 'hi',
                          label: Text(l10n.languageHindi, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (set) {
                        ref.read(localeProvider.notifier).setLocale(Locale(set.first));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Units Section
          _buildSectionHeader(l10n.clinicalPreferences),
          _buildCardSection(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.speed, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.glucoseUnitTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unit == 'mg/dL' ? l10n.glucoseUnitUsIndia : l10n.glucoseUnitIntl,
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'mg/dL',
                          label: Text('mg/dL', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment(
                          value: 'mmol/L',
                          label: Text('mmol/L', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
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
          ),
          const SizedBox(height: 24),

          // Backup & Restore Section
          _buildSectionHeader(l10n.dataBackupPortability),
          _buildCardSection(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                  title: Text(l10n.exportHealthRecords, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(l10n.exportHealthRecordsSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => BackupRestoreService.exportBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.green),
                  title: Text(l10n.restoreFromBackup, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(l10n.restoreFromBackupSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => BackupRestoreService.restoreBackupFromFile(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Family Members Management Section
          _buildSectionHeader(l10n.familyProfiles),
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
                            ? '${m.relation} • Born ${DateFormat('MMM d, yyyy').format(m.dateOfBirth!)} (${l10n.yearsOld(m.age)})'
                            : '${m.relation} • ${l10n.yearsOld(m.age)}';

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
                                tooltip: l10n.editProfile,
                                onPressed: () => MemberFormDialog.show(context, initialMember: m),
                              ),
                              if (members.length > 1) ...[
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                  tooltip: l10n.deleteProfile,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(l10n.deleteProfile),
                                        content: Text(l10n.deleteProfileConfirm(m.name)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text(l10n.cancel),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              minimumSize: const Size(80, 40),
                                            ),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text(l10n.delete),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      ref.read(familyMembersProvider.notifier).deleteMember(m.id);
                                    }
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
                      title: Text(
                        l10n.addNewMember,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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
          const SizedBox(height: 28),

          // App Version & Branding Footer
          Center(
            child: Column(
              children: [
                const Text(
                  'Family Health Tracker',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'v2.0.0 (Build 4)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
