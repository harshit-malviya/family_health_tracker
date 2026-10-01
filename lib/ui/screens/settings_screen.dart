import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(glucoseUnitProvider);
    final repo = ref.watch(healthRepositoryProvider);
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
          Container(
            decoration: _boxDecoration(),
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
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                  title: const Text('Export Health Records', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Save encrypted JSON backup file or send to Google Drive/WhatsApp'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    try {
                      final jsonString = await repo.exportBackupJson();
                      await SharePlus.instance.share(ShareParams(text: jsonString));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export error: $e')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.green),
                  title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Import previously exported JSON backup file'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showImportDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Family Members Management Section
          _buildSectionHeader('Family Profiles'),
          Container(
            decoration: _boxDecoration(),
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
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return ListTile(
                      leading: Text(m.avatarEmoji, style: const TextStyle(fontSize: 26)),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m.relation} • ${m.age} yrs'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 6, backgroundColor: m.color),
                          if (members.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                              onPressed: () {
                                ref.read(familyMembersProvider.notifier).deleteMember(m.id);
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
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

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.withOpacity(0.15)),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Restore Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your exported JSON backup text below:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '{"version": 1, ...}'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isEmpty) return;
              final repo = ref.read(healthRepositoryProvider);
              final success = await repo.importBackupJson(raw);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (!context.mounted) return;
              if (success) {
                ref.read(familyMembersProvider.notifier).loadMembers();
                ref.read(bpReadingsProvider.notifier).loadReadings();
                ref.read(glucoseReadingsProvider.notifier).loadReadings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup restored successfully!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to restore backup: Invalid data format')),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
